//
//  ESPError.swift
//  JVEmbedded
//
//  Created by Jan Verrept on 12/07/2025.
//


public enum ESPError: Error, ESPErrorProtocol {
	
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
