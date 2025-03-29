//
//  Network.swift
//  JVEmbedded
//
//  Created by Jan Verrept on 21/03/2025.
//

class Network {
	
	// Method to retrieve the MAC address using ESP32 API as a byte array
	static func getMACaddress() -> [UInt8] {
		var macAddress = [UInt8](repeating: 0, count: 6)
		esp_read_mac(&macAddress, ESP_MAC_WIFI_STA)
		return macAddress
	}
	
	// Method to retrieve the MAC address as a formatted string (XX:XX:XX:XX:XX:XX)
	static func getMACaddressString() -> String {
		let macAddress: [UInt8] = getMACaddress() // Get the MAC address as a byte array
		
		// Convert the byte array to a formatted string with hex characters
		let macString = macAddress.map { byte in
			let high = byte >> 4 // Get the high nibble
			let low = byte & 0x0F // Get the low nibble
			
			return "\(high.hexChar())\(low.hexChar())"
		}.joined(separator: ":")

		return macString
	}
	
}
