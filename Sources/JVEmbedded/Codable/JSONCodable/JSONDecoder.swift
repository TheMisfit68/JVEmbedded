// JSONDecoder.swift
//
// A blend of human creativity by TheMisfit68  and
// AI assistance from ChatGPT.
// Crafting the future, one line of Swift at a time.
// Copyright © 2023 Jan Verrept. All rights reserved.

#if hasFeature(Embedded)

public final class JSONDecoder: Decoder {
	
	public init(jsonString: String) throws(DecodingError) {
		let storage = try JSONDecoder.parseJSON(jsonString)
		super.init(storage: storage)
	}
	
	/// Parse a JSON string into a dictionary storage
	public static func parseJSON(_ jsonString: String) throws(DecodingError) -> [String: CodableValue] {
		var parser = JSONParser(jsonString)
		let value = try parser.parse()
		guard case .object(let dict) = value else {
			throw DecodingError.invalidFormat("Top-level JSON is not an object")
		}
		return dict
	}
}

#endif
