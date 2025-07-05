//
//  Double.swift
//  JVEmbedded
//
//  Created by Jan Verrept on 21/06/2025.
//


#if hasFeature(Embedded)


extension Swift.Double:LosslessStringConvertible{
	
	public init?(_ stringValue: String) {
		var value = 0.0
		var isNegative = false
		var seenDecimal = false
		var decimalFactor = 0.1
		var started = false
		
		for (i, char) in stringValue.enumerated() {
			if i == 0 && char == "-" {
				isNegative = true
				continue
			}
			if char == "." {
				if seenDecimal {
					return nil // multiple decimals not allowed
				}
				seenDecimal = true
				continue
			}
			guard let digit = char.asciiValue, digit >= 48, digit <= 57 else {
				return nil
			}
			started = true
			let num = Double(digit - 48)
			if seenDecimal {
				value += num * decimalFactor
				decimalFactor *= 0.1
			} else {
				value = value * 10 + num
			}
		}
		
		guard started else { return nil }
		self = isNegative ? -value : value
	}
	
	public var description: String {
		return String(self, precision: 6)
	}
	
}

#endif

//
//  Double.swift
//  JVEmbedded
//
//  Created by Jan Verrept on 21/06/2025.
//

#if hasFeature(Embedded)


extension Swift.Double{
	
	public init?(embeddedString stringValue: String) {
		var value = 0.0
		var isNegative = false
		var seenDecimal = false
		var decimalFactor = 0.1
		var started = false
		
		for (i, char) in stringValue.enumerated() {
			if i == 0 && char == "-" {
				isNegative = true
				continue
			}
			if char == "." {
				if seenDecimal {
					return nil // multiple decimals not allowed
				}
				seenDecimal = true
				continue
			}
			guard let digit = char.asciiValue, digit >= 48, digit <= 57 else {
				return nil
			}
			started = true
			let num = Double(digit - 48)
			if seenDecimal {
				value += num * decimalFactor
				decimalFactor *= 0.1
			} else {
				value = value * 10 + num
			}
		}
		
		guard started else { return nil }
		self = isNegative ? -value : value
	}
	
}

#endif

