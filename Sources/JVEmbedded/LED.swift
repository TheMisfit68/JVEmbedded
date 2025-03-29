//
//  RGB_LED.swift
//  JVEmbedded
//
//  Created by Jan Verrept on 02/03/2025.
//

public class LED{
	var on:Bool = false
}

extension LED{
	
	public class RGB{
		
		public var pixelNumber:Int = 1
		public var enabled: Bool = false {
			didSet {
				if !enabled {
					self.color = JVEmbedded.Color.HSB.off
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
		
		func syncHardware() {
			// Override this method in subclasses
			fatalError("[LED.RGB.SyncHardware] must be overridden in subclasses")
		}
		
	}
	
	// MARK: - Analog with 3 discrete channels
	public final class Analog: LED.RGB {
		
		private var redOutput: PWMOutput
		private var greenOutput: PWMOutput
		private var blueOutput: PWMOutput
		private var fadingEnabled: Bool
		
		init(redPWM: PWMConfiguration, greenPWM: PWMConfiguration, bluePWM: PWMConfiguration, enableFading: Bool = false) {
			
			self.redOutput = PWMOutput(redPWM.pin, channelNumber: redPWM.channel)
			self.greenOutput = PWMOutput(greenPWM.pin, channelNumber: greenPWM.channel)
			self.blueOutput = PWMOutput(bluePWM.pin, channelNumber: bluePWM.channel)
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
				
				if (redPercentage == 0) && (greenPercentage == 0) && (bluePercentage == 0) {
					redPercentage = 5
					greenPercentage = 5
					bluePercentage = 5
				}
			}
			
			if self.fadingEnabled {
				redOutput.fadeToPercentage(redPercentage, durationMs: 1000)
				greenOutput.fadeToPercentage(greenPercentage, durationMs: 1000)
				blueOutput.fadeToPercentage(bluePercentage, durationMs:1000)
			}else{
				redOutput.setPercentage(to:redPercentage)
				greenOutput.setPercentage(to:greenPercentage)
				blueOutput.setPercentage(to:bluePercentage)
			}
			
		}
	}
	
	// MARK: - Addressable like WS2812B
	public final class Addressable: LED.RGB {
		
		private var handle: led_driver_handle_t
		
		init(pinNumber: Int? = nil, channelNumber: Int? = nil){
			var config = led_driver_get_config()
			if let pinNumber = pinNumber {
				config.gpio = Int32(pinNumber)
			}
			if let channelNumber = channelNumber {
				config.channel = Int32(channelNumber)
			}
			guard let handle = led_driver_init(&config) else {
				fatalError("[⚠️ LED.Addressable.init] Failed to initialize LED driver handle")
			}
			self.handle = handle
			
			super.init()
			self.syncHardware()
		}
		
		override func syncHardware() {
#if DEBUG
			print("💡Adjusting addressable LED to color:\n\(self.color.description)")
#endif
			led_driver_set_power(handle, self.enabled)
			led_driver_set_hue(handle, UInt16(self.color.hue))
			led_driver_set_saturation(handle, UInt8(self.color.saturation))
			led_driver_set_brightness(handle, UInt8(self.color.brightness))
		}
	}
	
	// MARK: - Addressable strip
	public final class Strip {
		
		public typealias matrix = LED.Strip
		
		//		/// Convenience accessor for function pointers
		//		private var cFunctionPointers: led_strip_t { handle.pointee }
		//		typealias ledStripHandle = UnsafeMutablePointer<led_strip_t>
		//		private var handle: ledStripHandle
		//
		//		public var enabled: Bool = false{
		//			didSet{
		//				syncHardware()
		//			}
		//		}
		//
		//		public var colors: [JVEmbedded.Color.HSB] = [] {
		//			didSet {
		//				syncHardware()
		//			}
		//		}
		//
		//		init(pinNumber: Int, pixelCount: Int = 2) {
		//			var stripConfig = led_strip_config_t(max_leds: UInt32(pixelCount), dev: 0)
		//
		//			// Create the LED strip instance
		//			guard let stripHandle = led_strip_new_rmt_ws2812(&stripConfig) else {
		//				fatalError("⚠️ [LED.Strip.init] Failed to initialize LED strip")
		//			}
		//
		//			self.handle = stripHandle
		//			self.colors = Array(repeating: JVEmbedded.Color.HSB.off, count: pixelCount)
		//		}
		//
		//		deinit {
		//			if let delFunction = cFunctionPointers.del {
		//				let result = delFunction(handle)
		//				if result != ESP_OK {
		//					print("⚠️ [LED.Strip.deinit] Failed to delete LED strip resources")
		//				}
		//			}
		//		}
		//
		//		/// Sets the color of a specific pixel in the LED strip
		//		public func setColorForPixel(atIndex index: Int, color: JVEmbedded.Color.HSB) {
		//			guard index >= 0, index < colors.count else {
		//				print("⚠️ [LED.Strip.setColorForPixel] Pixel index \(index) out of bounds")
		//				return
		//			}
		//
		//			colors[index] = color
		//
		//			if let setPixelFunction = cFunctionPointers.set_pixel {
		//				let result = setPixelFunction(handle, UInt32(index), UInt32(color.hue), UInt32(color.saturation), UInt32(color.brightness))
		//				if result != ESP_OK {
		//					print("⚠️ [LED.Strip.setColorForPixel] Failed to set pixel color at index \(index), error: \(result)")
		//				}
		//			}
		//		}
		//
		//		func syncHardware() {
		//			if self.enabled && !colors.isEmpty {
		//				for (index, color) in colors.enumerated() {
		//					setColorForPixel(atIndex: index, color: color)
		//				}
		//			} else {
		//				if let clearFunction = cFunctionPointers.clear {
		//					clearFunction(handle, UInt32(1000))
		//				}
		//			}
		//		}
	}
}


// MARK: - Analog RBG DEMO/testing methods
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

