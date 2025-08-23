// NetworkManager3.swift
//
// Swift singleton network manager for Embedded Swift
// Handles Wi-Fi connection and bridges callbacks from C directly
// Author: Jan Verrept / AI assisted
// Copyright © 2023 Jan Verrept. All rights reserved.

public protocol NetworkManager3Delegate: AnyObject {
	func networkDidConnect()
	func networkDidDisconnect()
	func networkDidFailToConnect()
}

// MARK: - Event ID enums
enum IPEventID: Int32 {
	case gotIP = 0
	case lostIP = 1
	case gotIP6 = 2
}

enum WiFiEventID: Int32 {
	case wifiReady = 0
	case scanDone = 1
	case staStart = 2
	case staStop = 3
	case staConnected = 4
	case staDisconnected = 5
	case authModeChanged = 6
	case staBeaconTimeout = 43
}

// MARK: - Singleton
public final class NetworkManager3: Singleton {
	
	public static let shared: NetworkManager3 = NetworkManager3()
	
	// MARK: - Delegate
	public var delegate: NetworkManager3Delegate?
	
	// MARK: - Internal State
	var wifiSettings: WiFiSettings?
	var retryCount = 0
	let maxRetryAttempts = 10
	private var isStarted = false
	
	private init() {
		start()
	}
	
	// MARK: - Start network
	public func start() {
		guard !isStarted else { return }
		isStarted = true
		setupNetwork()
	}
	
	// MARK: - Setup
	private func setupNetwork() {
		
		_ = nvs_flash_init()
		_ = esp_netif_init()
		_ = esp_event_loop_create_default()
		_ = esp_wifi_set_default_wifi_sta_handlers()
		_ = esp_netif_create_default_wifi_sta()
		
		var initCfg = get_default_wifi_init_config_shim()
		let initResult = esp_wifi_init(&initCfg)
		print("⚙️ Wi-Fi init result: \(initResult)")
		guard initResult == ESP_OK else {
			print("❌ Wi-Fi init failed")
			return
		}
		
		var instance_wifi: esp_event_handler_instance_t?
		var instance_ip: esp_event_handler_instance_t?
		
		print("📌 Registering WIFI_EVENT handler…")
		let wifiHandler: esp_event_handler_t? = wifi_event_cb_shim
		let regWifiErr = esp_event_handler_instance_register(
			WIFI_EVENT,
			ESP_EVENT_ANY_ID,
			wifiHandler,
			nil,
			&instance_wifi
		)
		print("…wifi handler register result: \(regWifiErr)")
		
		print("📌 Registering IP_EVENT handler…")
		let ipHandler: esp_event_handler_t? = ip_event_cb_shim
		let regIpErr = esp_event_handler_instance_register(
			IP_EVENT,
			ESP_EVENT_ANY_ID,
			ipHandler,
			nil,
			&instance_ip
		)
		print("…ip handler register result: \(regIpErr)")
		
		print("✅ NetworkManager3: Wi-Fi and IP event handlers registered")
	}
	
	// MARK: - Connect / Disconnect
	public func connect(settingsNameSpace: String?) {
		if let nameSpace = settingsNameSpace {
			self.wifiSettings = WiFiSettings(nameSpace: nameSpace)
		} else {
			self.wifiSettings = WiFiSettings(nameSpace: "WiFi")
		}
		
		guard let ssid = self.wifiSettings?.SSID, let password = self.wifiSettings?.password else { return }
		
		print("🔌 Connecting to Wi-Fi SSID: \(ssid) with password: \(password)")
		
		let cSSID = strdup(ssid)
		let cPassword = strdup(password)
		defer {
			free(cSSID)
			free(cPassword)
		}
		
		var staConfig = wifi_config_t()
		staConfig.sta.threshold.authmode = WIFI_AUTH_WPA2_PSK
		strncpy(&staConfig.sta.ssid.0, cSSID, MemoryLayout.size(ofValue: staConfig.sta.ssid))
		strncpy(&staConfig.sta.password.0, cPassword, MemoryLayout.size(ofValue: staConfig.sta.password))
		
		_ = esp_wifi_set_ps(WIFI_PS_NONE)
		_ = esp_wifi_set_storage(WIFI_STORAGE_RAM)
		_ = esp_wifi_set_mode(WIFI_MODE_STA)
		_ = esp_wifi_set_config(WIFI_IF_STA, &staConfig)
		print("🚀 Starting Wi-Fi...")
		let startResult = esp_wifi_start()
		print("Wi-Fi start result: \(startResult)")
		_ = esp_wifi_connect()
	}
	
	public func disconnect() {
		_ = esp_wifi_disconnect()
	}
}

// MARK: - Global C-compatible callbacks
@_cdecl("wifi_event_cb_shim")
func wifi_event_cb_shim(_ handler_arg: UnsafeMutableRawPointer?,
						_ event_base: esp_event_base_t?,
						_ event_id: Int32,
						_ event_data: UnsafeMutableRawPointer?) {
	guard let ev = WiFiEventID(rawValue: event_id) else { return }
	let manager = NetworkManager3.shared
	
	switch ev {
		case .staStart:
#if DEBUG
			print("Connecting to AP…")
#endif
			// Removed direct call to esp_wifi_connect() here; now called after esp_wifi_start() in connect(settingsNameSpace:)
		case .staConnected:
			manager.retryCount = 0
#if DEBUG
			print("✅ Wi-Fi link connected")
#endif
			manager.delegate?.networkDidConnect()
		case .staDisconnected:
			manager.retryCount += 1
#if DEBUG
			print("⚠️ Wi-Fi link disconnected, retrying...")
#endif
			if manager.retryCount <= manager.maxRetryAttempts {
				_ = esp_wifi_connect()
			} else {
				manager.delegate?.networkDidFailToConnect()
			}
		default: break
	}
}

@_cdecl("ip_event_cb_shim")
func ip_event_cb_shim(_ handler_arg: UnsafeMutableRawPointer?,
					  _ event_base: esp_event_base_t?,
					  _ event_id: Int32,
					  _ event_data: UnsafeMutableRawPointer?) {
	guard let ev = IPEventID(rawValue: event_id) else { return }
	let manager = NetworkManager3.shared
	
	switch ev {
		case .gotIP, .gotIP6:
			manager.retryCount = 0
#if DEBUG
			print("✅ IP acquired")
#endif
			manager.delegate?.networkDidConnect()
			
		case .lostIP:
#if DEBUG
			print("⚠️ IP lost")
#endif
			manager.delegate?.networkDidDisconnect()
	}
}
