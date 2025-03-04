//
//  RGB_LED.swift
//  JVEmbedded
//
//  Created by Jan Verrept on 02/03/2025.
//

public class LED{
	var on:Bool = false
}

protocol RGBDriver {
	var enabled: Bool { get set }
	var color: JVEmbedded.Color.HSB { get set }
	func setHardwareEnable()
	func setHardwareColor()
}

public class RGBLED:RGBDriver{
	
	public var pixelNumber:Int = 1
	public var enabled: Bool = false {
		didSet {
			if !enabled {
				self.color = JVEmbedded.Color.HSB.off
			}
			self.setHardwareEnable()
		}
	}
	public var color: JVEmbedded.Color.HSB = JVEmbedded.Color.HSB.off {
		didSet {
			self.setHardwareColor()
		}
	}
	
	func setHardwareEnable() {
		fatalError("⚠️ [RGBLED.setHardwareEnable] must be overridden!")
	}
	
	func setHardwareColor() {
		fatalError("⚠️ [RGBLED.setHardwareColor] must be overridden!")
	}
}

// MARK: - Addressable like WS2812B
extension RGBLED{
	
	public final class Addressable: RGBLED {
		
		private var handle: led_driver_handle_t
		
		init(pinNumber: Int? = nil) {
			var config = led_driver_get_config()
			if let pinNumber = pinNumber {
				config.gpio = Int32(pinNumber)
			}
			guard let handle = led_driver_init(&config) else {
				fatalError("Failed to initialize LED driver handle")
			}
			self.handle = handle
			
			super.init()
			self.setHardwareEnable()
			self.setHardwareColor()
		}
		
		override func setHardwareEnable() {
			led_driver_set_power(handle, self.enabled)
		}
		
		override func setHardwareColor() {
			led_driver_set_hue(handle, UInt16(self.color.hue))
			led_driver_set_saturation(handle, UInt8(self.color.saturation))
			led_driver_set_brightness(handle, UInt8(self.color.brightness))
			
		}
	}
	
//	extension RGBLED.Addressable {
//		public final class Strip {
//			
//			private var pixelCount: Int
//			private var pixels: [RGBLED.Addressable]
//			
//			init(pixelCount: Int, pinNumber: Int? = nil) {
//				self.pixelCount = pixelCount
//				self.pixels = (0..<pixelCount).map { _ in RGBLED.Addressable(pinNumber: pinNumber) }
//			}
//			
//			// Set color for a specific pixel
//			public func setPixelColor(at index: Int, to color: JVEmbedded.Color.HSB) {
//				guard index >= 0 && index < pixelCount else { return }
//				pixels[index].color = color
//			}
//			
//			// Set colors for all pixels at once
//			public func setAllPixels(colors: [JVEmbedded.Color.HSB]) {
//				for (index, color) in colors.prefix(pixelCount).enumerated() {
//					pixels[index].color = color
//				}
//			}
//			
//			// Batch update for better efficiency
//			public func updateHardware() {
//				for pixel in pixels {
//					pixel.setHardwareColor()
//				}
//			}
//			
//			// Apply a gradient effect
//			public func applyGradient(startColor: JVEmbedded.Color.HSB, endColor: JVEmbedded.Color.HSB) {
//				for i in 0..<pixelCount {
//					let ratio = Float(i) / Float(pixelCount - 1)
//					let blendedColor = startColor.interpolate(to: endColor, ratio: ratio)
//					pixels[i].color = blendedColor
//				}
//			}
//		}
//	}

	// MARK: - Analog with 3 discrete channels
	public final class Analog: RGBLED {
		
		override public var color: JVEmbedded.Color.HSB{
			didSet {
				rgbOutput = JVEmbedded.Color.RGB(using: self.color)
				if color != JVEmbedded.Color.HSB.off && !self.enabled {
					self.enabled = true
				}
			}
		}
		
		private var rgbOutput: JVEmbedded.Color.RGB = JVEmbedded.Color.RGB.off {
			didSet {
				self.setHardwareColor()
			}
		}
		
		private var redOutput: PWMOutput
		private var greenOutput: PWMOutput
		private var blueOutput: PWMOutput
		
		init(redPWM: PWMConfiguration, greenPWM: PWMConfiguration, bluePWM: PWMConfiguration) {
			
			self.redOutput = PWMOutput(redPWM.pin, channelNumber: redPWM.channel)
			self.greenOutput = PWMOutput(greenPWM.pin, channelNumber: greenPWM.channel)
			self.blueOutput = PWMOutput(bluePWM.pin, channelNumber: bluePWM.channel)
			super.init()
			
			PWMOutput.installFadingService()
			self.setHardwareEnable()
			self.setHardwareColor()
		}
		
		override public func setHardwareEnable() {
			redOutput.setPercentage(to: enabled ? 5 : 0)
			greenOutput.setPercentage(to: enabled ? 5 : 0)
			blueOutput.setPercentage(to: enabled ? 5 : 0)
		}
		
		override public func setHardwareColor() {
			var redPercentage: Int = 0
			var greenPercentage: Int = 0
			var bluePercentage: Int = 0
			
			if enabled {
				redPercentage = Int(round(Double(self.rgbOutput.red) / 255.0 * 100.0))
				greenPercentage = Int(round(Double(self.rgbOutput.green) / 255.0 * 100.0))
				bluePercentage = Int(round(Double(self.rgbOutput.blue) / 255.0 * 100.0))
				
				if redPercentage == 0 && greenPercentage == 0 && bluePercentage == 0 {
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
}


// MARK: - Analog RBG DEMO/testing methods
extension RGBLED{
	
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



