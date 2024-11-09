// DiscreteRGBblinker.swift
// JVIDF
//
// Created by Jan Verrept on 05/11/2024.
//

class RGB_LEDdigital {
	
	enum RGBColor: CaseIterable {
		case red
		case green
		case blue
		case off
		
		// Method to get the next color in the sequence
		func next() -> RGBColor {
			
			// Find the next color, cycling back to the first after the last
			let allColors = RGBColor.allCases
			if let currentIndex = allColors.firstIndex(of: self) {
				let nextIndex = (currentIndex + 1) % allColors.count
				return allColors[nextIndex]
			}
			return .off
		}
	}
	
	public var enabled: Bool = false {
		didSet {
			if !enabled {
				color = .off
			}
		}
	}
	
	public var color: RGBColor = .off {
		didSet {
			switch color {
				case .red:
#if DEBUG
					print("Switching color to 🔴")
#endif
					discreteRedLed.logicalValue = true
					discreteGreenLed.logicalValue = false
					discreteBlueLed.logicalValue = false
				case .green:
#if DEBUG
					print("Switching color to 🟢")
#endif
					discreteRedLed.logicalValue = false
					discreteGreenLed.logicalValue = true
					discreteBlueLed.logicalValue = false
				case .blue:
#if DEBUG
					print("Switching color to 🔵")
#endif
					discreteRedLed.logicalValue = false
					discreteGreenLed.logicalValue = false
					discreteBlueLed.logicalValue = true
				case .off:
#if DEBUG
					print("Switching leds off ⚪️")
#endif
					discreteRedLed.logicalValue = false
					discreteGreenLed.logicalValue = false
					discreteBlueLed.logicalValue = false
			}
		}
	}
	
	private var discreteRedLed: DigitalOutput
	private var discreteGreenLed: DigitalOutput
	private var discreteBlueLed: DigitalOutput
	
	init(redPin: Int, greenPin: Int, bluePin: Int) {
		self.discreteRedLed = DigitalOutput(redPin)
		self.discreteGreenLed = DigitalOutput(greenPin)
		self.discreteBlueLed = DigitalOutput(bluePin)
	}
	
	// Method to select the next color
	public func cycleToNextColor() {
		if enabled {
			color = color.next()
		}else{
			color = .off
		}
	}
}

