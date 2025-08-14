//
//  WiFiSettings.swift
//  JVEmbedded
//
//  Created by Jan Verrept on 01/07/2025.
//



struct WiFiSettings:ConfigurableSettings {
	
	var SSID: String?
	var password: String?
	
	init?(nameSpace:String? = nil){
		let namespace = nameSpace ?? "WiFi" // Provides the default namespace if none is specified
		do {
			SSID = try SettingsManager.shared.readNVS(namespace:namespace, key: "SSID")
			password = try SettingsManager.shared.readNVS(namespace:namespace, key: "Password")
		} catch {
			print("❌ Error reading \(namespace)-settings: \(error)")
			return nil
		}
	}
	
}

