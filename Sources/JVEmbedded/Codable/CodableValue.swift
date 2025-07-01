//
//  CodableValue.swift
//  JVEmbedded
//
//  Created by Jan Verrept on 22/06/2025.
//


// Generic type used to store values for all encoders/decoders
public enum CodableValue {
	
	case string(String)
	case int(Int)
	case double(Double)
	case bool(Bool)
	case array([CodableValue])
	case object([String: CodableValue])
	case null
	
	// Needed to build nested structures of codable values
	// Used by Encoder.encode(value:at:)
	mutating func merge(with other: CodableValue) throws(EncodingError) {
		guard case .object(let otherDict) = other else {
			throw EncodingError.typeMismatch(expected: "object", found: "\(other)")
		}
		guard case .object(var currentDict) = self else {
			self = other // overschrijft eenvoudige waarde
			return
		}
		
		for (key, otherValue) in otherDict {
			if var existingValue = currentDict[key] {
				try existingValue.merge(with: otherValue)
				currentDict[key] = existingValue
			} else {
				currentDict[key] = otherValue
			}
		}
		self = .object(currentDict)
	}
	
	var jsonDescription: String {
		switch self {
			case .string(let s): return "\"\(s)\""
			case .int(let i): return String(i)
			case .double(let d): return String(d, precision: 3)
			case .bool(let b): return b ? "true" : "false"
			case .array(let a):
				let elements = a.map { $0.jsonDescription }.joined(separator: ", ")
				return "[\(elements)]"
			case .object(let o):
				let parts = o.map { key, value in
					"\"\(key)\": \(value.jsonDescription)"
				}.joined(separator: ", ")
				return "{\(parts)}"
			case .null: return "null"
		}
	}
}

