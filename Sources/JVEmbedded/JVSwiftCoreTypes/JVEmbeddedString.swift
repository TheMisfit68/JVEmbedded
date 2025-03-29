
extension Swift.String {
	
	var count: Int {
		self.utf8.count
	}
	var maxIndex:Int {
		self.count-1
	}
	
	/// Pads the string with a given character to a specified length
	public mutating func padLeft(to length: Int, with character: Character = "0"){
		
		while self.count < length {
			self = "\(character)\(self)"
		}
		
	}
	
	// Non mutating version of the previous method
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
	
	
}
