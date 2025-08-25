extension Comparable {
	mutating func clamp(to range: ClosedRange<Self>) {
		self = min(max(self, range.lowerBound), range.upperBound)
	}
	
	func clamped(to range: ClosedRange<Self>) -> Self {
		return min(max(self, range.lowerBound), range.upperBound)
	}
}


@inlinable
public func MIN<T: Comparable>(_ x: T, _ y: T) -> T {
	return y < x ? y : x
}

@inlinable
public func MAX<T: Comparable>(_ x: T, _ y: T) -> T {
	return x < y ? y : x
}
