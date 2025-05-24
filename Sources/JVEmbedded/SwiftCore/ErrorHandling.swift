// ErrorHandling.swift
// JVEmbedded
//
// A blend of human creativity by TheMisfit68 and
// AI assistance from ChatGPT.
// Crafting the future, one line of Swift at a time.
// Copyright © 2023 Jan Verrept. All rights reserved.

// MARK: - Protocol that throws Swift errors
// based on ESP-IDF error codes and that can be applied to different esp submodules.

protocol ESPErrorProtocol:Error {
	init(code: esp_err_t)
	static func check(_ code: esp_err_t, _ message: String?) throws(Self)
}

extension ESPErrorProtocol {
	
	public static func check(_ code: esp_err_t, _ message: String? = nil) throws(Self) {
		
		if code != ESP_OK {
			
			if let msg = message, !msg.isEmpty {
				print("❌ ESPError: \(msg)")
			}
			if let name = esp_err_to_name(code) {
				print("Code: \(code) – \(String(cString: name))")
			} else {
				print("Code: \(code) – Unknown ESP error")
			}
			
			throw Self(code: code)
		}
	}
	
}

public enum GeneralError: Error, ESPErrorProtocol {
	
	case ok
	case fail
	case noMem
	case invalidArg
	case invalidState
	case invalidSize
	case notFound
	case notSupported
	case timeout
	case invalidResponse
	case invalidCRC
	case unknown
	
	public init(code: esp_err_t) {
		switch code {
				
			case ESP_OK:
				self = .ok
			case ESP_FAIL:
				self = .fail
			case ESP_ERR_NO_MEM:
				self = .noMem
			case ESP_ERR_INVALID_ARG:
				self = .invalidArg
			case ESP_ERR_INVALID_STATE:
				self = .invalidState
			case ESP_ERR_INVALID_SIZE:
				self = .invalidSize
			case ESP_ERR_NOT_FOUND:
				self = .notFound
			case ESP_ERR_NOT_SUPPORTED:
				self = .notSupported
			case ESP_ERR_TIMEOUT:
				self = .timeout
			case ESP_ERR_INVALID_RESPONSE:
				self = .invalidResponse
			case ESP_ERR_INVALID_CRC:
				self = .invalidCRC
				
			default:
				self = .unknown
		}
	}
	
}
