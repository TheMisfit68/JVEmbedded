// JSONEncoder.swift
//
// A blend of human creativity by TheMisfit68  and
// AI assistance from ChatGPT.
// Crafting the future, one line of Swift at a time.
// Copyright © 2023 Jan Verrept. All rights reserved.

#if hasFeature(Embedded)

public final class JSONEncoder: Encoder {
	
	/// Encodes the current structure to a JSON-formatted string
	public func encodeToString() -> String {
		return serialize(self.storage)
	}
	
	// Helper function to serialize the dictionary to a JSON string
	private func serialize(_ object: [String: CodableValue]) -> String {
		let parts = object.map { key, value in
			return "\"\(key)\": \(value.jsonDescription)"
		}.joined(separator: ", ")
		return "{\(parts)}"
	}
}

#endif
