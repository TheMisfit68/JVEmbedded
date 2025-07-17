//
//  Addressable.swift
//  JVEmbedded
//
//  Created by Jan Verrept on 16/07/2025.
//

// MARK: - Addressable LED like WS2812B
// (=5050 with integrated controller)

extension LED {
	
	open class Addressable: LED.RGB {
		
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
}

// MARK: - Addressable strip
extension LED {
	
	public typealias Matrix = LED.Strip
	
	open class Strip: LED.RGB {
		
		private(set) var handle: UnsafeMutablePointer<led_strip_t>?
		public let pixelCount: Int
		
		public override var enabled: Bool {
			didSet {
				if !enabled {
					self.rgbOutputs = Array(repeating: JVEmbedded.Color.RGB.off, count: pixelCount)
				} else {
					self.rgbOutputs = self.colors.map { JVEmbedded.Color.RGB(using: $0) }
				}
			}
		}
		
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
		
		// MARK: - Init
		public init(pinNumber: Int32, channelNumber: UInt32 = 0, pixelCount: Int = 2) throws(ESPError) {
			
			self.pixelCount = pixelCount
			
			self.colors = Array(repeating: JVEmbedded.Color.HSB.off, count: pixelCount)
			self.rgbOutputs = Array(repeating: JVEmbedded.Color.RGB.off, count: pixelCount)
			
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
			
			super.init()
			self.syncHardware()
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
			guard let handle = handle else { return }
			
			do{
				
				for index in 0..<rgbOutputs.count {
					let rgb = rgbOutputs[index]
					try setPixel(index: UInt32(index), red: UInt32(rgb.red), green: UInt32(rgb.green), blue: UInt32(rgb.blue))
				}
				
				
				for index in rgbOutputs.count..<pixelCount {
					try setPixel(index: UInt32(index), red: 0, green: 0, blue: 0)
				}
				try refresh()
				
			}catch {
				print("[⚠️ LED.Strip.syncHardware] Error refreshing strip: \(error)")
			}
		}
		
		// MARK: - Multiple pixel control methods
		
		/// Sets the given colors into the specified pixel range,
		/// and sets all other pixels to `.off`.
		///
		/// - Parameters:
		///   - colors: The color values to apply.
		///   - range: The pixel range to apply them to (must match `colors.count`).
		///   - clearOutsideRange: clear the pixels that are outside the applied range.
		public func setColors(_ colors: [JVEmbedded.Color.HSB],
							  atRange range: Range<Int>,
							  clearOutsideRange: Bool = true) {
			
			// Prepare newColors: either start from .off or preserve existing colors
			var newColors: [JVEmbedded.Color.HSB] = clearOutsideRange ? Array(repeating: .off, count: self.pixelCount) : self.colors
			
			// Apply only the provided colors
			for (offset, pixelIndex) in range.enumerated() {
				guard offset < colors.count else { break }
				guard pixelIndex >= 0 && pixelIndex < self.pixelCount else { continue }
				newColors[pixelIndex] = colors[offset]
			}
			
			self.colors = newColors
		}
		
		
		
		/// Sets colors in the specified range using a closure.
		public func setColors(atRange range: Range<Int>,
							  clearOutsideRange: Bool = true,
							  generator: (Int) -> JVEmbedded.Color.HSB) {
			
			let colors = range.map(generator)
			self.setColors(colors, atRange: range, clearOutsideRange: clearOutsideRange)
		}
		
		// MARK: - Private subroutines
		private func setPixel(index: UInt32, red: UInt32, green: UInt32, blue: UInt32) throws(ESPError) {
			guard let handle = handle else { throw ESPError.fail }
			let result = handle.pointee.set_pixel(handle, index, red, green, blue)
			try ESPError.check(result)
		}
		
		private func refresh(timeoutMs: UInt32 = 100) throws(ESPError) {
			guard let handle = handle else { throw ESPError.fail }
			let result = handle.pointee.refresh(handle, timeoutMs)
			try ESPError.check(result)
		}
		
		private func clear(timeoutMs: UInt32 = 100) throws(ESPError) {
			guard let handle = handle else { throw ESPError.fail }
			let result = handle.pointee.clear(handle, timeoutMs)
			try ESPError.check(result)
		}
	}
	
}

// MARK: - Effects for addressable LED strips
extension LED.Strip {
	
	/// Applies a gradient of colors from `startColor` to `endColor` across the specified range.
	public func applyGradient(from startColor: JVEmbedded.Color.HSB,
							  to endColor: JVEmbedded.Color.HSB,
							  atRange range: Range<Int>,
							  clearOutsideRange: Bool = true) {
		
		let span = max(1, range.count - 1)
		
		self.setColors(atRange: range, clearOutsideRange: clearOutsideRange) { index in
			let fraction = Double(index - range.lowerBound) / Double(span)
			return startColor.interpolate(to: endColor, fraction: fraction)
		}
	}
	
	/// Applies a repeating pattern of colors across the specified range.
	public func applyPattern(_ pattern: [JVEmbedded.Color.HSB],
							 atRange range: Range<Int>,
							 clearOutsideRange: Bool = true) {
		
		guard !pattern.isEmpty else { return }
		
		self.setColors(atRange: range, clearOutsideRange: clearOutsideRange) { index in
			let offset = index - range.lowerBound
			return pattern[offset % pattern.count]
		}
	}
	
}

