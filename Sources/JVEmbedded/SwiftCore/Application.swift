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
		public static let shared = Application()
		public static var wifiSettingsNameSpace:String = "WiFi"
		
		public var delegate:JVEmbedded.AppDelegate? = nil
		
		// An asynchronuous/non-blocking retry mechanism for network reconnections
		private var reconnectTimer:Oscillator!
		public var recconnectInterval:Double = 10.0
		
		private init() {
			
			// Setup the network
			NetworkManager3.shared.delegate = self
			NetworkManager3.shared.connect(settingsNameSpace: JVEmbedded.Application.wifiSettingsNameSpace)
			self.reconnectTimer = Oscillator(name: "Application.reconnectTimer", delay: recconnectInterval) { oscillator in
				NetworkManager3.shared.connect(settingsNameSpace: JVEmbedded.Application.wifiSettingsNameSpace)
			}
			self.reconnectTimer.enable = false
			
		}
		
		// Restart the entire ESP32 system
		public func restart(){
			esp_restart()
		}
		
	}
	
	
}

// MARK: - NetworkManager3Delegate
extension JVEmbedded.Application:NetworkManager3Delegate{
	public func networkDidConnect() {
		
#if DEBUG
		print("✅ Network connected")
#endif
		delegate?.didConnect()
		reconnectTimer.enable = false // Pause the reconnect timer
	}
	
	public func networkDidDisconnect() {
#if DEBUG
		print("⚠️ Network disconnected, retrying...")
#endif
		delegate?.didDisconnect()
	}
	
	public func networkDidFailToConnect(){
		reconnectTimer.enable = true // Start the reconnect timer to retry connecting after a while
	}
	
}
