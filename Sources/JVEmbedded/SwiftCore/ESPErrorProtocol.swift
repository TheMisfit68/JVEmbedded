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
