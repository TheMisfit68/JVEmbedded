// WiFiEventShim.c
#include "esp_event.h"
#include "esp_log.h"
#include "esp_wifi.h"
#include "esp_netif.h"
#include "Wifi_shim.h"

static bool s_wifiConnected = false;
static bool s_ipAcquired = false;

static void wifi_event_handler(void* arg, esp_event_base_t event_base,
                               int32_t event_id, void* event_data) {

    if (event_base == WIFI_EVENT && event_id == WIFI_EVENT_STA_CONNECTED) {
        ESP_LOGI("WiFiShim", "✅ Wi-Fi connected");
        s_wifiConnected = true;
    }

    if (event_base == IP_EVENT && event_id == IP_EVENT_STA_GOT_IP) {
        ESP_LOGI("WiFiShim", "✅ IP address acquired");
        s_ipAcquired = true;
    }
}

void WiFiEventShim_registerHandlers(void) {
    esp_event_handler_register(WIFI_EVENT, ESP_EVENT_ANY_ID, &wifi_event_handler, NULL);
    esp_event_handler_register(IP_EVENT, ESP_EVENT_ANY_ID, &wifi_event_handler, NULL);
}

bool WiFiEventShim_isConnected(void) {
    return s_wifiConnected && s_ipAcquired;
}
