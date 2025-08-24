//
//  NetworkError.swift
//  JVEmbedded
//
//  Created by Jan Verrept on 24/05/2025.
//


public enum NetworkError: Error, ESPErrorProtocol {
	case ok
	case wifiNotInit
	case wifiNotStarted
	case wifiTimeout
	case unknown
	
	public init(code: esp_err_t) {
		switch code {
			case ESP_OK:
				self = .ok
			case ESP_ERR_WIFI_NOT_INIT:
				self = .wifiNotInit
			case ESP_ERR_WIFI_NOT_STARTED:
				self = .wifiNotStarted
			case ESP_ERR_WIFI_TIMEOUT:
				self = .wifiTimeout
			default:
				self = .unknown
		}
	}
}
