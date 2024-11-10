// RGB_LEDAnalog.swift
// JVIDF
//
// Created by Jan Verrept on 05/11/2024.
//

public struct PWMConfiguration {
	let pin: Int
	let channel: Int
}

final class RGB_LEDAnalog {
	
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
		
	// Method to gradually transition to the next color in a glowing effect
	public func glow() {
		// Only adjust the color if the LED is enabled
		if enabled {
			let deltaRange: ClosedRange<Int> = -255...255
			
			// Calculate random deltas for each color component
			var redDelta = Int.random(in: deltaRange)
			var greenDelta = Int.random(in: deltaRange)
			var blueDelta = Int.random(in: deltaRange)
			
			// Calculate the new color values based on the current color and the delta
			var newRed = Int(color.rgb.red) + redDelta
			var newGreen = Int(color.rgb.green) + greenDelta
			var newBlue = Int(color.rgb.blue) + blueDelta
			
			// Update each color component and reverse direction if necessary
			if newRed < 0 || newRed > 255 {
				redDelta = -redDelta  // Reverse direction when hitting boundaries
			}
			if newGreen < 0 || newGreen > 255 {
				greenDelta = -greenDelta  // Reverse direction when hitting boundaries
			}
			if newBlue < 0 || newBlue > 255 {
				blueDelta = -blueDelta  // Reverse direction when hitting boundaries
			}
			
			// Ensure all components are within the valid range [0, 255]
			newRed = max(0, min(255, newRed))
			newGreen = max(0, min(255, newGreen))
			newBlue = max(0, min(255, newBlue))
			
			// Create a new color with the updated values
			let newColor = RGBColor(red: UInt8(newRed), green: UInt8(newGreen), blue: UInt8(newBlue))
			color = newColor
		}
	}
}
