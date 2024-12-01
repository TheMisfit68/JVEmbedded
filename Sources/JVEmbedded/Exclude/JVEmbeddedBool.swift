//
//  JVEmbeddedBool.swift
//  JVEmbedded
//
//  Created by Jan Verrept on 01/12/2024.
//


// Extend the Bool type to add the logical XOR operator
infix operator ^^: LogicalDisjunctionPrecedence

extension Bool {
	static func ^^(lhs: Bool, rhs: Bool) -> Bool {
		return lhs != rhs  // XOR logic: true if different, false if same
	}
}
