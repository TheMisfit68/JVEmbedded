////
////  networkmanager2_shim.h
////  JVEmbedded
////
////  Created by Jan Verrept on 20/08/2025.
////
//
//
//// networkmanager2_shim.h
////
//// C ↔︎ Swift bridge for NetworkManager2
//// Provides thin C proxies to Swift static @_cdecl functions
//// Author: Jan Verrept / AI assisted
//// Copyright © 2023 Jan Verrept. All rights reserved.
//#pragma once
//
//#include "esp_wifi.h"
//#include "freertos/event_groups.h"
//
//extern "C" {
//
//// Start and register network and Wi-Fi event callbacks
//void networkmanager2_start_shim(void);
//
//// ESP-IDF Wi-Fi event callbacks
//void networkmanager2_wifi_connected_shim(void* handler_arg, esp_event_base_t base, int32_t id, void* event_data);
//void networkmanager2_wifi_disconnected_shim(void* handler_arg, esp_event_base_t base, int32_t id, void* event_data);
//
//
//// Bridge functions implemented on the Swift side
//void wifi_connected_callback_shim(void);
//void wifi_disconnected_callback_shim(void);
//
//}
//
//
//
