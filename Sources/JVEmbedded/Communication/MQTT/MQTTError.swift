//
//  MQTTerror.swift
//  JVEmbedded
//
//  Created by Jan Verrept on 24/05/2025.
//


public enum MQTTerror: Error, ESPErrorProtocol {
	
	case operationFailed
	case unknown
	
	public init(code: esp_err_t) {
		self = .unknown
	}
	
}
