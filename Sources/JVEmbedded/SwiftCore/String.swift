#if hasFeature(Embedded)


// MARK: - Embedded Swift Compatibility
extension Swift.String {
	
	init(_ value: Double, precision: Int = 3) {
		var result = ""
		var number = value
		if number.isNaN {
			self = "nan"
			return
		}
		if number.isInfinite {
			self = number > 0 ? "inf" : "-inf"
			return
		}
		if number < 0 {
			result.append("-")
			number = -number
		}
		
		let integerPart = Int(number)
		result.append(String(integerPart))
		result.append(".")
		
		var fractional = number - Double(integerPart)
		for _ in 0..<precision {
			fractional *= 10
			let digit = Int(fractional)
			result.append(String(digit))
			fractional -= Double(digit)
		}
		
		self = result
	}
	
	func trimmingCharacters(_ characters: String) -> String {
		let scalars = self.unicodeScalars
		let trimScalars = characters.unicodeScalars
		
		var start = scalars.startIndex
		var end = scalars.index(before: scalars.endIndex)
		
		while start <= end, trimScalars.contains(scalars[start]) {
			start = scalars.index(after: start)
		}
		
		while end >= start, trimScalars.contains(scalars[end]) {
			end = scalars.index(before: end)
		}
		
		return String(scalars[start...end])
	}
	
}

#endif
