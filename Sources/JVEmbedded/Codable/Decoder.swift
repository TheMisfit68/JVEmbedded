// Decoder.swift
// JVEmbedded
//
// A blend of human creativity by TheMisfit68 and
// AI assistance from ChatGPT.
// Crafting the future, one line of Swift at a time.
// Copyright © 2023–2025 Jan Verrept. All rights reserved.

#if hasFeature(Embedded)

public class Decoder {
	
	internal let storage: [String: CodableValue]
	
	public init(storage: [String: CodableValue]) {
		self.storage = storage
	}
	
	private func lookupValue(for keyPath: String) throws(DecodingError) -> CodableValue {
		let keys = keyPath.split(separator: ".").map(String.init)
		guard let leafKey = keys.last else {
			throw DecodingError.invalidKeyPath("Malformed key path")
		}
		
		var current: CodableValue = .object(storage)
		for key in keys.dropLast() {
			guard case .object(let dict) = current,
				  let next = dict[key] else {
				throw DecodingError.missingKey("Key path component '\(key)' not found")
			}
			current = next
		}
		
		guard case .object(let leafDict) = current, let leafValue = leafDict[leafKey] else {
			throw DecodingError.missingKey("Leaf key '\(leafKey)' not found")
		}
		
		return leafValue
	}
	
	final func decode(atKeyPath keyPath: String) throws(DecodingError) -> String {
		let value = try lookupValue(for: keyPath)
		guard case .string(let result) = value else {
			throw DecodingError.typeMismatch(expected: "String", found: "\(value)")
		}
		return result
	}
	
	final func decode(atKeyPath keyPath: String) throws(DecodingError) -> Int {
		let value = try lookupValue(for: keyPath)
		guard case .int(let result) = value else {
			throw DecodingError.typeMismatch(expected: "Int", found: "\(value)")
		}
		return result
	}
	
	final func decode(atKeyPath keyPath: String) throws(DecodingError) -> Int8 {
		let value = try lookupValue(for: keyPath)
		guard case .int(let result) = value else {
			throw DecodingError.typeMismatch(expected: "Int", found: "\(value)")
		}
		return Int8(result)
	}
	
	final func decode(atKeyPath keyPath: String) throws(DecodingError) -> Int16 {
		let value = try lookupValue(for: keyPath)
		guard case .int(let result) = value else {
			throw DecodingError.typeMismatch(expected: "Int", found: "\(value)")
		}
		return Int16(result)
	}
	
	final func decode(atKeyPath keyPath: String) throws(DecodingError) -> Int32 {
		let value = try lookupValue(for: keyPath)
		guard case .int(let result) = value else {
			throw DecodingError.typeMismatch(expected: "Int", found: "\(value)")
		}
		return Int32(result)
	}
	
	final func decode(atKeyPath keyPath: String) throws(DecodingError) -> Int64 {
		let value = try lookupValue(for: keyPath)
		guard case .int(let result) = value else {
			throw DecodingError.typeMismatch(expected: "Int", found: "\(value)")
		}
		return Int64(result)
	}
	
	final func decode(atKeyPath keyPath: String) throws(DecodingError) -> UInt8 {
		let value = try lookupValue(for: keyPath)
		guard case .int(let result) = value else {
			throw DecodingError.typeMismatch(expected: "Int", found: "\(value)")
		}
		return UInt8(result)
	}
	
	final func decode(atKeyPath keyPath: String) throws(DecodingError) -> UInt16 {
		let value = try lookupValue(for: keyPath)
		guard case .int(let result) = value else {
			throw DecodingError.typeMismatch(expected: "Int", found: "\(value)")
		}
		return UInt16(result)
	}
	
	final func decode(atKeyPath keyPath: String) throws(DecodingError) -> UInt32 {
		let value = try lookupValue(for: keyPath)
		guard case .int(let result) = value else {
			throw DecodingError.typeMismatch(expected: "Int", found: "\(value)")
		}
		return UInt32(result)
	}
	
	final func decode(atKeyPath keyPath: String) throws(DecodingError) -> UInt64 {
		let value = try lookupValue(for: keyPath)
		guard case .int(let result) = value else {
			throw DecodingError.typeMismatch(expected: "Int", found: "\(value)")
		}
		return UInt64(result)
	}
	
	final func decode(atKeyPath keyPath: String) throws(DecodingError) -> Double {
		let value = try lookupValue(for: keyPath)
		guard case .double(let result) = value else {
			throw DecodingError.typeMismatch(expected: "Double", found: "\(value)")
		}
		return result
	}
	
	final func decode(atKeyPath keyPath: String) throws(DecodingError) -> Bool {
		let value = try lookupValue(for: keyPath)
		guard case .bool(let result) = value else {
			throw DecodingError.typeMismatch(expected: "Bool", found: "\(value)")
		}
		return result
	}
	
	// Decode value at a single key
	final func decode(forKey key: String) throws(DecodingError) -> String {
		return try decode(atKeyPath: key)
	}
	
	final func decode(forKey key: String) throws(DecodingError) -> Int {
		return try decode(atKeyPath: key)
	}
	
	final func decode(forKey key: String) throws(DecodingError) -> Double {
		return try decode(atKeyPath: key)
	}
	
	final func decode(forKey key: String) throws(DecodingError) -> Int8 {
		return try decode(atKeyPath: key)
	}
	
	final func decode(forKey key: String) throws(DecodingError) -> Int16 {
		return try decode(atKeyPath: key)
	}
	
	final func decode(forKey key: String) throws(DecodingError) -> Int32 {
		return try decode(atKeyPath: key)
	}
	
	final func decode(forKey key: String) throws(DecodingError) -> Int64 {
		return try decode(atKeyPath: key)
	}
	
	final func decode(forKey key: String) throws(DecodingError) -> UInt8 {
		return try decode(atKeyPath: key)
	}
	
	final func decode(forKey key: String) throws(DecodingError) -> UInt16 {
		return try decode(atKeyPath: key)
	}
	
	final func decode(forKey key: String) throws(DecodingError) -> UInt32 {
		return try decode(atKeyPath: key)
	}
	
	final func decode(forKey key: String) throws(DecodingError) -> UInt64 {
		return try decode(atKeyPath: key)
	}
	
	final func decode(forKey key: String) throws(DecodingError) -> Bool {
		return try decode(atKeyPath: key)
	}
	
}

#endif
