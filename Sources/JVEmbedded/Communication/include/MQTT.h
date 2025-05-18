//
//  MQTT.h
//  JVEmbedded
//
//  Created by Jan Verrept on 17/05/2025.
//

// ESP-IDF includes for the MQTT client with TLS support
#include <stdio.h>
#include <esp_spiffs.h>
//#include <esp_tls.h>
#include "mqtt_client.h"

#include "esp_system.h"
#include "esp_mac.h" // Needed to get the Mac-address
#include <lwip/sockets.h>
#include <lwip/netdb.h>

#include "esp_log.h"
#include "nvs_flash.h"
#include "esp_netif.h"
#include "esp_event.h"

#include "esp_wifi.h"
#include "esp_err.h"

#include "freertos/FreeRTOS.h"
#include <inttypes.h>
#include <string.h>
#include "freertos/task.h"
#include "freertos/event_groups.h"
