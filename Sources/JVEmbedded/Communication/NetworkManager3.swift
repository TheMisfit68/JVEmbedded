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

// MARK: - Singleton
public final class NetworkManager3: Singleton {
	
	public static let shared: NetworkManager3? = try? NetworkManager3()
	
	// C-callback that will be used to pass events onto the Swift message handler
	private static let cCallback: esp_event_handler_t = { context, eventBase, eventId, eventData in
		guard let context else { return }
		guard let eventData else { return }
		
		let mqttClient = Unmanaged<MQTTClient>.fromOpaque(context).takeUnretainedValue()
		
		// Reinterpret eventData as `esp_mqtt_event_t`
		let event = eventData.assumingMemoryBound(to: esp_mqtt_event_t.self).pointee
		
		mqttClient.handleEvent(event)
	}
	
	// MARK: - Delegate
	public var isConnected:Bool{
		get{
			var ap_info = wifi_ap_record_t()
			let result:esp_err_t = esp_wifi_sta_get_ap_info(&ap_info)
			return (result == ESP_OK)
		}
	}
	public var delegate: NetworkManager3Delegate?
	
	// MARK: - Internal State
	var wifiSettings: WiFiSettings?
	var retryCount = 0
	let maxRetryAttempts = 10
	
	private init() throws(NetworkError) {
		
		try NetworkError.check(nvs_flash_init())
		try NetworkError.check(esp_netif_init())
		try NetworkError.check(esp_event_loop_create_default())
		try NetworkError.check(esp_wifi_set_default_wifi_sta_handlers())
		guard let netif = esp_netif_create_default_wifi_sta() else {
			throw NetworkError.wifiNotInit
		}
		var wifiInitCfg = defaultWifiConfig
		try NetworkError.check(esp_wifi_init(&wifiInitCfg), "Wi-Fi init failed")
		
		let wifiHandler: esp_event_handler_t? = wifiEventHandler
		let ipHandler: esp_event_handler_t? = ipEventHandler
		var instance_wifi: esp_event_handler_instance_t?
		var instance_ip: esp_event_handler_instance_t?
		
		let regWifiErr = esp_event_handler_instance_register(
			WIFI_EVENT,
			ESP_EVENT_ANY_ID,
			wifiHandler,
			nil,
			&instance_wifi
		)
		try NetworkError.check(regWifiErr, "Failed to register Wi-Fi event handler")
		
		let regIpErr = esp_event_handler_instance_register(
			IP_EVENT,
			ESP_EVENT_ANY_ID,
			ipHandler,
			nil,
			&instance_ip
		)
		try NetworkError.check(regIpErr, "Failed to register IP event handler")
		
	}
	
	// MARK: - Connect / Disconnect
	public func connect(settingsNameSpace: String?) throws(NetworkError) {
				if let nameSpace = settingsNameSpace {
					self.wifiSettings = WiFiSettings(nameSpace: nameSpace)
				} else {
					self.wifiSettings = WiFiSettings(nameSpace: "WiFi")
				}
		
				guard let ssid = self.wifiSettings?.SSID, let password = self.wifiSettings?.password else { return }
		
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
		
				try NetworkError.check(esp_wifi_set_ps(WIFI_PS_NONE))
				try NetworkError.check(esp_wifi_set_storage(WIFI_STORAGE_RAM))
				try NetworkError.check(esp_wifi_set_mode(WIFI_MODE_STA))
				try NetworkError.check(esp_wifi_set_config(WIFI_IF_STA, &staConfig))
				try NetworkError.check(esp_wifi_start())
				try NetworkError.check(esp_wifi_connect())
	}
	
	public func disconnect() throws(NetworkError) {
		try NetworkError.check(esp_wifi_disconnect())
	}
	
}

// MARK: - C-bridging
// C-config shim to get default Wi-Fi config
extension NetworkManager3 {
	// This variable is an abstraction over the C function to get default Wi-Fi config through a shim
	// Can not be replaced by an initializer and dot notation at this time
	// due to several nested Macro's and #defines in the C code
	private var defaultWifiConfig: wifi_init_config_t {
		return get_default_wifi_init_config_shim()
	}
}

// C-Callbacks

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

@_cdecl("wifi_event_cb_shim")
func wifiEventHandler(_ handler_arg: UnsafeMutableRawPointer?,
					  _ event_base: esp_event_base_t?,
					  _ event_id: Int32,
					  _ event_data: UnsafeMutableRawPointer?) {
	guard let ev = WiFiEventID(rawValue: event_id), let manager = NetworkManager3.shared else { return }
	switch ev {
		case .staStart:
#if DEBUGe
			print("Connecting to AP…")
#endif
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
func ipEventHandler(_ handler_arg: UnsafeMutableRawPointer?,
					_ event_base: esp_event_base_t?,
					_ event_id: Int32,
					_ event_data: UnsafeMutableRawPointer?) {
	guard let ev = IPEventID(rawValue: event_id), let manager = NetworkManager3.shared else { return }
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

