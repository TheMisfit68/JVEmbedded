
extension Swift.String {
	
	var count: Int {
		self.utf8.count
	}
	
	/// Pads the string with a given character to a specified length
	public mutating func padLeft(to length: Int, with character: Character = "0"){
		
		while self.count < length {
			self = "\(character)\(self)"
		}
		
	}
	
}
