// NetworkManager.swift
//
// A blend of human creativity by TheMisfit68  and
// AI assistance from ChatGPT.
// Crafting the future, one line of Swift at a time.
// Copyright © 2023 Jan Verrept. All rights reserved.



// MARK: - Event Callbacks (C-compatible, global scope)

@_cdecl("wifi_event_cb")
func wifi_event_cb(arg: UnsafeMutableRawPointer?, base: esp_event_base_t?, id: Int32, data: UnsafeMutableRawPointer?) {
	guard let base = base else { return }
	
	if base == WIFI_EVENT {
		switch id {
			case Int32(WIFI_EVENT_STA_START):
				esp_wifi_connect()
			case Int32(WIFI_EVENT_STA_DISCONNECTED):
				if let manager = NetworkManager.shared {
					if manager.retryCount < manager.maxRetryAttempts {
						manager.retryCount += 1
						print("🔁 Retrying Wi-Fi connection (\(manager.retryCount))")
						esp_wifi_connect()
					} else {
						xEventGroupSetBits(manager.eventGroup, manager.WIFI_FAIL_BIT)
					}
				}
			default:
				break
		}
	}
}

@_cdecl("ip_event_cb")
func ip_event_cb(arg: UnsafeMutableRawPointer?, base: esp_event_base_t?, id: Int32, data: UnsafeMutableRawPointer?) {
	guard let base = base else { return }
	
	if base == IP_EVENT {
		switch id {
			case Int32(IP_EVENT_STA_GOT_IP):
				if let eventData = data?.assumingMemoryBound(to: ip_event_got_ip_t.self) {
					let ip = eventData.pointee.ip_info.ip
					let ipStr = String(cString: inet_ntoa(ip))
					print("📡 Got IP: \(ipStr)")
					if let manager = NetworkManager.shared {
						xEventGroupSetBits(manager.eventGroup, manager.WIFI_CONNECTED_BIT)
					}
				}
			default:
				break
		}
	}
}

final class NetworkManager:Singleton {
	
	public static let shared:NetworkManager? = NetworkManager()
	
	// MARK: - Constants
	let WIFI_AUTHMODE: wifi_auth_mode_t = WIFI_AUTH_WPA2_PSK
	let WIFI_CONNECTED_BIT: UInt32 = 1 << 0
	let WIFI_FAIL_BIT : UInt32 = 1 << 1
	let maxRetryAttempts = 3
	
	// MARK: - Internal State
	private var retryCount = 0
	private var netif: OpaquePointer? = nil
	private var ipEventHandler: esp_event_handler_instance_t? = nil
	private var wifiEventHandler: esp_event_handler_instance_t? = nil
	private var eventGroup: EventGroupHandle_t? = nil
	
	// MARK: - Public API
	/// Initializes Wi-Fi system
	///
	init?(){
		
		var result:esp_err_t
		
		do {
			
			result = nvs_flash_init()
			if result == ESP_ERR_NVS_NO_FREE_PAGES || result == ESP_ERR_NVS_NEW_VERSION_FOUND {
				_ = nvs_flash_erase()
				result = nvs_flash_init()
			}
			
			eventGroup = xEventGroupCreate()
			guard eventGroup != nil else {
				print("❌ Error: Failed to create event group")
				return nil
			}
			
			try ESPError.check(esp_netif_init())
			
			result = esp_event_loop_create_default()
			try ESPError.check(result)
			
			result = esp_wifi_set_default_wifi_sta_handlers()
			try ESPError.check(result)
			
			netif = esp_netif_create_default_wifi_sta()
			if netif == nil {
				print("❌ Error: Failed to create default Wi-Fi STA interface")
				return nil
			}
			
			var cfg = WIFI_INIT_CONFIG_DEFAULT()
			result = esp_wifi_init(&cfg)
			try ESPError.check(result)
			
			result = esp_event_handler_instance_register(
				WIFI_EVENT,
				ESP_EVENT_ANY_ID,
				&wifi_event_cb,
				nil,
				&wifiEventHandler
			)
			try ESPError.check(result)
			
			result = esp_event_handler_instance_register(
				IP_EVENT,
				ESP_EVENT_ANY_ID,
				&ip_event_cb,
				nil,
				&ipEventHandler
			)
			try ESPError.check(result)
			
		} catch {
			return nil
		}
		
	}
	
	public func connect(ssid: String, password: String) throws(ESPError) {
		
		var wifiConfig = wifi_config_t()
		wifiConfig.sta.threshold.authmode = WIFI_AUTHMODE
		
		let cSSID = strdup(ssid)
		let cPassword = strdup(password)
		defer {
			free(cSSID)
			free(cPassword)
		}
		
		strncpy(&wifiConfig.sta.ssid.0, cSSID, MemoryLayout.size(ofValue: wifiConfig.sta.ssid))
		strncpy(&wifiConfig.sta.password.0, cPassword, MemoryLayout.size(ofValue: wifiConfig.sta.password))
		
		try ESPError.check(esp_wifi_set_ps(WIFI_PS_NONE))
		try ESPError.check(esp_wifi_set_storage(WIFI_STORAGE_RAM))
		try ESPError.check(esp_wifi_set_mode(WIFI_MODE_STA))
		try ESPError.check(esp_wifi_set_config(WIFI_IF_STA, &wifiConfig))
		try ESPError.check(esp_wifi_start())
		
		let bits = xEventGroupWaitBits(
			eventGroup,
			WIFI_CONNECTED_BIT | WIFI_FAIL_BIT,
			pdFALSE,
			pdFALSE,
			portMAX_DELAY
		)
		
		if (bits & WIFI_CONNECTED_BIT) != 0 {
			print("✅ Connected to Wi-Fi network: \(ssid)")
		} else if (bits & WIFI_FAIL_BIT) != 0 {
			throw ESPError.wifi(.notStarted)
		} else {
			throw ESPError.wifi(.notStarted)
		}
	}
	
	public func disconnect() throws(ESPError) {
		if let group = eventGroup {
			vEventGroupDelete(group)
			eventGroup = nil
		}
		
		let result = esp_wifi_disconnect()
		try ESPError.check(result)
	}
	
	public func deinitialize() throws(ESPError) {
		
		var result = esp_wifi_stop()
		if result == ESP_ERR_WIFI_NOT_INIT {
			try ESPError.check(result)
		} else {
			try ESPError.check(result)
		}
		
		try ESPError.check(esp_wifi_deinit())
		
		if let netif = netif {
			try ESPError.check(esp_wifi_clear_default_wifi_driver_and_handlers(netif))
			esp_netif_destroy(netif)
			self.netif = nil
		}
		
		if let ipHandler = ipEventHandler {
			try ESPError.check(esp_event_handler_instance_unregister(IP_EVENT, ESP_EVENT_ANY_ID, ipHandler))
			ipEventHandler = nil
		}
		
		if let wifiHandler = wifiEventHandler {
			try ESPError.check(
				esp_event_handler_instance_unregister(WIFI_EVENT, ESP_EVENT_ANY_ID, wifiHandler))
			wifiEventHandler = nil
		}
		
		print("✅ NetworkManager successfully deinitialized")
	}
}
