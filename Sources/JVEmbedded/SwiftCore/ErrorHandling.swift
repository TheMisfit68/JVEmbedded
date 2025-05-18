// ESPError.swift
// JVEmbedded
//
// A blend of human creativity by TheMisfit68 and
// AI assistance from ChatGPT.
// Crafting the future, one line of Swift at a time.
// Copyright © 2023 Jan Verrept. All rights reserved.

public enum ESPError: Error {
	case general(GeneralError)
	case wifi(WiFiError)
	case nvs(NVSError)
	case unknown(esp_err_t)
	
	public init(code: esp_err_t) {
		switch code {
				
				// General Errors
			case ESP_OK:                         self = .general(.ok)
			case ESP_FAIL:                       self = .general(.fail)
			case ESP_ERR_NO_MEM:                 self = .general(.noMem)
			case ESP_ERR_INVALID_ARG:            self = .general(.invalidArg)
			case ESP_ERR_INVALID_STATE:          self = .general(.invalidState)
			case ESP_ERR_INVALID_SIZE:           self = .general(.invalidSize)
			case ESP_ERR_NOT_FOUND:              self = .general(.notFound)
			case ESP_ERR_NOT_SUPPORTED:          self = .general(.notSupported)
			case ESP_ERR_TIMEOUT:                self = .general(.timeout)
			case ESP_ERR_INVALID_RESPONSE:       self = .general(.invalidResponse)
			case ESP_ERR_INVALID_CRC:            self = .general(.invalidCRC)
			case ESP_ERR_INVALID_VERSION:        self = .general(.invalidVersion)
			case ESP_ERR_INVALID_MAC:            self = .general(.invalidMAC)
				
				// Wi-Fi Errors
			case ESP_ERR_WIFI_NOT_INIT:          self = .wifi(.notInitialized)
			case ESP_ERR_WIFI_NOT_STARTED:       self = .wifi(.notStarted)
			case ESP_ERR_WIFI_TIMEOUT:           self = .wifi(.timeout)
				
				// NVS Errors
			case ESP_ERR_NVS_NOT_INITIALIZED:    self = .nvs(.notInitialized)
			case ESP_ERR_NVS_NOT_FOUND:          self = .nvs(.notFound)
			case ESP_ERR_NVS_INVALID_HANDLE:     self = .nvs(.invalidHandle)
			case ESP_ERR_NVS_READ_ONLY:          self = .nvs(.readOnly)
				
			default:
				self = .unknown(code)
		}
	}
	
	public var code: esp_err_t {
		switch self {
			case .general(let e):    return e.code
			case .wifi(let e):       return e.code
			case .nvs(let e):        return e.code
			case .unknown(let raw):  return raw
		}
	}
	
	public static func check(_ code: esp_err_t, _ message: String? = nil) throws(ESPError) {
		if code != ESP_OK {
			let error = ESPError(code: code)
			if let msg = message, !msg.isEmpty {
				print("❌ ESPError: \(msg)")
			}
			if let name = esp_err_to_name(code) {
				print("Code: \(code) – \(String(cString: name))")
			} else {
				print("Code: \(code) – Unknown ESP error")
			}
			throw error
		}
	}
}

// MARK: - General Errors
public enum GeneralError {
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
	case invalidVersion
	case invalidMAC
	
	public var code: esp_err_t {
		switch self {
			case .ok: return ESP_OK
			case .fail: return ESP_FAIL
			case .noMem: return ESP_ERR_NO_MEM
			case .invalidArg: return ESP_ERR_INVALID_ARG
			case .invalidState: return ESP_ERR_INVALID_STATE
			case .invalidSize: return ESP_ERR_INVALID_SIZE
			case .notFound: return ESP_ERR_NOT_FOUND
			case .notSupported: return ESP_ERR_NOT_SUPPORTED
			case .timeout: return ESP_ERR_TIMEOUT
			case .invalidResponse: return ESP_ERR_INVALID_RESPONSE
			case .invalidCRC: return ESP_ERR_INVALID_CRC
			case .invalidVersion: return ESP_ERR_INVALID_VERSION
			case .invalidMAC: return ESP_ERR_INVALID_MAC
		}
	}
}

// MARK: - Wi-Fi Errors
public enum WiFiError {
	case notInitialized
	case notStarted
	case timeout
	
	public var code: esp_err_t {
		switch self {
			case .notInitialized: return ESP_ERR_WIFI_NOT_INIT
			case .notStarted:     return ESP_ERR_WIFI_NOT_STARTED
			case .timeout:        return ESP_ERR_WIFI_TIMEOUT
		}
	}
}

// MARK: - NVS Errors
public enum NVSError {
	case notInitialized
	case notFound
	case invalidHandle
	case readOnly
	
	public var code: esp_err_t {
		switch self {
			case .notInitialized: return ESP_ERR_NVS_NOT_INITIALIZED
			case .notFound:       return ESP_ERR_NVS_NOT_FOUND
			case .invalidHandle:  return ESP_ERR_NVS_INVALID_HANDLE
			case .readOnly:       return ESP_ERR_NVS_READ_ONLY
		}
	}
}
