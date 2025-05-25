//
//  StorageError.swift
//  JVEmbedded
//
//  Created by Jan Verrept on 24/05/2025.
//


public enum StorageError: Error, ESPErrorProtocol {
	
	case ok
	case notFound
	case invalidName
	case invalidHandle
	case flashOpFail
	case flashTimeout
	case spiffsMountFailed
	case writeError
	case readError
	case unknown
	
	public init(code: esp_err_t) {
		switch code {
			case ESP_OK:
				self = .ok
			case ESP_ERR_NVS_NOT_FOUND:
				self = .notFound
			case ESP_ERR_NVS_INVALID_NAME:
				self = .invalidName
			case ESP_ERR_NVS_INVALID_HANDLE:
				self = .invalidHandle
			case ESP_ERR_FLASH_OP_FAIL:
				self = .flashOpFail
			case ESP_ERR_FLASH_OP_TIMEOUT:
				self = .flashTimeout
			case ESP_FAIL:
				self = .spiffsMountFailed
			default:
				self = .unknown
		}
	}
}

