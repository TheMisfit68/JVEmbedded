extension UInt8 {
	
	// Convert a single nibble (4 bits) to a hexadecimal character
	func hexChar() -> Character {
		if self < 10 {
			// Return the corresponding digit character (0-9)
			return Character(UnicodeScalar(self + 48)) // Valid characters for digits 0-9
		} else if self >= 10 && self <= 15 {
			// Return the corresponding letter character (a-f)
			return Character(UnicodeScalar(self + 87)) // Valid characters for a-f
		} else {
			// Invalid input, return a default character (or handle error case)
			return "?" // or some other fallback
		}
	}
	
}

#if hasFeature(Embedded)

extension Int: LosslessStringConvertible {
	public init?(_ description: String) {
		self.init(description, radix: 10)
	}
	
	public var description: String {
		String(self)
	}
}

extension Int8: LosslessStringConvertible {
	public init?(_ description: String) {
		self.init(description, radix: 10)
	}
	
	public var description: String {
		String(self)
	}
}

extension Int16: LosslessStringConvertible {
	public init?(_ description: String) {
		self.init(description, radix: 10)
	}
	
	public var description: String {
		String(self)
	}
}

extension Int32: LosslessStringConvertible {
	public init?(_ description: String) {
		self.init(description, radix: 10)
	}
	
	public var description: String {
		String(self)
	}
}

extension Int64: LosslessStringConvertible {
	public init?(_ description: String) {
		self.init(description, radix: 10)
	}
	
	public var description: String {
		String(self)
	}
}

extension UInt: LosslessStringConvertible {
	public init?(_ description: String) {
		self.init(description, radix: 10)
	}
	
	public var description: String {
		String(self)
	}
}

extension UInt8: LosslessStringConvertible {
	public init?(_ description: String) {
		self.init(description, radix: 10)
	}
	
	public var description: String {
		String(self)
	}
}

extension UInt16: LosslessStringConvertible {
	public init?(_ description: String) {
		self.init(description, radix: 10)
	}
	
	public var description: String {
		String(self)
	}
}

extension UInt32: LosslessStringConvertible {
	public init?(_ description: String) {
		self.init(description, radix: 10)
	}
	
	public var description: String {
		String(self)
	}
}

extension UInt64: LosslessStringConvertible {
	public init?(_ description: String) {
		self.init(description, radix: 10)
	}
	
	public var description: String {
		String(self)
	}
}

#endif
