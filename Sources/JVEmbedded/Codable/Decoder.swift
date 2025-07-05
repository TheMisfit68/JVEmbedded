// Decoder.swift
// JVEmbedded
//
// A blend of human creativity by TheMisfit68 and
// AI assistance from ChatGPT.
// Crafting the future, one line of Swift at a time.
// Copyright © 2023–2025 Jan Verrept. All rights reserved.

#if hasFeature(Embedded)

public class Decoder {
	
	internal let storage: CodableValue
	
	public init(storage: CodableValue) {
		self.storage = storage
	}
	
	private func lookupValue(for keyPath: String) throws(DecodingError) -> CodableValue {
		let keys = keyPath.split(separator: ".").map(String.init)
		guard let leafKey = keys.last else {
			throw DecodingError.invalidKeyPath("Malformed key path")
		}
		
		guard case .dictionary(let rootDict) = storage else {
			throw DecodingError.invalidFormat("Top-level value is not a dictionary")
		}
		var current = rootDict
		
		for key in keys.dropLast() {
			guard let nextValue = current[key],
				  case .dictionary(let nextDict) = nextValue else {
				throw DecodingError.missingKey("Key path component '\(key)' not found")
			}
			current = nextDict
		}
		
		guard let leafValue = current[leafKey] else {
			throw DecodingError.missingKey("Leaf key '\(leafKey)' not found")
		}
		
		return leafValue
	}
	
	// MARK: - Generic Type Decoding
	
	final func decode(atKeyPath keyPath: String) throws(DecodingError) -> String {
		let value = try lookupValue(for: keyPath)
		guard case .string(let result) = value else {
			throw DecodingError.typeMismatch(expected: "String", found: "\(value)")
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
	
	final func decode(atKeyPath keyPath: String) throws(DecodingError) -> Double {
		let value = try lookupValue(for: keyPath)
		guard case .double(let result) = value else {
			throw DecodingError.typeMismatch(expected: "Double", found: "\(value)")
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
	
	// MARK: - Integer and Unsigned Decoding
	
	final func decode(atKeyPath keyPath: String) throws(DecodingError) -> Int8  { Int8(try decode(atKeyPath: keyPath)) }
	final func decode(atKeyPath keyPath: String) throws(DecodingError) -> Int16 { Int16(try decode(atKeyPath: keyPath)) }
	final func decode(atKeyPath keyPath: String) throws(DecodingError) -> Int32 { Int32(try decode(atKeyPath: keyPath)) }
	final func decode(atKeyPath keyPath: String) throws(DecodingError) -> Int64 { Int64(try decode(atKeyPath: keyPath)) }
	
	final func decode(atKeyPath keyPath: String) throws(DecodingError) -> UInt8  { UInt8(try decode(atKeyPath: keyPath)) }
	final func decode(atKeyPath keyPath: String) throws(DecodingError) -> UInt16 { UInt16(try decode(atKeyPath: keyPath)) }
	final func decode(atKeyPath keyPath: String) throws(DecodingError) -> UInt32 { UInt32(try decode(atKeyPath: keyPath)) }
	final func decode(atKeyPath keyPath: String) throws(DecodingError) -> UInt64 { UInt64(try decode(atKeyPath: keyPath)) }
	
	// MARK: - Shortcut for single keys
	
	final func decode(forKey key: String) throws(DecodingError) -> String  { try decode(atKeyPath: key) }
	final func decode(forKey key: String) throws(DecodingError) -> Bool    { try decode(atKeyPath: key) }
	final func decode(forKey key: String) throws(DecodingError) -> Double  { try decode(atKeyPath: key) }
	final func decode(forKey key: String) throws(DecodingError) -> Int     { try decode(atKeyPath: key) }
	final func decode(forKey key: String) throws(DecodingError) -> Int8    { try decode(atKeyPath: key) }
	final func decode(forKey key: String) throws(DecodingError) -> Int16   { try decode(atKeyPath: key) }
	final func decode(forKey key: String) throws(DecodingError) -> Int32   { try decode(atKeyPath: key) }
	final func decode(forKey key: String) throws(DecodingError) -> Int64   { try decode(atKeyPath: key) }
	final func decode(forKey key: String) throws(DecodingError) -> UInt8   { try decode(atKeyPath: key) }
	final func decode(forKey key: String) throws(DecodingError) -> UInt16  { try decode(atKeyPath: key) }
	final func decode(forKey key: String) throws(DecodingError) -> UInt32  { try decode(atKeyPath: key) }
	final func decode(forKey key: String) throws(DecodingError) -> UInt64  { try decode(atKeyPath: key) }
}

#endif
