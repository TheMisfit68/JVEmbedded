//
//  HTTPError.swift
//  JVEmbedded
//
//  Created by Jan Verrept on 20/06/2025.
//

public enum HTTPError: Error, ESPErrorProtocol {
	
	case failedToInit
	case noData
	case okNotModified
	case notFound
	case badRequest
	case serverError
	case redirected
	case lostConnection
	case requestFailed
	case unknown
	
	public init(code: esp_err_t) {
		self = .unknown
	}
}
