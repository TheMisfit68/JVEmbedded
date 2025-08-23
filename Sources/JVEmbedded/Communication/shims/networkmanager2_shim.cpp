//// networkmanager2_shim.cpp
////
//// C ↔︎ Swift bridge for NetworkManager2
//// Thin proxies to Swift static @_cdecl functions
//
//#include "networkmanager2_shim.h"
//
//// ESP-IDF event callbacks
//void networkmanager2_wifi_connected_shim(void* handler_arg, esp_event_base_t base, int32_t id, void* event_data)
//{
//	wifi_connected_callback_shim();
//}
//
//void networkmanager2_wifi_disconnected_shim(void* handler_arg, esp_event_base_t base, int32_t id, void* event_data)
//{
//	wifi_disconnected_callback_shim();
//}
//
//// Start / register network
//void networkmanager2_start_shim(void) {
//	esp_event_handler_instance_t wifiConnectedHandler = NULL;
//	esp_event_handler_instance_t wifiDisconnectedHandler = NULL;
//	
//	esp_event_handler_instance_register(
//										WIFI_EVENT,
//										WIFI_EVENT_STA_CONNECTED,
//										&networkmanager2_wifi_connected_shim,
//										NULL,
//										&wifiConnectedHandler
//										);
//	
//	esp_event_handler_instance_register(
//										WIFI_EVENT,
//										WIFI_EVENT_STA_DISCONNECTED,
//										&networkmanager2_wifi_disconnected_shim,
//										NULL,
//										&wifiDisconnectedHandler
//										);
//	
//	esp_wifi_start();
//	esp_wifi_connect();
//}
