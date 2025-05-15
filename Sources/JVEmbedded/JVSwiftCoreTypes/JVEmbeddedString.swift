extension Swift.String {
	
	/// Alias to make the intent clear when bridging to C
	public typealias CString = UnsafePointer<CChar>
	
	var count: Int {
		self.utf8.count
	}
	
	var maxIndex: Int {
		self.count - 1
	}
	
	/// Pads the string with a given character to a specified length
	public mutating func padLeft(to length: Int, with character: Character = "0") {
		while self.count < length {
			self = "\(character)\(self)"
		}
	}
	
	/// Non mutating version of the previous method
	public func paddedLeft(to length: Int, with character: Character = "0") -> String {
		var paddedString = self
		paddedString.padLeft(to: length, with: character)
		return paddedString
	}
	
	/// Iterates over the UTF-8 bytes of the string and executes a closure for each byte
	func iterateUTF8Bytes(_ process: (UInt8, Int) -> Void) {
		var index = 0
		for byte in self.utf8 {
			process(byte, index)
			index += 1
		}
	}
	
	public func replacingOccurrences(of target: String, with replacement: String) -> String {
		let sourceBytes = Array(self.utf8)
		let targetBytes = Array(target.utf8)
		let replacementBytes = Array(replacement.utf8)
		
		guard !targetBytes.isEmpty else { return self }
		
		var resultBytes: [UInt8] = []
		var i = 0
		
		while i < sourceBytes.count {
			var match = true
			if i + targetBytes.count <= sourceBytes.count {
				for j in 0..<targetBytes.count {
					if sourceBytes[i + j] != targetBytes[j] {
						match = false
						break
					}
				}
			} else {
				match = false
			}
			
			if match {
				resultBytes.append(contentsOf: replacementBytes)
				i += targetBytes.count
			} else {
				resultBytes.append(sourceBytes[i])
				i += 1
			}
		}
		
		return String(decoding: resultBytes, as: UTF8.self)
	}
	
}
