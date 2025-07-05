// Encoder.swift
// JVEmbedded
//
// A blend of human creativity by TheMisfit68 and
// AI assistance from ChatGPT.
// Crafting the future, one line of Swift at a time.
// Copyright © 2023 Jan Verrept. All rights reserved.

#if hasFeature(Embedded)

public class Encoder {
	
	internal var storage: CodableValue = .dictionary(CodableDict())
	
	public init() {}
	
	final func encode<T: CustomStringConvertible>(_ value: T, atKeyPath keyPath: String) throws(EncodingError) {
		try encode(value.description, atKeyPath: keyPath)
	}
	
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
			case let v as CodableDict: codableValue = .dictionary(v)
			default:
				throw EncodingError.unsupportedType("Unsupported type: \(T.self)")
		}
		
		let keys = keyPath.split(separator: ".").map(String.init)
		
		var nestedValue = codableValue
		for key in keys.reversed() {
			var wrapper = CodableDict()
			wrapper.setValue(nestedValue, forKey: key)
			nestedValue = .dictionary(wrapper)
		}
		
		try storage.merge(with: nestedValue)
	}
	
	final func encode<T>(_ value: T, forKey key: String) throws(EncodingError) {
		try encode(value, atKeyPath: key)
	}
}

#endif
