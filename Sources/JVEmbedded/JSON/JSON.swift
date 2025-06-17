public final class JSONEncoder {
	
	let root: UnsafeMutablePointer<cJSON>
	
	public init() {
		self.root = cjson_create_object_shim()
	}
	
	public var jsonString: String {
		guard let cStr = cjson_print_unformatted_shim(root) else { return "{}" }
		defer { free(cStr) }
		return String(cString: cStr)
	}
	
	func encode<T>(_ value: T, forKey key: StaticString) throws(JSONError) where T: CustomStringConvertible {
		let stringValue = value.description
		guard cjson_object_set_string_shim(root, key.utf8Start, stringValue) else {
			throw JSONError.encodingFailed(key)
		}
	}
	
	func encode(_ value: Double, forKey key: StaticString) throws(JSONError) {
		// Handle negative values
		var result = ""
		var absValue = value
		
		if value < 0 {
			result.append("-")
			absValue = -value
		}
		
		// Separate integer and fractional parts
		let intPart = Int(absValue)
		let fractional = absValue - Double(intPart)
		
		// Multiply fractional part to get 2 decimal places (manual formatting)
		let fracPart = Int((fractional * 100).rounded())
		
		// Assemble the string manually (e.g., "123.45")
		result.append("\(intPart).")
		if fracPart < 10 {
			result.append("0") // ensure at least two digits
		}
		result.append("\(fracPart)")
		
		// Convert to UTF8 C string
		let utf8CString = Array(result.utf8 + [0]) // null-terminated
		
		utf8CString.withUnsafeBufferPointer { buffer in
			buffer.baseAddress?.withMemoryRebound(to: CChar.self, capacity: buffer.count) { cStr in
				cjson_object_set_string_shim(root, key.utf8Start, cStr)
			}
		}
	}
	
}

public final class JSONDecoder {
	let root: UnsafeMutablePointer<cJSON>
	
	public init?(from json: String) {
		guard let root = json.withCString(cjson_parse_shim) else { return nil }
		self.root = root
	}
	
	deinit {
		cjson_delete_shim(root)
	}
	
	func decode<T: JSONDecodable>(_ key: StaticString) -> T? {
		guard let rawCString = cjson_object_get_string_shim(root, key.utf8Start),
			  let json = String(validatingUTF8: rawCString),
			  let decoder = JSONDecoder(from: json) else {
			return nil
		}
		return T(from: decoder)
	}
	
	func decode(_ key: StaticString) -> String? {
		guard let cStr = cjson_object_get_string_shim(root, key.utf8Start) else { return nil }
		return String(cString: cStr)
	}
	
	func decode(_ key: StaticString) -> UInt64? {
		guard let str = cjson_object_get_string_shim(root, key.utf8Start) else { return nil }
		return UInt64(String(cString: str))
	}
	
	func decode(_ key: StaticString) -> UInt32? {
		guard let str = cjson_object_get_string_shim(root, key.utf8Start) else { return nil }
		return UInt32(String(cString: str))
	}
	
	func decode(_ key: StaticString) -> UInt16? {
		guard let str = cjson_object_get_string_shim(root, key.utf8Start) else { return nil }
		return UInt16(String(cString: str))
	}
	
	func decode(_ key: StaticString) -> Int? {
		guard let str = cjson_object_get_string_shim(root, key.utf8Start) else { return nil }
		return Int(String(cString: str))
	}
	
	func decode(_ key: StaticString) -> Double? {
		guard let cStr = cjson_object_get_string_shim(root, key.utf8Start) else {
			return nil
		}
		
		// Calculate length of C string (null-terminated)
		var length = 0
		while cStr[length] != 0 {
			length += 1
		}
		
		// Cast pointer to UInt8 for decoding
		let bytePtr = UnsafeRawPointer(cStr).assumingMemoryBound(to: UInt8.self)
		let buffer = UnsafeBufferPointer(start: bytePtr, count: length)
		let str = String(decoding: buffer, as: UTF8.self)
		
		// Manual Double parsing (no Foundation, no Double(str))
		var isNegative = false
		var integerPart: Double = 0
		var fractionPart: Double = 0
		var fractionDivisor: Double = 1
		var pastDecimal = false
		
		for char in str {
			if char == "-" && integerPart == 0 && !pastDecimal {
				isNegative = true
			} else if char == "." {
				pastDecimal = true
			} else if let digit = char.wholeNumberValue {
				if pastDecimal {
					fractionDivisor *= 10
					fractionPart += Double(digit) / fractionDivisor
				} else {
					integerPart = integerPart * 10 + Double(digit)
				}
			} else {
				return nil // invalid character
			}
		}
		
		let result = integerPart + fractionPart
		return isNegative ? -result : result
	}
	
	// For enums with rawValue: String
	func decodeEnum<T>(_ key: StaticString) -> T? where T: RawRepresentable, T.RawValue == String {
		guard let raw = cjson_object_get_string_shim(root, key.utf8Start) else { return nil }
		return T(rawValue: String(cString: raw))
	}
	
	// For enums with rawValue: UInt32
	func decodeEnum<T>(_ key: StaticString) -> T? where T: RawRepresentable, T.RawValue == UInt32 {
		guard let raw = cjson_object_get_string_shim(root, key.utf8Start) else { return nil }
		guard let number = UInt32(String(cString: raw)) else { return nil }
		return T(rawValue: number)
	}
	
	// For enums that conform to RawRepresentable manually,
	// like enums with associated values or complex types
	func decode<T: RawRepresentable>(_ key: StaticString) -> T? where T.RawValue: JSONDecodable {
		guard let rawValue: T.RawValue = decode(key) else { return nil }
		return T(rawValue: rawValue)
	}
	
}



