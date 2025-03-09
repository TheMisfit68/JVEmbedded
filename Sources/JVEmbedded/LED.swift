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
				self.syncHardware()
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
		
		init(redPWM: PWMConfiguration, greenPWM: PWMConfiguration, bluePWM: PWMConfiguration) {
			
			self.redOutput = PWMOutput(redPWM.pin, channelNumber: redPWM.channel)
			self.greenOutput = PWMOutput(greenPWM.pin, channelNumber: greenPWM.channel)
			self.blueOutput = PWMOutput(bluePWM.pin, channelNumber: bluePWM.channel)
			super.init()
			
			PWMOutput.installFadingService()
			self.syncHardware()
		}
		
		override func syncHardware() {
			
			var redPercentage: Int = 0
			var greenPercentage: Int = 0
			var bluePercentage: Int = 0
			
			if enabled {
				redPercentage = Int(round(Double(self.rgbOutput.red) / 255.0 * 100.0))
				greenPercentage = Int(round(Double(self.rgbOutput.green) / 255.0 * 100.0))
				bluePercentage = Int(round(Double(self.rgbOutput.blue) / 255.0 * 100.0))
				
				if (redPercentage == 0) && (greenPercentage == 0) && (bluePercentage == 0) {
					redPercentage = 5
					greenPercentage = 5
					bluePercentage = 5
				}
			}
			
			redOutput.fadeToPercentage(redPercentage, durationMs: 1000)
			greenOutput.fadeToPercentage(greenPercentage, durationMs: 1000)
			blueOutput.fadeToPercentage(bluePercentage, durationMs: 1000)
		}
		
	}
	
	// MARK: - Addressable like WS2812B
	public final class Addressable: LED.RGB {
		
		private var handle: led_driver_handle_t
		
		init(pinNumber: Int? = nil) {
			var config = led_driver_get_config()
			if let pinNumber = pinNumber {
				config.gpio = Int32(pinNumber)
			}
			guard let handle = led_driver_init(&config) else {
				fatalError("[⚠️ LED.Addressable.init] Failed to initialize LED driver handle")
			}
			self.handle = handle
			
			super.init()
			self.syncHardware()
		}
		
		override func syncHardware() {
			led_driver_set_power(handle, self.enabled)
			led_driver_set_hue(handle, UInt16(self.color.hue))
			led_driver_set_saturation(handle, UInt8(self.color.saturation))
			led_driver_set_brightness(handle, UInt8(self.color.brightness))
		}
	}
	
	// MARK: - Addressable strip
	public final class Strip {
		
		public typealias matrix = LED.Strip
		
		/// Convenience accessor for function pointers
		private var cFunctionPointers: led_strip_t { handle.pointee }
		typealias ledStripHandle = UnsafeMutablePointer<led_strip_t>
		private var handle: ledStripHandle
		
		public var enabled: Bool = false{
			didSet{
				syncHardware()
			}
		}
		
		public var colors: [JVEmbedded.Color.HSB] = [] {
			didSet {
				syncHardware()
			}
		}
		
		init(pinNumber: Int, pixelCount: Int = 2) {
			var stripConfig = led_strip_config_t(max_leds: UInt32(pixelCount), dev: 0)
			
			// Create the LED strip instance
			guard let stripHandle = led_strip_new_rmt_ws2812(&stripConfig) else {
				fatalError("⚠️ [LED.Strip.init] Failed to initialize LED strip")
			}
			
			self.handle = stripHandle
			self.colors = Array(repeating: JVEmbedded.Color.HSB.off, count: pixelCount)
		}
		
		deinit {
			if let delFunction = cFunctionPointers.del {
				let result = delFunction(handle)
				if result != ESP_OK {
					print("⚠️ [LED.Strip.deinit] Failed to delete LED strip resources")
				}
			}
		}
		
		/// Sets the color of a specific pixel in the LED strip
		public func setColorForPixel(atIndex index: Int, color: JVEmbedded.Color.HSB) {
			guard index >= 0, index < colors.count else {
				print("⚠️ [LED.Strip.setColorForPixel] Pixel index \(index) out of bounds")
				return
			}
			
			colors[index] = color
			
			if let setPixelFunction = cFunctionPointers.set_pixel {
				let result = setPixelFunction(handle, UInt32(index), UInt32(color.hue), UInt32(color.saturation), UInt32(color.brightness))
				if result != ESP_OK {
					print("⚠️ [LED.Strip.setColorForPixel] Failed to set pixel color at index \(index), error: \(result)")
				}
			}
		}
		
		func syncHardware() {
			if self.enabled && !colors.isEmpty {
				for (index, color) in colors.enumerated() {
					setColorForPixel(atIndex: index, color: color)
				}
			} else {
				if let clearFunction = cFunctionPointers.clear {
					clearFunction(handle, UInt32(1000))
				}
			}
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
	
	
	public func fade(){
		
		guard enabled else { self.color = JVEmbedded.Color.HSB.off; return}
		self.color.fade(withinRanges: JVEmbedded.Color.HSB.fullRange)
		
	}
	
	// Color transition (flame flicker effect)
	public func flicker(intensity:Float = 50.0) {
		guard enabled else { self.color = JVEmbedded.Color.HSB.off; return}
		let flickerRanges: JVEmbedded.Color.HSB.hsbRanges = (
			hue: 0.0...60.0, // Keeps the hue within yellow-to-red range
			saturation: 50.0...100.0, // Moderate saturation for vivid colors
			brightness: 30.0...80.0 // Keeps the brightness in a reasonable range
		)
		self.color.fade(atSpeed: intensity, withinRanges: flickerRanges)
	}
	
}

