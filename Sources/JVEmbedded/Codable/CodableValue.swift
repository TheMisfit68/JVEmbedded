// CodableValue.swift
// JVEmbedded
//
// A blend of human creativity by TheMisfit68 and
// AI assistance from ChatGPT.
// Crafting the future, one line of Swift at a time.
// Copyright © 2023 Jan Verrept. All rights reserved.

#if hasFeature(Embedded)

public typealias CodableDict = JVEmbedded.Dictionary<String, CodableValue>

public enum CodableValue {
	case int(Int)
	case double(Double)
	case bool(Bool)
	case string(String)
	case dictionary(CodableDict)
	case array([CodableValue])
	case null
	
	/// Merge another CodableValue into this one, recursively.
	/// Used by Encoder.encode(value:at:) to build nested keypaths like "a.b.c"
	public mutating func merge(with other: CodableValue) throws(EncodingError) {
		guard case .dictionary(let otherDict) = other else {
			throw EncodingError.typeMismatch(expected: "dictionary", found: "\(other)")
		}
		guard case .dictionary(var currentDict) = self else {
			self = other
			return
		}
		
		var mergedDict = CodableDict()
		
		for pair in currentDict {
			if let otherValue = otherDict.value(forKey: pair.key) {
				var newValue = pair.value
				try newValue.merge(with: otherValue)
				mergedDict.setValue(newValue, forKey: pair.key)
			} else {
				mergedDict.setValue(pair.value, forKey: pair.key)
			}
		}
		
		// Add new keys not already in currentDict
		for otherPair in otherDict {
			if currentDict.value(forKey: otherPair.key) == nil {
				mergedDict.setValue(otherPair.value, forKey: otherPair.key)
			}
		}
		
		self = .dictionary(mergedDict)
	}
	
}

#endif
