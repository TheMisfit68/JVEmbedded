extension JVEmbedded{
	
	public struct Color {
		
		public struct RGB: Equatable, CustomStringConvertible {
			
			// MARK: - Equatable Protocol
			public static func ==(lhs: RGB, rhs: RGB) -> Bool {
				let epsilon: Float = 0.0001
				return abs(lhs.red - rhs.red) < epsilon &&
				abs(lhs.green - rhs.green) < epsilon &&
				abs(lhs.blue - rhs.blue) < epsilon
			}
			
			public typealias rgbRanges = (red: ClosedRange<Float>, green: ClosedRange<Float>, blue: ClosedRange<Float>)
			public typealias rgbValues = (red: Float, green: Float, blue: Float)
			
			// MARK: - Common colors
			public static let none = JVEmbedded.Color.RGB(red: 0.0, green: 0.0, blue: 0.0)
			public static let off = JVEmbedded.Color.RGB(red: 0.0, green: 0.0, blue: 0.0)
			public static let black = JVEmbedded.Color.RGB(red: 0.0, green: 0.0, blue: 0.0)
			public static let white = JVEmbedded.Color.RGB(red: 255.0, green: 255.0, blue: 255.0)
			public static let red = JVEmbedded.Color.RGB(red: 255.0, green: 0.0, blue: 0.0)
			public static let orange = JVEmbedded.Color.RGB(red: 255.0, green: 165.0, blue: 0.0)
			public static let yellow = JVEmbedded.Color.RGB(red: 255.0, green: 255.0, blue: 0.0)
			public static let green = JVEmbedded.Color.RGB(red: 0.0, green: 255.0, blue: 0.0)
			public static let blue = JVEmbedded.Color.RGB(red: 0.0, green: 0.0, blue: 255.0)
			public static let indigo = JVEmbedded.Color.RGB(red: 75.0, green: 0.0, blue: 130.0)
			public static let violet = JVEmbedded.Color.RGB(red: 238.0, green: 130.0, blue: 238.0)
			
			// MARK: - Range and values
			public static let fullRange: rgbRanges = (red: 0.0...255.0, green: 0.0...255.0, blue: 0.0...255.0)
			private var components: rgbValues {
				didSet {
					self.clamped(to: JVEmbedded.Color.RGB.fullRange)
#if DEBUG
					print("Updated RGB color to:\n\(description)")
#endif
				}
			}
			
			// MARK: - Individual computed properties
			public var red: Float {
				get { components.red }
				set { components.red = newValue.clamped(to: JVEmbedded.Color.RGB.fullRange.red) }
			}
			
			public var green: Float {
				get { components.green }
				set { components.green = newValue.clamped(to: JVEmbedded.Color.RGB.fullRange.green) }
			}
			
			public var blue: Float {
				get { components.blue }
				set { components.blue = newValue.clamped(to: JVEmbedded.Color.RGB.fullRange.blue) }
			}
			
			public var description: String {
				return "🔴🟢🔵\t\(self.red)\t\(self.green)\t\(self.blue)"
			}
			
			// MARK: - Initializers
			public init(red: Float, green: Float, blue: Float) {
				self.components = (red, green, blue)
			}
			
			public init(using hsbColor: Color.HSB) {
				
				let hue = hsbColor.hue / 360.0
				let saturation = hsbColor.saturation / 100.0
				let brightness = hsbColor.brightness / 100.0
				
				let chroma = brightness * saturation
				let secondaryComponent = chroma * (1 - abs((hue * 6).truncatingRemainder(dividingBy: 2) - 1))
				let match = brightness - chroma
				
				let (red, green, blue): (Float, Float, Float)
				
				switch Int(hue * 6) {
					case 0:  (red, green, blue) = (chroma, secondaryComponent, 0)
					case 1:  (red, green, blue) = (secondaryComponent, chroma, 0)
					case 2:  (red, green, blue) = (0, chroma, secondaryComponent)
					case 3:  (red, green, blue) = (0, secondaryComponent, chroma)
					case 4:  (red, green, blue) = (secondaryComponent, 0, chroma)
					case 5:  (red, green, blue) = (chroma, 0, secondaryComponent)
					default: (red, green, blue) = (0, 0, 0)
				}
				
				self.init(
					red: (red + match) * JVEmbedded.Color.RGB.fullRange.red.upperBound,
					green: (green + match) * JVEmbedded.Color.RGB.fullRange.green.upperBound,
					blue: (blue + match) * JVEmbedded.Color.RGB.fullRange.blue.upperBound
				)
			}
			
			private mutating func clamped(to ranges: rgbRanges) {
				self.components = (
					red: self.red.clamped(to: ranges.red),
					green: self.green.clamped(to: ranges.green),
					blue: self.blue.clamped(to: ranges.blue)
				)
			}
		}
		
		
		public struct HSB: Equatable, CustomStringConvertible {
			
			public static func ==(lhs: HSB, rhs: HSB) -> Bool {
				let epsilon: Float = 0.0001
				return abs(lhs.hue - rhs.hue) < epsilon &&
				abs(lhs.saturation - rhs.saturation) < epsilon &&
				abs(lhs.brightness - rhs.brightness) < epsilon
			}
			
			// MARK: - Typealiases
			public typealias hsbRanges = (hue: ClosedRange<Float>, saturation: ClosedRange<Float>, brightness: ClosedRange<Float>)
			public typealias hsbValues = (hue: Float, saturation: Float, brightness: Float)
			
			// MARK: - Constants
			
			// Common Colors
			static let none = JVEmbedded.Color.HSB(hue: 0, saturation: 0, brightness: 0)
			static let off = JVEmbedded.Color.HSB(hue: 0.0, saturation: 0.0, brightness: 0.0)
			static let black = JVEmbedded.Color.HSB(hue: 0.0, saturation: 0.0, brightness: 0.0)
			static let white = JVEmbedded.Color.HSB(hue: 0.0, saturation: 0.0, brightness: 100.0)
			static let red = JVEmbedded.Color.HSB(hue: 0.0, saturation: 100.0, brightness: 100.0)
			static let orange = JVEmbedded.Color.HSB(hue: 30.0, saturation: 100.0, brightness: 100.0)
			static let yellow = JVEmbedded.Color.HSB(hue: 60.0, saturation: 100.0, brightness: 100.0)
			static let green = JVEmbedded.Color.HSB(hue: 120.0, saturation: 100.0, brightness: 100.0)
			static let blue = JVEmbedded.Color.HSB(hue: 240.0, saturation: 100.0, brightness: 100.0)
			static let indigo = JVEmbedded.Color.HSB(hue: 275.0, saturation: 100.0, brightness: 100.0)
			static let violet = JVEmbedded.Color.HSB(hue: 300.0, saturation: 100.0, brightness: 100.0)
			
			// MARK: - Range and values
			public static let fullRange: hsbRanges = (hue: 0.0...360.0, saturation: 0.0...100.0, brightness: 0.0...100.0)
			private var components: hsbValues {
				didSet {
					self.clamped(to: JVEmbedded.Color.HSB.fullRange)
#if DEBUG
					print("Updating HSB color to:\n\(description)")
#endif
				}
			}
			
			// MARK: - Individual computed properties
			
			public var hue: Float {
				get { components.hue }
				set { components.hue = newValue.clamped(to: JVEmbedded.Color.HSB.fullRange.hue) }
			}
			
			public var saturation: Float {
				get { components.saturation }
				set { components.saturation =  newValue.clamped(to: JVEmbedded.Color.HSB.fullRange.saturation) }
			}
			
			public var brightness: Float {
				get { components.brightness }
				set { components.brightness = newValue.clamped(to: JVEmbedded.Color.HSB.fullRange.brightness) }
			}
			
			// Temperature Calculation Properties
			private let minTemperature: Float = 3000.0
			private let maxTemperature: Float = 6500.0
			private let minHue: Float = 180.0
			private let maxHue: Float = 0.0
			
			public var temperature: Float {
				get {
					let hueRatio = (hue - minHue) / (maxHue - minHue)
					let tempRange = maxTemperature - minTemperature
					return (hueRatio * tempRange) + minTemperature
				}
				set {
					let clampedTemperature = newValue.clamped(to: minTemperature...maxTemperature)
					let tempRatio = (clampedTemperature - minTemperature) / (maxTemperature - minTemperature)
					hue = (tempRatio * (maxHue - minHue)) + minHue
				}
			}
			
			public var description: String {
				return "🎨🎚️🔆\t\(hue)\t\(saturation)\t\(brightness)"
			}
			
			// MARK: - Initializers
			public init(hue: Float, saturation: Float, brightness: Float) {
				self.components = (hue, saturation, brightness)
			}
			
			public init(using rgbColor: Color.RGB) {
				let red = rgbColor.red / 255.0
				let green = rgbColor.green / 255.0
				let blue = rgbColor.blue / 255.0
				
				let maxComponent = max(red, green, blue)
				let minComponent = min(red, green, blue)
				let delta = maxComponent - minComponent
				
				var hue: Float = 0
				var saturation: Float = 0
				let brightness = maxComponent
				
				if delta != 0 {
					saturation = delta / maxComponent
					
					if maxComponent == red {
						hue = ((green - blue) / delta).truncatingRemainder(dividingBy: 6)
					} else if maxComponent == green {
						hue = (blue - red) / delta + 2
					} else {
						hue = (red - green) / delta + 4
					}
					
					hue *= 60
					if hue < 0 { hue += 360 }
				}
				
				self.init(hue: hue, saturation: saturation * 100, brightness: brightness * 100)
			}
			
			// MARK: - Helper Method
			public mutating func clamped(to ranges: hsbRanges) {
				components = (
					hue: hue.clamped(to: ranges.hue),
					saturation: saturation.clamped(to: ranges.saturation),
					brightness: brightness.clamped(to: ranges.brightness)
				)
			}
		}
		
	}
	
}

// MARK: - Color Effects
extension JVEmbedded.Color.RGB {
	
	// RGB Color transition (color fade effect)
	public mutating func fade(atSpeed speed: Float = 100.0,
							  withinRanges ranges: JVEmbedded.Color.RGB.rgbRanges) {
		
		// Make sure everything has a valid range
		self.clamped(to: ranges)
		let clampedSpeed = speed.clamped(to: 0.0...100.0)
		
		// Convert speed into a scaling factor (percentage)
		let speedFactor = clampedSpeed / 100.0
		
		// Scale the ranges down by the speed factor (keeping all calculations in Float)
		let redDeltaRange = (ranges.red.lowerBound * speedFactor)...(ranges.red.upperBound * speedFactor)
		let greenDeltaRange = (ranges.green.lowerBound * speedFactor)...(ranges.green.upperBound * speedFactor)
		let blueDeltaRange = (ranges.blue.lowerBound * speedFactor)...(ranges.blue.upperBound * speedFactor)
		
		// Get a random delta value for each color component from the ranges
		let redDelta = Float.random(in: redDeltaRange)
		let greenDelta = Float.random(in: greenDeltaRange)
		let blueDelta = Float.random(in: blueDeltaRange)
		
		// Adjust the compononents
		self.red += redDelta
		self.green += greenDelta
		self.blue += blueDelta
		
	}
	
}

extension JVEmbedded.Color.HSB {
	
	// HSB Color transition (color fade effect)
	public mutating func fade(atSpeed speed: Float = 100.0,
							  withinRanges ranges: JVEmbedded.Color.HSB.hsbRanges) {
		
		// Make sure everything has a valid range
		self.clamped(to: ranges)
		let clampedSpeed = speed.clamped(to: 0.0...100.0)
		
		// Convert speed into a scaling factor (percentage)
		let speedFactor = clampedSpeed / 100.0
		
		// Scale the ranges down by the speed factor (keep it in Float to preserve precision)
		let hueDeltaRange = (ranges.hue.lowerBound * speedFactor)...(ranges.hue.upperBound * speedFactor)
		let saturationDeltaRange = (ranges.saturation.lowerBound * speedFactor)...(ranges.saturation.upperBound * speedFactor)
		let brightnessDeltaRange = (ranges.brightness.lowerBound * speedFactor)...(ranges.brightness.upperBound * speedFactor)
		
		// Get a random delta value for each color component from the ranges (preserve Float)
		let hueDelta = Float.random(in: hueDeltaRange)
		let saturationDelta = Float.random(in: saturationDeltaRange)
		let brightnessDelta = Float.random(in: brightnessDeltaRange)
		
		// Adjust the compononents
		self.hue += hueDelta
		self.saturation += saturationDelta
		self.brightness += brightnessDelta
		
	}
	
}

