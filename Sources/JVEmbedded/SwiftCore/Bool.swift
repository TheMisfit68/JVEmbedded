//
//  JVEmbeddedBool.swift
//  JVEmbedded
//
//  Created by Jan Verrept on 01/12/2024.
//


// Extend the Bool type to add the logical XOR operator
infix operator ^^: LogicalDisjunctionPrecedence

extension Swift.Bool {
	static func ^^(lhs: Bool, rhs: Bool) -> Bool {
		return lhs != rhs  // XOR logic: true if different, false if same
	}
	
}

#if hasFeature(Embedded)

extension Swift.Bool:LosslessStringConvertible{
	
	public init?(_ stringValue: String) {
		
		switch stringValue.lowercased() {
			case "true", "1":
				self = true
			case "false", "0":
				self = false
			default:
				return nil  // Invalid string representation
		}
	}
	
	public var description: String {
		return self ? "true" : "false"
	}
	
}

#endif


