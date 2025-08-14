//
//  LED.swift
//  JVEmbedded
//
//  Created by Jan Verrept on 15/07/2025.
//

// MARK: - Simple LED
open class LED{
	
	public var on:Bool = false{
		didSet {
			output.logicalValue = on
		}
	}
	public var blink: Bool = false{
		didSet {
			if blink && !blinkTimer.isRunning {
				self.blinkTimer.start()
			} else if !blink {
				self.blinkTimer.stop()
			}
		}
	}
	public var blinkSpeed: TimeInterval = 1.0
	private var blinkTimer: Oscillator!
	
	public var output:DigitalOutput
	
	
	init(pinNumber: GPIO.PinNumber){
		self.output = DigitalOutput(pinNumber, logic:.straight)
		self.blinkTimer = Oscillator(name: "LED.blinkTimer", delay: blinkSpeed) { [self] blinkTimer in
			on = !on
		}
	}
	
}

// MARK: - Abstract base class for RGB LED
extension LED{
	
	open class RGB{
		
		public var enabled: Bool = false {
			didSet {
				if enabled {
					self.rgbOutput = JVEmbedded.Color.RGB(using: color)
				}else {
					self.rgbOutput = JVEmbedded.Color.RGB.off
				}
			}
		}
		
		public var color: JVEmbedded.Color.HSB = JVEmbedded.Color.HSB.off {
			didSet {
				self.rgbOutput = JVEmbedded.Color.RGB(using: color)
			}
		}
		
		var rgbOutput: JVEmbedded.Color.RGB = JVEmbedded.Color.RGB.off{
			didSet {
				// Only update the hardware if the color has changed to prevent flickering
				if rgbOutput != oldValue {
					self.syncHardware()
				}
			}
		}
		public var blink: Bool = false{
			didSet {
				if blink && !blinkTimer.isRunning {
					self.blinkTimer.start()
				} else if !blink {
					self.blinkTimer.stop()
				}
			}
		}
		public var blinkSpeed: TimeInterval = 1.0
		private var blinkTimer: Oscillator!
		
		init(){
			self.blinkTimer = Oscillator(name: "LED.RGB.blinkTimer", delay: blinkSpeed) { [self] blinkTimer in
				enabled = !enabled
			}
		}
		
		func syncHardware() {
			// Override this method in subclasses
			fatalError("[LED.RGB.SyncHardware] must be overridden in subclasses")
		}
		
	}
	
	// MARK: - Analog RGB LED
	// with 3 discrete channels
	open class Analog: LED.RGB {
		
		
		private var redOutput: PWMOutput
		private var greenOutput: PWMOutput
		private var blueOutput: PWMOutput
		private var fadingEnabled: Bool
		
		init(redPinAndChannel: (GPIO.PinNumber,GPIO.ChannelNumber), greenPinAndChannel: (GPIO.PinNumber,GPIO.ChannelNumber), bluePinAndChannel: (GPIO.PinNumber,GPIO.ChannelNumber), timerNumber:GPIO.TimerNumber, enableFading: Bool = false) {
			
			self.redOutput = PWMOutput(redPinAndChannel.0, channelNumber: redPinAndChannel.1, timerNumber: timerNumber)
			self.greenOutput = PWMOutput(greenPinAndChannel.0, channelNumber: greenPinAndChannel.1, timerNumber: timerNumber)
			self.blueOutput = PWMOutput(bluePinAndChannel.0, channelNumber: bluePinAndChannel.1, timerNumber: timerNumber)
			self.fadingEnabled = enableFading
			super.init()
			
			if self.fadingEnabled {
				PWMOutput.installFadingService()
			}
			self.syncHardware()
		}
		
		override func syncHardware() {
			
			var redPercentage: Int = 0
			var greenPercentage: Int = 0
			var bluePercentage: Int = 0
			
			if enabled {
#if DEBUG
				print("💡Adjusting analog RGB-LED to color:\n\(self.rgbOutput.description)")
#endif
				redPercentage = Int(round(Double(self.rgbOutput.red) / 255.0 * 100.0))
				greenPercentage = Int(round(Double(self.rgbOutput.green) / 255.0 * 100.0))
				bluePercentage = Int(round(Double(self.rgbOutput.blue) / 255.0 * 100.0))
				
			}
			
			if self.fadingEnabled {
				redOutput.fadeToPercentage(redPercentage, durationMs: 1000)
				greenOutput.fadeToPercentage(greenPercentage, durationMs: 1000)
				blueOutput.fadeToPercentage(bluePercentage, durationMs: 1000)
			}else{
				redOutput.setPercentage(to:redPercentage)
				greenOutput.setPercentage(to:greenPercentage)
				blueOutput.setPercentage(to:bluePercentage)
			}
			
		}
	}
	
}


// MARK: - Effects for RGB LED
extension LED.RGB{
	
	// Method to select the next color
	public func cycleToNextChannel() {
		
		guard enabled else { self.color = JVEmbedded.Color.HSB.off; return}
		
		self.color = {
			switch self.color {
				case JVEmbedded.Color.HSB.off:
					return JVEmbedded.Color.HSB.red
				case JVEmbedded.Color.HSB.red:
					return JVEmbedded.Color.HSB.green
				case JVEmbedded.Color.HSB.green:
					return JVEmbedded.Color.HSB.blue
				case JVEmbedded.Color.HSB.blue:
					return JVEmbedded.Color.HSB.off
				default: return JVEmbedded.Color.HSB.off
			}
		}()
	}
	
	
	public func randomColor(){
		
		guard enabled else { self.color = JVEmbedded.Color.HSB.off; return}
		
		// During debugging, we want to keep the brightness low
#if DEBUG
		let brightNessRange:ClosedRange<Float> = 2.0...20.0
#else
		let brightNessRange:ClosedRange<Float> = 5.0...100.0
#endif
		self.color = JVEmbedded.Color.HSB.random(in: (hue:-100.0...100.0, saturation: 0.0...100.0, brightness: brightNessRange) )
		
	}
	
	// Color transition (flame flicker effect)
	public func flicker() {
		
		guard enabled else { self.color = JVEmbedded.Color.HSB.off; return}
		
		let orange = JVEmbedded.Color.HSB.orange // Corresponds to (hue:20.0, saturation: 100.0, brightness: 100.0)
		self.color = orange
		
		// Wait anywhere between 0 and 1 second
		let randomDelay = Int.random(in: 0...1000)
		JVEmbedded.Time.sleep(ms:randomDelay)
		
		// Create a small shift in the color
		self.color = self.color.offset(by: (hue:-3.0...3.0, saturation: -3.0...0.0, brightness: -20.0...0.0))
		
	}
	
}
