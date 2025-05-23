//
//  FloatDouble.swift
//  JVEmbedded
//
//  Created by Jan Verrept on 22/05/2025.
//

extension Double: JSONStringConvertible {
	
	public var jsonString: String {
		let isNegative = self < 0
		let absValue = Swift.abs(self)
		
		let integerPart = Int(absValue)
		let fractionalMultiplier = 1_000 // 3 decimal digits
		let fractionalPart = Int((absValue - Double(integerPart)) * Double(fractionalMultiplier))
		
		// Left-pad the fractional part with zeros if needed
		var fracStr = String(fractionalPart)
		while fracStr.count < 3 {
			fracStr = "0" + fracStr
		}
		
		let sign = isNegative ? "-" : ""
		let finalString = sign + "\(integerPart).\(fracStr)"
		return "\"\(finalString)\""
	}
	
}
