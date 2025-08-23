//// networkmanager_shim.c
//#include "networkmanager_shim.h"
//
//extern "C" {
//
//	// Return the default Wi-Fi init config struct
//	wifi_init_config_t get_default_wifi_init_config_shim(void) {
//		return WIFI_INIT_CONFIG_DEFAULT();
//	}
//
//	// Actual event handlers registered with ESP-IDF
//	void ip_event_cb_shim(void *arg, esp_event_base_t event_base, int32_t event_id, void *event_data) {
//		ESP_LOGI("SwiftShim", "Forwarding IP event 0x%" PRIx32, event_id);
//		handle_ip_event(event_data, event_id);
//	}
//
//	void wifi_event_cb_shim(void *arg, esp_event_base_t event_base, int32_t event_id, void *event_data) {
//		ESP_LOGI("SwiftShim", "Forwarding Wi-Fi event 0x%" PRIx32, event_id);
//		handle_wifi_event(event_data, event_id);
//	}
//
//}
