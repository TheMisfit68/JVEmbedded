// JSONCodable.swift
//
// A blend of human creativity by TheMisfit68  and
// AI assistance from ChatGPT.
// Crafting the future, one line of Swift at a time.
// Copyright © 2023 Jan Verrept. All rights reserved.

// Mark: - JSONCodable protocols
public protocol JSONEncodable {
	func encode(to encoder: inout JSONEncoder) throws(JSONError)
}

public protocol JSONDecodable {
	init?(from decoder: JSONDecoder)
}

public typealias JSONCodable = JSONEncodable & JSONDecodable
