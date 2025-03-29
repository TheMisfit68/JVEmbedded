extension Comparable {
	mutating func clamp(to range: ClosedRange<Self>) {
		self = min(max(self, range.lowerBound), range.upperBound)
	}
	
	func clamped(to range: ClosedRange<Self>) -> Self {
		return min(max(self, range.lowerBound), range.upperBound)
	}
}
