// Application.swift
//
// Singleton managing the main application logic and network events
// Author: Jan Verrept / AI assisted
// Copyright © 2023 Jan Verrept. All rights reserved.

extension JVEmbedded{
	
	// MARK: - Matter.AppDelegate Protocol
	public protocol AppDelegate: AnyObject {
		func didConnect()
		func didDisconnect()
	}
	
	public final class Application:Singleton {
		
		// MARK: - Singleton
		public static let shared:Application = Application()
		public static var wifiSettingsNameSpace:String = "WiFi"
		
		public var delegate:JVEmbedded.AppDelegate? = nil
		
		// An asynchronuous/non-blocking retry mechanism for network reconnections
		private var reconnectTimer:Oscillator!
		public var recconnectInterval:Double = 10.0
		
		private init(){
			
			// Setup the network
			NetworkManager.shared?.delegate = self
			do{
				try NetworkManager.shared?.connect(settingsNameSpace: JVEmbedded.Application.wifiSettingsNameSpace)
			}catch let error{
#if DEBUG
				print("⚠️ Network connection failed: \(error)")
#endif
			}
			self.reconnectTimer = Oscillator(name: "Application.reconnectTimer", delay: recconnectInterval) { oscillator in
				// Attempt to reconnect
				if let _ = try? NetworkManager.shared?.connect(settingsNameSpace: JVEmbedded.Application.wifiSettingsNameSpace) {
#if DEBUG
					print("✅ Network reconnected successfully")
#endif
				} else {
#if DEBUG
					print("⚠️ Network reconnection failed")
#endif
				}
			}
			self.reconnectTimer.enable = false
		}
		
		
	}
	
	// Restart the entire ESP32 system
	public func restart(){
		esp_restart()
	}
	
}


// MARK: - NetworkManagerDelegate
extension JVEmbedded.Application:NetworkManagerDelegate{
	
	public func networkDidConnect() {
		
		delegate?.didConnect()
		reconnectTimer.enable = false // Pause the reconnect timer
	}
	
	public func networkDidDisconnect() {

		delegate?.didDisconnect()
	}
	
	public func networkDidFailToConnect(){
		
		reconnectTimer.enable = true // Start the reconnect timer to retry connecting after a while
	}
	
}
