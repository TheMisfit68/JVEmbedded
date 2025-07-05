//
//  EncodingDecodingError.swift
//  JVEmbedded
//
//  Created by Jan Verrept on 21/06/2025.
//

#if hasFeature(Embedded) // Embedded platforms like ESP32.


public enum EncodingError: Error {
	case invalidValue(String)
	case missingValue(String)
	case typeMismatch(expected: String, found: String)
	case invalidKeyPath(String)
	case unsupportedType(String)
}

public enum DecodingError: Error {
	case missingKey(String)
	case typeMismatch(expected: String, found: String)
	case invalidKeyPath(String)
	case invalidEnumValue(String)
	case invalidFormat(String)
}

#endif


