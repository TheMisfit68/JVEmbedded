// RGB_LEDanalog.swift
// JVembedded
//
// Created by Jan Verrept on 05/11/2024.
//

public struct PWMConfiguration {
	let pin: Int
	let channel: Int
}

final class RGB_LEDanalog {
	
	private var redLed: PWMOutput
	private var greenLed: PWMOutput
	private var blueLed: PWMOutput
	
	init(redConfig: PWMConfiguration, greenConfig: PWMConfiguration, blueConfig: PWMConfiguration) {
		self.redLed = PWMOutput(redConfig.pin, channelNumber: redConfig.channel)
		self.greenLed = PWMOutput(greenConfig.pin, channelNumber: greenConfig.channel)
		self.blueLed = PWMOutput(blueConfig.pin, channelNumber: blueConfig.channel)
		
		redLed.setPercentage(to: 0)
		greenLed.setPercentage(to: 0)
		blueLed.setPercentage(to: 0)
	}
	
	public var enabled: Bool = false {
		didSet {
			if !enabled {
				// When disabled, set color to black (off)
				color = RGBColor.black
				// Directly set duty cycles to 0 to turn off LEDs
				redLed.setPercentage(to: 0)
				greenLed.setPercentage(to: 0)
				blueLed.setPercentage(to: 0)
			}
		}
	}
	
	// Color property using the defined Color enum
	public var color: RGBColor = RGBColor.black {
		didSet {
			
			// Convert RGB values to percentages (0-100)
			var redPercentage = Int( Float(color.rgb.red) / 255 * 100 )
			var greenPercentage = Int( Float(color.rgb.green) / 255 * 100 )
			var bluePercentage = Int( Float(color.rgb.blue) / 255 * 100 )
			
			// While enabled, prevent all LEDs from being off
			if enabled && (redPercentage == 0) && (greenPercentage == 0) && (bluePercentage == 0) {
				redPercentage = 5
				greenPercentage = 5
				bluePercentage = 5
			}
#if DEBUG
			print("Updating channel to: 🔴 \(redPercentage)%")
			print("Updating channel to: 🟢 \(greenPercentage)%")
			print("Updating channel to: 🔵 \(bluePercentage)%")
			print("")
#endif
			
			redLed.fadeToPercentage(redPercentage, durationMs: 1000)
			greenLed.fadeToPercentage(greenPercentage, durationMs: 1000)
			blueLed.fadeToPercentage(bluePercentage, durationMs: 1000)
		}
	}
		
	public func breath(ranges: (ClosedRange<Int>, ClosedRange<Int>, ClosedRange<Int>) = (-255...255, -255...255, -255...255)) {
		if enabled {
			let (redRange, greenRange, blueRange) = ranges
			
			// Bereken willekeurige deltas binnen de gespecificeerde ranges
			var redDelta = Int.random(in: redRange)
			var greenDelta = Int.random(in: greenRange)
			var blueDelta = Int.random(in: blueRange)
			
			// Bereken de nieuwe kleurwaarden
			var newRed = Int(color.rgb.red) + redDelta
			var newGreen = Int(color.rgb.green) + greenDelta
			var newBlue = Int(color.rgb.blue) + blueDelta
			
			// Omkeren als grenzen worden overschreden
			if newRed < 0 || newRed > 255 { redDelta = -redDelta }
			if newGreen < 0 || newGreen > 255 { greenDelta = -greenDelta }
			if newBlue < 0 || newBlue > 255 { blueDelta = -blueDelta }
			
			// Houd de waarden binnen 0-255
			newRed = max(0, min(255, newRed))
			newGreen = max(0, min(255, newGreen))
			newBlue = max(0, min(255, newBlue))
			
			// Update de kleur
			color = RGBColor(red: UInt8(newRed), green: UInt8(newGreen), blue: UInt8(newBlue))
		}
	}
	
	public func flicker(intensity: Int = 50) {
		// Kleiner bereik voor een kaarsachtig flikkereffect
		let flickerRanges = (-intensity...intensity, -intensity/2...intensity/2, -intensity/4...intensity/4)
		breath(ranges: flickerRanges)
	}
}
