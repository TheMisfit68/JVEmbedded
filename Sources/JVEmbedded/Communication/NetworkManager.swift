// NetworkManager.swift
//
// A blend of human creativity by TheMisfit68  and
// AI assistance from ChatGPT.
// Crafting the future, one line of Swift at a time.
// Copyright © 2023 Jan Verrept. All rights reserved.

// MARK: - Event Callbacks (C-compatible, global scope)
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
	case staBeaconTimeout = 43  // 👈 Add this
}

@_cdecl("handle_ip_event")
func handle_ip_event(eventData: UnsafeMutableRawPointer?, eventID: Int32) {
	guard let eventID = IPEventID(rawValue: eventID) else {
		print("Unhandled IP event ID: \(eventID)")
		return
	}
	
	switch eventID {
		case .gotIP:
			let event = eventData?.assumingMemoryBound(to: ip_event_got_ip_t.self).pointee
			if let ip = event?.ip_info.ip {
				let ipString = NetworkManager.ipToString(ip)
				print("📡 Got IP: \(ipString)")
			}
			
			// Inline signalConnected()
			NetworkManager.shared?.retryCount = 0
			if let group = NetworkManager.shared?.eventGroup {
				xEventGroupSetBits(group, NetworkManager.shared!.WIFI_CONNECTED_BIT)
			}
			
		case .lostIP:
			print("Lost IP")
			
		case .gotIP6:
			let event = eventData?.assumingMemoryBound(to: ip_event_got_ip6_t.self).pointee
			if let ip6 = event?.ip6_info.ip {
				print("Got IPv6: \(ip6)")
			}
			// Inline signalConnected()
			NetworkManager.shared?.retryCount = 0
			if let group = NetworkManager.shared?.eventGroup {
				xEventGroupSetBits(group, NetworkManager.shared!.WIFI_CONNECTED_BIT)
			}
	}
}

@_cdecl("handle_wifi_event")
func handle_wifi_event(eventData: UnsafeMutableRawPointer?, eventID: Int32) {
	guard let eventID = WiFiEventID(rawValue: eventID) else {
		print("Unhandled Wi-Fi event ID: \(eventID)")
		return
	}
	
	switch eventID {
		case .wifiReady:
			print("Wi-Fi ready")
			
		case .scanDone:
			print("Scan completed")
			
		case .staStart:
			print("Connecting to AP…")
			esp_wifi_connect()
			
		case .staStop:
			print("Wi-Fi stopped")
			
		case .staConnected:
			print("Wi-Fi connected")
			
		case .staDisconnected:
			print("Wi-Fi disconnected")
			if let manager = NetworkManager.shared {
				if manager.retryCount < manager.maxRetryAttempts {
					print("Retrying…")
					esp_wifi_connect()
					manager.retryCount += 1
				} else {
					print("Failed to connect")
					// Inline signalFailed()
					if let group = manager.eventGroup {
						xEventGroupSetBits(group, manager.WIFI_FAIL_BIT)
					}
				}
			}
			
		case .authModeChanged:
			print("Auth mode changed")
		case .staBeaconTimeout:
			print("⚠️ Beacon timeout – AP not responding")
	}
}


// MARK: - NetworkManager
final class NetworkManager:Singleton {
	
	public static let shared:NetworkManager? = NetworkManager()
	
	// MARK: - Constants
	let WIFI_AUTHMODE: wifi_auth_mode_t = WIFI_AUTH_WPA2_PSK
	let WIFI_CONNECTED_BIT: UInt32 = 1 << 0
	let WIFI_FAIL_BIT : UInt32 = 1 << 1
	let maxRetryAttempts = 3
	
	// MARK: - Internal State
	var retryCount = 0
	var eventGroup: EventGroupHandle_t? = nil

	private var netif: OpaquePointer? = nil
	private static var wifiEventHandler: esp_event_handler_instance_t? = nil
	private static var ipEventHandler: esp_event_handler_instance_t? = nil

	public static func ipToString(_ ip: esp_ip4_addr_t) -> String {
		print("Converting IP to string gets called")
		let addr = UInt32(bigEndian: ip.addr)
		let octets = (
			(addr >> 24) & 0xFF,
			(addr >> 16) & 0xFF,
			(addr >> 8) & 0xFF,
			addr & 0xFF
		)
		return "\(octets.0).\(octets.1).\(octets.2).\(octets.3)"
	}
	
	private static func ensureEventHandlersRegistered() throws(NetworkError) {
		if !eventsRegistered {
			try registerForEvents()
		}
	}
	private static var eventsRegistered = false
	
	public static func registerForEvents() throws(NetworkError) {
		
		// Initialize the default event loop if not yet created
		let result = esp_event_loop_create_default()
		try NetworkError.check(result, "❌ Could not create event loop")
		
		try NetworkError.check(esp_event_handler_instance_register(
			WIFI_EVENT,
			ESP_EVENT_ANY_ID,
			wifi_event_cb_shim,
			nil,
			&wifiEventHandler
		), "❌ Wifi event handler registration failed")
		
		try NetworkError.check(esp_event_handler_instance_register(
			IP_EVENT,
			ESP_EVENT_ANY_ID,
			ip_event_cb_shim,
			nil,
			&ipEventHandler
		), "❌ IP event handler registration failed")
		
		eventsRegistered = true
		print("✅ NetworkManager: Wi-Fi and IP event handlers registered")
	}
	
	public init?() {
		
		var result: esp_err_t

		do {
			
			result = nvs_flash_init()
			if result == ESP_ERR_NVS_NO_FREE_PAGES || result == ESP_ERR_NVS_NEW_VERSION_FOUND {
				_ = nvs_flash_erase()
				result = nvs_flash_init()
			}
			try NetworkError.check(result)
			
			eventGroup = xEventGroupCreate()
			guard eventGroup != nil else {
				print("❌ Error: Failed to create event group")
				return nil
			}
			
			try NetworkError.check(esp_netif_init())
			
			result = esp_event_loop_create_default()
			try NetworkError.check(result)
			
			result = esp_wifi_set_default_wifi_sta_handlers()
			try NetworkError.check(result)
			
			netif = esp_netif_create_default_wifi_sta()
			guard netif != nil else {
				print("❌ Error: Failed to create default Wi-Fi STA interface")
				return nil
			}
			
			var cfg = get_default_wifi_init_config_shim()
			result = esp_wifi_init(&cfg)
			try NetworkError.check(result)
			
			try Self.ensureEventHandlersRegistered()
			
		} catch {
			print("❌ NetworkManager init failed with error: \(error)")
			return nil
		}
	}
	
	public func connect(ssid: String, password: String) throws(NetworkError) {
		
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
		
		try NetworkError.check(esp_wifi_set_ps(WIFI_PS_NONE))
		try NetworkError.check(esp_wifi_set_storage(WIFI_STORAGE_RAM))
		try NetworkError.check(esp_wifi_set_mode(WIFI_MODE_STA))
		try NetworkError.check(esp_wifi_set_config(WIFI_IF_STA, &wifiConfig))
		try NetworkError.check(esp_wifi_start())
		
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
			throw NetworkError.wifiNotStarted
		} else {
			throw NetworkError.wifiNotStarted
		}
	}
	
	public func disconnect() throws(NetworkError) {
		if let group = eventGroup {
			vEventGroupDelete(group)
			eventGroup = nil
		}
		
		let result = esp_wifi_disconnect()
		try NetworkError.check(result)
	}
	
	public func deinitialize() throws(NetworkError) {
		
		var result = esp_wifi_stop()
		if result == ESP_ERR_WIFI_NOT_INIT {
			try NetworkError.check(result)
		} else {
			try NetworkError.check(result)
		}
		
		try NetworkError.check(esp_wifi_deinit())
		
		if let netif = netif {
			try NetworkError.check(esp_wifi_clear_default_wifi_driver_and_handlers(UnsafeMutableRawPointer(netif)))
			esp_netif_destroy(netif)
			self.netif = nil
		}
		
		if let ipHandler = Self.ipEventHandler {
			try NetworkError.check(esp_event_handler_instance_unregister(IP_EVENT, ESP_EVENT_ANY_ID, ipHandler))
			Self.ipEventHandler = nil
		}
		
		if let wifiHandler = Self.wifiEventHandler {
			try NetworkError.check(
				esp_event_handler_instance_unregister(WIFI_EVENT, ESP_EVENT_ANY_ID, wifiHandler))
			Self.wifiEventHandler = nil
		}
		
		print("✅ NetworkManager successfully deinitialized")
	}
}




