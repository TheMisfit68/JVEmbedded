//
//  WiFiSettings.swift
//  JVEmbedded
//
//  Created by Jan Verrept on 01/07/2025.
//



public struct WiFiSettings:ConfigurableSettings {
	
	var SSID: String?
	var password: String?
	
	init?(nameSpace:String = "WiFi"){
		do {
			SSID = try SettingsManager.shared.readNVS(namespace:nameSpace, key: "SSID")
			password = try SettingsManager.shared.readNVS(namespace:nameSpace, key: "Password")
		} catch {
			print("❌ Error reading \(nameSpace)-settings: \(error)")
			return nil
		}
	}
	
}

