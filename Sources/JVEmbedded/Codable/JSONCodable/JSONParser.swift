// JSONParser.swift
//
// A blend of human creativity by TheMisfit68  and
// AI assistance from ChatGPT.
// Crafting the future, one line of Swift at a time.
// Copyright © 2023 Jan Verrept. All rights reserved.

#if hasFeature(Embedded)

/// Simple recursive descent JSON parser for Embedded Swift
/// Produces a CodableValue representation of the JSON input
public struct JSONParser {
	
	enum Token {
		case leftBrace       // {
		case rightBrace      // }
		case leftBracket     // [
		case rightBracket    // ]
		case colon           // :
		case comma           // ,
		case string(String)
		case number(Double)
		case bool(Bool)
		case null
		case eof
	}
	
	let input: String
	var index: String.Index
	
	public init(_ input: String) {
		self.input = input
		self.index = input.startIndex
	}
	
	mutating func parse() throws(DecodingError) -> CodableValue {
		let value = try parseValue()
		skipWhitespace()
		if !isAtEnd() {
			throw DecodingError.invalidFormat("Unexpected trailing characters")
		}
		print("🟢 Finished parsing JSON")
		return value
	}
	
	mutating func parseValue() throws(DecodingError) -> CodableValue {
		print("🟢 Parsing value")
		skipWhitespace()
		guard !isAtEnd() else {
			throw DecodingError.invalidFormat("Unexpected end of input")
		}
		let c = peek()
		switch c {
			case "{":
				return try parseDictionary()
			case "[":
				return try parseArray()
			case "\"":
				return .string(try parseString())
			case "t", "f":
				return .bool(try parseBool())
			case "n":
				try parseNull()
				return .null
			case "-", "0"..."9":
				return .double(try parseNumber())
			default:
				throw DecodingError.invalidFormat("Unexpected character: \(c)")
		}
	}
	
	mutating func parseDictionary() throws(DecodingError) -> CodableValue {
		print("🟢 Parsing dictionary")
		try consume("{")
		skipWhitespace()
		var dict = CodableDict()
		if peek() == "}" {
			try consume("}")
			return .dictionary(dict)
		}
		while true {
			skipWhitespace()
			let key = try parseString()
			print("🔑 Parsed dictionary key: \(key)")
			
			skipWhitespace()
			try consume(":")
			skipWhitespace()
			
			let value = try parseValue()
			print("🚨 Assigning value to dictionary: key=\(key)")
			dict.setValue(value, forKey: key)
			print("✅ Assigned key '\(key)' in dictionary")
			
			skipWhitespace()
			if peek() == "}" {
				try consume("}")
				break
			}
			try consume(",")
		}
		
		return .dictionary(dict)
	}
	
	mutating func parseArray() throws(DecodingError) -> CodableValue {
		print("🟢 Parsing array")
		try consume("[")
		skipWhitespace()
		var array = [CodableValue]()
		if peek() == "]" {
			try consume("]")
			return .array(array)
		}
		while true {
			let value = try parseValue()
			array.append(value)
			skipWhitespace()
			if peek() == "]" {
				try consume("]")
				break
			}
			try consume(",")
			skipWhitespace()
		}
		return .array(array)
	}
	
	mutating func parseString() throws(DecodingError) -> String {
		print("🟢 Parsing string")
		try consume("\"")
		var result = ""
		while true {
			guard !isAtEnd() else {
				throw DecodingError.invalidFormat("Unterminated string")
			}
			let c = advance()
			if c == "\"" {
				break
			}
			if c == "\\" {
				guard !isAtEnd() else {
					throw DecodingError.invalidFormat("Unterminated escape sequence")
				}
				let escape = advance()
				switch escape {
					case "\"": result.append("\"")
					case "\\": result.append("\\")
					case "/": result.append("/")
					case "b": result.append("\u{08}")
					case "f": result.append("\u{0C}")
					case "n": result.append("\n")
					case "r": result.append("\r")
					case "t": result.append("\t")
					case "u":
						let hex = try parseUnicodeEscape()
						result.append(hex)
					default:
						throw DecodingError.invalidFormat("Invalid escape sequence: \\(escape)")
				}
			} else {
				result.append(c)
			}
		}
		return result
	}
	
	mutating func parseUnicodeEscape() throws(DecodingError) -> Character {
		func hexDigit(_ c: Character) throws(DecodingError) -> UInt32 {
			guard let ascii = c.asciiValue else {
				throw DecodingError.invalidFormat("Invalid unicode escape digit: \(c)")
			}
			switch ascii {
				case 48...57:  return UInt32(ascii - 48)
				case 97...102: return UInt32(ascii - 97 + 10)
				case 65...70:  return UInt32(ascii - 65 + 10)
				default:
					throw DecodingError.invalidFormat("Invalid unicode escape digit: \(c)")
			}
		}
		var value: UInt32 = 0
		for _ in 0..<4 {
			guard !isAtEnd() else {
				throw DecodingError.invalidFormat("Incomplete unicode escape")
			}
			value <<= 4
			value += try hexDigit(advance())
		}
		guard let scalar = UnicodeScalar(value) else {
			throw DecodingError.invalidFormat("Invalid unicode scalar: \(value)")
		}
		return Character(scalar)
	}
	
	mutating func parseBool() throws(DecodingError) -> Bool {
		print("🟢 Parsing boolean")
		if try consumeIf("true") {
			return true
		} else if try consumeIf("false") {
			return false
		}
		throw DecodingError.invalidFormat("Invalid boolean value")
	}
	
	mutating func parseNull() throws(DecodingError) {
		print("🟢 Parsing null")
		if !(try consumeIf("null")) {
			throw DecodingError.invalidFormat("Invalid null value")
		}
	}
	
	mutating func parseNumber() throws(DecodingError) -> Double {
		print("🟢 Parsing number")
		var numberString = ""
		if peek() == "-" {
			numberString.append(advance())
		}
		while !isAtEnd() && isDigit(peek()) {
			numberString.append(advance())
		}
		if !isAtEnd() && peek() == "." {
			numberString.append(advance())
			while !isAtEnd() && isDigit(peek()) {
				numberString.append(advance())
			}
		}
		if !isAtEnd() && (peek() == "e" || peek() == "E") {
			numberString.append(advance())
			if !isAtEnd() && (peek() == "+" || peek() == "-") {
				numberString.append(advance())
			}
			while !isAtEnd() && isDigit(peek()) {
				numberString.append(advance())
			}
		}
		
		print("🐞🐞 Number string \(numberString)")
		guard let number = Double(embeddedString: numberString) else {
			print("❌ Failed to convert number string to Double")
			throw DecodingError.invalidFormat("Invalid number format: \(numberString)")
		}
		let test = number.description
		print("🐞🐞 Converted number \(test)")
		return number
	}
	
	// MARK: - Helpers
	
	func isAtEnd() -> Bool {
		return index >= input.endIndex
	}
	
	func peek() -> Character {
		guard !isAtEnd() else { return "\0" }
		return input[index]
	}
	
	@discardableResult
	mutating func advance() -> Character {
		let c = input[index]
		index = input.index(after: index)
		return c
	}
	
	// Custom ASCII whitespace check (no Foundation)
	func isWhitespace(_ c: Character) -> Bool {
		// Only ASCII whitespace: space, tab, line feed, carriage return
		return c == " " || c == "\t" || c == "\n" || c == "\r"
	}
	
	func isDigit(_ c: Character) -> Bool {
		guard let ascii = c.asciiValue else { return false }
		return ascii >= 48 && ascii <= 57
	}
	
	mutating func skipWhitespace() {
		while !isAtEnd() && isWhitespace(peek()) {
			_ = advance()
		}
	}
	
	mutating func consume(_ expected: Character) throws(DecodingError) {
		guard !isAtEnd() && advance() == expected else {
			throw DecodingError.invalidFormat("Expected character: \(expected)")
		}
	}
	
	mutating func consumeIf(_ expected: String) throws(DecodingError) -> Bool {
		let startIndex = index
		for c in expected {
			if isAtEnd() || advance() != c {
				index = startIndex
				return false
			}
		}
		return true
	}
	
}

#endif // hasFeature(Embedded)
