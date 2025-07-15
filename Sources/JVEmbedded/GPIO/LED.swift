//
//  LED.swift
//  JVEmbedded
//
//  Created by Jan Verrept on 15/07/2025.
//

public class LED{
	
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
	
	
	init(pinNumber: Int){
		self.output = DigitalOutput(pinNumber, logic:.straight)
		self.blinkTimer = Oscillator(name: "LED.blinkTimer", delay: blinkSpeed) { [self] blinkTimer in
			on = !on
		}
	}
	
}

extension LED{
	
	public class RGB{
		
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
	public final class Strip: LED.RGB {
		
		public typealias Matrix = LED.Strip
		
		private(set) var handle: UnsafeMutablePointer<led_strip_t>?
		public let pixelCount: Int
		
		public var colors: [JVEmbedded.Color.HSB] {
			didSet {
				if enabled {
					self.rgbOutputs = colors.map { JVEmbedded.Color.RGB(using: $0) }
				}
			}
		}
		
		var rgbOutputs: [JVEmbedded.Color.RGB] {
			didSet {
				if rgbOutputs != oldValue {
					try? self.syncHardware()
				}
			}
		}
		
		public override var enabled: Bool {
			didSet {
				if !enabled {
					try? clear()
				} else {
					self.rgbOutputs = self.colors.map { JVEmbedded.Color.RGB(using: $0) }
				}
			}
		}
		
		// MARK: - Init
		
		public init(pinNumber: Int32, channelNumber: UInt32 = 0, pixelCount: Int = 2) throws(ESPError) {
			
			self.pixelCount = pixelCount
			
			self.colors = Array(repeating: JVEmbedded.Color.HSB.off, count: pixelCount)
			super.init()
			
			var rmtConfig = rmt_config_t()
			rmtConfig.rmt_mode = RMT_MODE_TX
			rmtConfig.channel = rmt_channel_t(channelNumber)
			rmtConfig.gpio_num = gpio_num_t(pinNumber)
			rmtConfig.clk_div = 2
			rmtConfig.mem_block_num = 1
			rmtConfig.flags = 0
			
			rmtConfig.tx_config.carrier_freq_hz = 38000
			rmtConfig.tx_config.carrier_level = RMT_CARRIER_LEVEL_HIGH
			rmtConfig.tx_config.idle_level = RMT_IDLE_LEVEL_LOW
			rmtConfig.tx_config.carrier_duty_percent = 33
			rmtConfig.tx_config.carrier_en = false
			rmtConfig.tx_config.loop_en = false
			rmtConfig.tx_config.idle_output_en = true
			
			try ESPError.check(rmt_config(&rmtConfig))
			try ESPError.check(rmt_driver_install(rmtConfig.channel, 0, 0))
			
			var stripConfig = led_strip_config_t()
			stripConfig.max_leds = UInt32(pixelCount)
			stripConfig.dev = UnsafeMutableRawPointer(bitPattern: UInt(rmtConfig.channel.rawValue))
			
			guard let handle = led_strip_new_rmt_ws2812(&stripConfig) else {
				throw ESPError.fail
			}
			self.handle = handle
		}
		
		deinit {
			if let handle = handle {
				_ = handle.pointee.del(handle)
			}
		}
		
		// MARK: - Hardware interaction
		
		public override func syncHardware() {
#if DEBUG
			print("💡Syncing LED strip with \(rgbOutputs.count) RGB pixels")
#endif
			try? setPixels(rgbColors: rgbOutputs)
		}
		
		func setPixels(rgbColors: [JVEmbedded.Color.RGB]) throws {
			guard let handle = handle else { throw ESPError.fail }
			
			for index in 0..<rgbColors.count {
				let rgb = rgbColors[index]
				try setPixel(index: UInt32(index), red: UInt32(rgb.red), green: UInt32(rgb.green), blue: UInt32(rgb.blue))
			}
			
			for index in rgbColors.count..<pixelCount {
				try setPixel(index: UInt32(index), red: 0, green: 0, blue: 0)
			}
			
			try refresh()
		}
		
		private func setPixel(index: UInt32, red: UInt32, green: UInt32, blue: UInt32) throws {
			guard let handle = handle else { throw ESPError.fail }
			let result = handle.pointee.set_pixel(handle, index, red, green, blue)
			try ESPError.check(result)
		}
		
		private func refresh(timeoutMs: UInt32 = 100) throws {
			guard let handle = handle else { throw ESPError.fail }
			let result = handle.pointee.refresh(handle, timeoutMs)
			try ESPError.check(result)
		}
		
		private func clear(timeoutMs: UInt32 = 100) throws {
			guard let handle = handle else { throw ESPError.fail }
			let result = handle.pointee.clear(handle, timeoutMs)
			try ESPError.check(result)
		}
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

