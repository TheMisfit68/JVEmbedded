#pragma once

// ToDo: Place this in the bridging-header or CMakeTarget
// UNSET MBEDTLS_CONFIG_FILE!!
// it creates a conflict somehow within ESP-IDF v5.2.3
#ifdef MBEDTLS_CONFIG_FILE
#undef MBEDTLS_CONFIG_FILE
#endif

#include <mqtt5_client.h>
#include <mbedtls/esp_config.h>

#include <esp_tls.h>

#include "esp_system.h"
#include "esp_heap_caps.h"
#include "esp_event.h"
#include "esp_log.h"
#include "sdkconfig.h"


#include "nvs_flash.h"
#include "esp_netif.h"
#include "esp_wifi.h"      // For esp_wifi_* functions and Wi-Fi config
#include "lwip/dns.h"      // For dns_setserver and IP address manipulation
#include "lwip/ip_addr.h"  // For ip_addr_t and ipaddr_aton

extern "C" {

esp_mqtt_client_config_t make_mqtt_config(const char *hostname,
													 uint32_t port,
													 const char *client_id,
													 const char *username,
													 const char *password);


}
