// JSONDecoder.swift
// JVEmbedded
//
// A blend of human creativity by TheMisfit68 and
// AI assistance from ChatGPT.
// Crafting the future, one line of Swift at a time.
// Copyright © 2023–2025 Jan Verrept. All rights reserved.

public class JSONDecoder: Decoder {
	
	public init(jsonString: String) throws(DecodingError) {
		var parser = JSONParser(jsonString)
		let rootValue = try parser.parse()
		
		guard case .dictionary(let dict) = rootValue else {
			throw DecodingError.invalidFormat("Expected root JSON object")
		}
		
		super.init(storage: .dictionary(dict))
	}
}
