// DiscreteRGBblinker.swift
// JVembedded
//
// Created by Jan Verrept on 05/11/2024.
//

class RGB_LEDdigital {
	
	enum RGBColor: String, CaseIterable {
		case red = "🔴"
		case green = "🟢"
		case blue = "🔵"
		case off = "⚫️"

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
					discreteRedLed.logicalValue = (color == .red)
					discreteGreenLed.logicalValue = (color == .green)
					discreteBlueLed.logicalValue = (color == .blue)
#if DEBUG
					let colorRepresentation:String = color.rawValue
					print("Switching color to \(colorRepresentation)")
#endif
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

