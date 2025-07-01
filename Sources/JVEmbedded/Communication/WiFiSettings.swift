//
//  WiFiSettings.swift
//  JVEmbedded
//
//  Created by Jan Verrept on 01/07/2025.
//



struct WiFiSettings {
	
	let SSID: String
	let password: String
	
	init?() {
		do {
			self.SSID = try SettingsManager.shared.readNVS(namespace:"WiFi", key: "SSID")
			self.password = try SettingsManager.shared.readNVS(namespace:"WiFi", key: "Password")
		}catch {
			print("❌ [WiFiSettings.init?] Error reading WiFiSettings from NVS")
			return nil
		}
	}
	
}

