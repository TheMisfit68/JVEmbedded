// RGBColor.swift
// JVembedded
//
// Created by Jan Verrept on 05/11/2024.
//

struct RGBColor: Equatable{
	
	// Factory methods for common colors
	static var black: RGBColor { RGBColor(red: 0, green: 0, blue: 0) }
	static var white: RGBColor { RGBColor(red: 255, green: 255, blue: 255) }
	static var red: RGBColor { RGBColor(red: 255, green: 0, blue: 0) }
	static var orange: RGBColor { RGBColor(red: 255, green: 165, blue: 0) }
	static var yellow: RGBColor { RGBColor(red: 255, green: 255, blue: 0) }
	static var green: RGBColor { RGBColor(red: 0, green: 255, blue: 0) }
	static var blue: RGBColor { RGBColor(red: 0, green: 0, blue: 255) }
	static var indigo: RGBColor { RGBColor(red: 75, green: 0, blue: 130) }
	static var violet: RGBColor { RGBColor(red: 238, green: 130, blue: 238) }
	
	// Public RGB values
	public var rgb: (red: UInt8, green: UInt8, blue: UInt8)
	
	// RGB Initializer/Users/janverrept/JVEmbedded/JVMatter/JVembedded/RGB_Color.swift
	init(red: UInt8, green: UInt8, blue: UInt8) {
		self.rgb = (red, green, blue)
	}
	
	// Convenience Initializer for Hue and Saturation
	init(hue: Int, saturation: Int) {
		let rgbComponents = RGBColor.hslToRgb(hue: Float(hue) / 360.0, saturation: Float(saturation) / 100.0, lightness: 0.5)
		self.init(red: rgbComponents.0, green: rgbComponents.1, blue: rgbComponents.2)
	}
	
	// Convenience Initializer for Temperature
	init(temperature: Int) {
		let rgbComponents = RGBColor.temperatureToRgb(temperature: temperature)
		self.init(red: rgbComponents.0, green: rgbComponents.1, blue: rgbComponents.2)
	}
	
	// Private method to convert HSL to RGB
	private static func hslToRgb(hue: Float, saturation: Float, lightness: Float) -> (UInt8, UInt8, UInt8) {
		var r: Float = 0, g: Float = 0, b: Float = 0
		
		if saturation == 0 {
			r = lightness
			g = lightness
			b = lightness // Achromatic (grey)
		} else {
			let q = lightness < 0.5 ? lightness * (1 + saturation) : lightness + saturation - lightness * saturation
			let p = 2 * lightness - q
			r = hueToRgb(p: p, q: q, t: hue + 1.0 / 3.0)
			g = hueToRgb(p: p, q: q, t: hue)
			b = hueToRgb(p: p, q: q, t: hue - 1.0 / 3.0)
		}
		
		return (UInt8(r * 255), UInt8(g * 255), UInt8(b * 255))
	}
	
	// Private method to convert hue to RGB
	private static func hueToRgb(p: Float, q: Float, t: Float) -> Float {
		var t = t
		if t < 0 { t += 1 }
		if t > 1 { t -= 1 }
		if t < 1.0 / 6.0 { return p + (q - p) * 6 * t }
		if t < 0.5 { return q }
		if t < 2.0 / 3.0 { return p + (q - p) * (2.0 / 3.0 - t) * 6 }
		return p
	}
	
	// Private method to convert Temperature to RGB
	private static func temperatureToRgb(temperature: Int) -> (UInt8, UInt8, UInt8) {
		// Placeholder for temperature to RGB conversion logic
		return (255, 255, 255) // White as a placeholder
	}
	
	// Conformance to Equatable, defining == operator
	public static func ==(lhs: RGBColor, rhs: RGBColor) -> Bool {
		return lhs.rgb.red == rhs.rgb.red && lhs.rgb.green == rhs.rgb.green && lhs.rgb.blue == rhs.rgb.blue
	}
}
