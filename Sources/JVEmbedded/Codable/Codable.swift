// Codable.swift
// JVEmbedded
//
// A blend of human creativity by TheMisfit68 and
// AI assistance from ChatGPT.
// Crafting the future, one line of Swift at a time.
// Copyright © 2023–2025 Jan Verrept. All rights reserved.

#if hasFeature(Embedded) // Embedded platforms like ESP32.

// MARK: -  Encodable/Decodable/Codable
/// Encodable protocol for Embedded Swift
public protocol Encodable {
	func encode(to encoder: Encoder) throws(EncodingError)
}

/// Decodable protocol for Embedded Swift
public protocol Decodable {
	init(from decoder: Decoder) throws(DecodingError)
}

/// Composed Codable protocol for Embedded Swift
public typealias Codable = Encodable & Decodable

// MARK: - Default Encodable
// For enums with rawValue == String
public extension Encodable where Self: RawRepresentable, RawValue == String {
	
	func encode(to encoder: Encoder) throws(EncodingError) {
		try encoder.encode(rawValue, forKey: "rawValue")
	}
}

// For enums with rawValue ≠ String but that provide their own description
public extension Encodable where Self: RawRepresentable & CustomStringConvertible, RawValue: LosslessStringConvertible {
	
	func encode(to encoder: Encoder) throws(EncodingError) {
		
		try encoder.encode(rawValue, forKey: "rawValue")
		
		// Only add description if it's actually different from rawValue
		if description != String(rawValue) {
			try encoder.encode(description, forKey: "description")
		}
	}
}

// MARK: - Default Decodable
// For RawRepresentable Enums with specific rawValue types
public extension Decodable where Self: RawRepresentable, RawValue == String {
	
	init(from decoder: Decoder) throws(DecodingError) {
		let raw: RawValue = try decoder.decode(forKey: "rawValue")
		guard let enumValue = Self(rawValue: raw) else {
			throw DecodingError.invalidEnumValue("Invalid value: \(raw)")
		}
		self = enumValue
	}
}

public extension Decodable where Self: RawRepresentable, RawValue == Int {
	
	init(from decoder: Decoder) throws(DecodingError) {
		let raw: RawValue = try decoder.decode(forKey: "rawValue")
		guard let enumValue = Self(rawValue: raw) else {
			throw DecodingError.invalidEnumValue("Invalid value: \(raw)")
		}
		self = enumValue
	}
}

public extension Decodable where Self: RawRepresentable, RawValue == Int8 {
	init(from decoder: Decoder) throws(DecodingError) {
		let raw = try decoder.decode(forKey: "rawValue") as Int
		guard let value = RawValue(exactly: raw),
			  let enumValue = Self(rawValue: value) else {
			throw DecodingError.invalidEnumValue("Invalid Int8 value: \(raw)")
		}
		self = enumValue
	}
}

public extension Decodable where Self: RawRepresentable, RawValue == Int16 {
	init(from decoder: Decoder) throws(DecodingError) {
		let raw = try decoder.decode(forKey: "rawValue") as Int
		guard let value = RawValue(exactly: raw),
			  let enumValue = Self(rawValue: value) else {
			throw DecodingError.invalidEnumValue("Invalid Int16 value: \(raw)")
		}
		self = enumValue
	}
}

public extension Decodable where Self: RawRepresentable, RawValue == Int32 {
	init(from decoder: Decoder) throws(DecodingError) {
		let raw = try decoder.decode(forKey: "rawValue") as Int
		guard let value = RawValue(exactly: raw),
			  let enumValue = Self(rawValue: value) else {
			throw DecodingError.invalidEnumValue("Invalid Int32 value: \(raw)")
		}
		self = enumValue
	}
}

public extension Decodable where Self: RawRepresentable, RawValue == UInt8 {
	init(from decoder: Decoder) throws(DecodingError) {
		let raw = try decoder.decode(forKey: "rawValue") as Int
		guard let value = RawValue(exactly: raw),
			  let enumValue = Self(rawValue: value) else {
			throw DecodingError.invalidEnumValue("Invalid UInt8 value: \(raw)")
		}
		self = enumValue
	}
}

public extension Decodable where Self: RawRepresentable, RawValue == UInt16 {
	init(from decoder: Decoder) throws(DecodingError) {
		let raw = try decoder.decode(forKey: "rawValue") as Int
		guard let value = RawValue(exactly: raw),
			  let enumValue = Self(rawValue: value) else {
			throw DecodingError.invalidEnumValue("Invalid UInt16 value: \(raw)")
		}
		self = enumValue
	}
}

public extension Decodable where Self: RawRepresentable, RawValue == UInt32 {
	init(from decoder: Decoder) throws(DecodingError) {
		let raw = try decoder.decode(forKey: "rawValue") as Int
		guard let value = RawValue(exactly: raw),
			  let enumValue = Self(rawValue: value) else {
			throw DecodingError.invalidEnumValue("Invalid UInt32 value: \(raw)")
		}
		self = enumValue
	}
}

public extension Decodable where Self: RawRepresentable, RawValue == UInt64 {
	init(from decoder: Decoder) throws(DecodingError) {
		let raw = try decoder.decode(forKey: "rawValue") as Int
		guard let value = RawValue(exactly: raw),
			  let enumValue = Self(rawValue: value) else {
			throw DecodingError.invalidEnumValue("Invalid UInt64 value: \(raw)")
		}
		self = enumValue
	}
}

public extension Decodable where Self: RawRepresentable, RawValue == Double {
	
	init(from decoder: Decoder) throws(DecodingError) {
		let raw: RawValue = try decoder.decode(forKey: "rawValue")
		guard let enumValue = Self(rawValue: raw) else {
			throw DecodingError.invalidEnumValue("Invalid value: \(raw)")
		}
		self = enumValue
	}
}






//
// 3️⃣ Fallback for RawRepresentable enums (including Int, UInt, etc.)
public extension Encodable where Self: RawRepresentable {

	func encode(to encoder: Encoder) throws(EncodingError) {
		try encoder.encode(rawValue, forKey: "rawValue")
	}
}
//
//public extension Decodable where Self: RawRepresentable, RawValue: LosslessStringConvertible {
//
//	init(from decoder: Decoder) throws(DecodingError) {
//		let raw:RawValue = try decoder.decode(forKey: "rawValue")
//		guard let enumValue = Self(rawValue: raw) else {
//			throw DecodingError.invalidEnumValue("Invalid value: \(raw)")
//		}
//		self = enumValue
//	}
//}

#endif
