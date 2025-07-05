// JSONEncoder.swift
//
// A blend of human creativity by TheMisfit68  and
// AI assistance from ChatGPT.
// Crafting the future, one line of Swift at a time.
// Copyright © 2023 Jan Verrept. All rights reserved.

#if hasFeature(Embedded)

public final class JSONEncoder: Encoder {
	
	/// Serializes the encoded data into a JSON string
	public func encodeToString() -> String {
		return serialize(storage)
	}
	
	private func serialize(_ value: CodableValue) -> String {
		switch value {
			case .null:
				return "null"
			case .bool(let b):
				return b ? "true" : "false"
			case .int(let i):
				return String(i)
			case .double(let d):
				return String(d) // already known to work
			case .string(let s):
				return "\"\(s)\"" // no escaping yet
			case .array(let arr):
				let items = arr.map { serialize($0) }.joined(separator: ",")
				return "[\(items)]"
			case .dictionary(let dict):
				let parts = dict.map { pair in
					"\"\(pair.key)\":\(serialize(pair.value))"
				}.joined(separator: ",")
				return "{\(parts)}"
		}
	}
}

#endif
