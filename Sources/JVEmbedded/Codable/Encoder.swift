//
//  EncoderDecoder.swift
//  JVEmbedded
//
//  Created by Jan Verrept on 21/06/2025.
//

// A generic Encoder superclass from which all Encoder types should inherit,
// These subclasses only add the ability to import from a specific format, like JSON, plist, XML, etc.

#if hasFeature(Embedded)

public class Encoder {
	
	internal var storage: [String: CodableValue] = [:]
	
	public init() {}
	
	final func encode<T: CustomStringConvertible>(_ value: T, atKeyPath keyPath: String) throws(EncodingError) {
		// Use the description to be encode as a string
		try encode(value.description, atKeyPath: keyPath)
	}
	
	// Encode a value at a specific key path, allowing nested structures
	final func encode<T>(_ value: T, atKeyPath keyPath: String) throws(EncodingError) {
		let codableValue: CodableValue
		switch value {
			case let v as Int:         codableValue = .int(v)
			case let v as Int8:        codableValue = .int(Int(v))
			case let v as Int16:       codableValue = .int(Int(v))
			case let v as Int32:       codableValue = .int(Int(v))
			case let v as Int64:       codableValue = .int(Int(v))
			case let v as UInt:        codableValue = .int(Int(v))
			case let v as UInt8:       codableValue = .int(Int(v))
			case let v as UInt16:      codableValue = .int(Int(v))
			case let v as UInt32:      codableValue = .int(Int(v))
			case let v as UInt64:      codableValue = .int(Int(v))
			case let v as Double:      codableValue = .double(v)
			case let v as Float:       codableValue = .double(Double(v))
			case let v as Bool:        codableValue = .bool(v)
			case let v as String:      codableValue = .string(v)
			case let v as [String: CodableValue]: codableValue = .object(v)
			default:
				throw EncodingError.unsupportedType("Unsupported type: \(T.self)")
		}
		
		// Insert or merge the value at the key path
		let keys = keyPath.split(separator: ".").map(String.init)
		guard let leafKey = keys.last else {
			throw EncodingError.invalidKeyPath("Malformed key path")
		}
		
		// Build the nested structure inside-out
		var currentParent: CodableValue = .object([leafKey: codableValue])
		for key in keys.dropLast().reversed() {
			currentParent = .object([key: currentParent])
		}
		
		// Add or merge into the actual storage
		let rootKey = keys.first!
		if var existing = storage[rootKey] {
			try existing.merge(with: currentParent)
			storage[rootKey] = existing
		} else {
			storage[rootKey] = currentParent
		}
	}
	
	// Single key encoding method
	final func encode<T>(_ value: T, forKey key: String) throws(EncodingError) {
		try encode(value, atKeyPath: key)
	}
	
}

#endif
