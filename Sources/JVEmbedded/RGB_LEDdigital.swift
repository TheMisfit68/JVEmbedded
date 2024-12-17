// RGB_LEDdigital.swift
// JVIDF
//
// Created by Jan Verrept on 05/11/2024.
//

class RGB_LEDdigital {
	
	enum RGBColor:CaseIterable {
		
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
		
		// Computed property for emoji representation of the color
		var representation: String {
			switch self {
				case .red: return "🔴"
				case .green: return "🟢"
				case .blue: return "🔵"
				case .off: return "⚪️"
			}
		}
	}
	
	public var enabled: Bool = false {
		didSet {
			if !enabled {
				color = .off
			}
		}
	}
	
	public var color: RGBColor{
		didSet {
			print("Switching color to \(color.representation)")
			discreteRedLed.logicalValue = (color == .red)
			discreteGreenLed.logicalValue = (color == .green)
			discreteBlueLed.logicalValue = (color == .blue)
		}
	}
	
	private var discreteRedLed: DigitalOutput
	private var discreteGreenLed: DigitalOutput
	private var discreteBlueLed: DigitalOutput
	
	init(redPin: Int, greenPin: Int, bluePin: Int) {
		self.discreteRedLed = DigitalOutput(redPin)
		self.discreteGreenLed = DigitalOutput(greenPin)
		self.discreteBlueLed = DigitalOutput(bluePin)
		self.color = .off // Safe to initialize after LED properties
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

