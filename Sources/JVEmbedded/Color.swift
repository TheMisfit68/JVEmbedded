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
					if components != oldValue {
						self.clamp(to: JVEmbedded.Color.RGB.fullRange)
					}
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
				// Convert every component to a Int first because of the limitations for printing floats in embedded Swift
				let red = Int(self.red)
				let green = Int(self.green)
				let blue = Int(self.blue)
				return "🔴 🟢 🔵\t\(red)\t\(green)\t\(blue)"
			}
			
			// Use a HSB color as a go between to modify the brightness on a RGB color
			public var brightness: Float {
				get {
					return Color.HSB(using: self).brightness
				}
				set {
					var hsbEquivalent = Color.HSB(using: self) // Convert to HSB
					hsbEquivalent.brightness = newValue       // Modify brightness
					self.components = Color.RGB(using: hsbEquivalent).components // Convert back
				}
			}
			
			// MARK: - Initializers
			public init(red: Float, green: Float, blue: Float) {
				self.components = (red, green, blue)
				self.clamp(to: JVEmbedded.Color.RGB.fullRange)
			}
			
			// Convinience initializer for HSB to RGB conversion
			public init(using hsbColor: Color.HSB) {
				let hue: Float = hsbColor.hue / JVEmbedded.Color.HSB.fullRange.hue.upperBound
				let saturation: Float = hsbColor.saturation / JVEmbedded.Color.HSB.fullRange.saturation.upperBound
				let brightness: Float = hsbColor.brightness / JVEmbedded.Color.HSB.fullRange.brightness.upperBound
				
				let chroma: Float = brightness * saturation
				let secondaryComponent: Float = chroma * (1 - abs((hue * 6).truncatingRemainder(dividingBy: 2) - 1))
				let match: Float = brightness - chroma
				
				let red: Float, green: Float, blue: Float
				
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
			
			private mutating func clamp(to ranges: rgbRanges) {
				self.red.clamp(to: ranges.red)
				self.green.clamp(to: ranges.green)
				self.blue.clamp(to: ranges.blue)
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
			static let none = JVEmbedded.Color.HSB(hue: 0.0, saturation: 0.0, brightness: 0.0)
			static let off = JVEmbedded.Color.HSB(hue: 0.0, saturation: 0.0, brightness: 0.0)
			static let black = JVEmbedded.Color.HSB(hue: 0.0, saturation: 0.0, brightness: 0.0)
			static let white = JVEmbedded.Color.HSB(hue: 0.0, saturation: 0.0, brightness: 100.0)
			static let red = JVEmbedded.Color.HSB(hue: 0.0, saturation: 100.0, brightness: 100.0)
			static let orange = JVEmbedded.Color.HSB(hue: 20.0, saturation: 100.0, brightness: 100.0)
			static let yellow = JVEmbedded.Color.HSB(hue: 60.0, saturation: 100.0, brightness: 100.0)
			static let green = JVEmbedded.Color.HSB(hue: 120.0, saturation: 100.0, brightness: 100.0)
			static let blue = JVEmbedded.Color.HSB(hue: 240.0, saturation: 100.0, brightness: 100.0)
			static let indigo = JVEmbedded.Color.HSB(hue: 275.0, saturation: 100.0, brightness: 100.0)
			static let violet = JVEmbedded.Color.HSB(hue: 300.0, saturation: 100.0, brightness: 100.0)
			
			// MARK: - Range and values
			public static let fullRange: hsbRanges = (hue: 0.0...360.0, saturation: 0.0...100.0, brightness: 0.0...100.0)
			private var components: hsbValues {
				didSet {
					if components != oldValue {
						self.clamp(to: JVEmbedded.Color.HSB.fullRange)
					}
				}
			}
			
			// MARK: - Individual computed properties
			public var hue: Float {
				get { components.hue }
				set { components.hue = newValue.clamped(to: JVEmbedded.Color.HSB.fullRange.hue) }
			}
			
			public var saturation: Float {
				get { components.saturation }
				set { components.saturation = newValue.clamped(to: JVEmbedded.Color.HSB.fullRange.saturation) }
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
				// Convert every component to a Int first because of the limitations for printing floats in embedded Swift
				let hue = Int(hue)
				let saturation = Int(saturation)
				let brightness = Int(brightness)
				return "🎨 🎚️ 🔆\t\(hue)\t\(saturation)\t\(brightness)"
			}
			
			// MARK: - Initializers
			public init(hue: Float, saturation: Float, brightness: Float) {
				self.components = (hue, saturation, brightness)
			}
			
			// Convinience initializer for RGB to HSB conversion
			public init(using rgbColor: Color.RGB) {
				let red: Float = rgbColor.red / JVEmbedded.Color.RGB.fullRange.red.upperBound
				let green: Float = rgbColor.green / JVEmbedded.Color.RGB.fullRange.green.upperBound
				let blue: Float = rgbColor.blue / JVEmbedded.Color.RGB.fullRange.blue.upperBound
				
				let maxComponent: Float = max(red, green, blue)
				let minComponent: Float = min(red, green, blue)
				let delta: Float = maxComponent - minComponent
				
				var hue: Float = 0
				var saturation: Float = 0
				let brightness: Float = maxComponent
				
				if delta != 0 {
					saturation = delta / maxComponent
					
					if maxComponent == red {
						hue = ((green - blue) / delta).truncatingRemainder(dividingBy: 6)
					} else if maxComponent == green {
						hue = (blue - red) / delta + 2
					} else {
						hue = (red - green) / delta + 4
					}
					
					hue *= JVEmbedded.Color.HSB.fullRange.hue.upperBound / 6  // Adjusting to full hue range
					if hue < 0 { hue += JVEmbedded.Color.HSB.fullRange.hue.upperBound }
				}
				
				self.init(
					hue: hue,
					saturation: saturation * JVEmbedded.Color.HSB.fullRange.saturation.upperBound,
					brightness: brightness * JVEmbedded.Color.HSB.fullRange.brightness.upperBound
				)
			}
			
			// MARK: - Helper Method
			public mutating func clamp(to ranges: hsbRanges) {
				self.hue.clamp(to: ranges.hue)
				self.saturation.clamp(to: ranges.saturation)
				self.brightness.clamp(to: ranges.brightness)
			}
		}
		
	}
	
}

// MARK: - Color Effects
extension JVEmbedded.Color.RGB {
	
	/// Randomly adjusts RGB values within specified per-channel ranges and clamps the result.
	public static func random(in ranges: rgbRanges =
						  (red: -255...255, green: -255...255, blue: -255...255) ) -> JVEmbedded.Color.RGB {
		
		// Apply random deltas
		let red = Float.random(in: ranges.red)
		let green = Float.random(in: ranges.green)
		let blue = Float.random(in: ranges.blue)
		
		// Final clamping to enforce valid RGB ranges
		return JVEmbedded.Color.RGB(red: red, green: green, blue: blue)
	}
}

extension JVEmbedded.Color.HSB {
	
	public static func random(in ranges: hsbRanges =
							(hue: -360...360, saturation: -100...100, brightness: -100...100) ) -> JVEmbedded.Color.HSB {
		
		// Apply random deltas
		let hue = Float.random(in: ranges.hue)
		let saturation = Float.random(in: ranges.saturation)
		let brightness = Float.random(in: ranges.brightness)
		
		// Final clamping to enforce valid HSB ranges
		return JVEmbedded.Color.HSB(hue: hue, saturation: saturation, brightness: brightness)
	}
	
	/// Randomly adjusts HSB values within specified per-channel ranges and clamps the result.
	public func offset(by ranges:hsbRanges =
	(hue: -360...360, saturation: -100...100, brightness: -100...100) ) -> JVEmbedded.Color.HSB {
		
		// Apply random deltas
		var hue = self.hue+Float.random(in: ranges.hue)
		var saturation = self.saturation+Float.random(in: ranges.saturation)
		var brightness = self.brightness+Float.random(in: ranges.brightness)
		
		if hue < 0 {
			hue += 360
		}
		if saturation < 0 {
			saturation = abs(saturation)
		}
		if brightness < 0 {
			brightness = abs(brightness)
		}
		
		return JVEmbedded.Color.HSB(hue: hue, saturation: saturation, brightness: brightness)
	}
	
}

