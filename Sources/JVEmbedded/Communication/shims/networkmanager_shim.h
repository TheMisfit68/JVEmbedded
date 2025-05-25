// wifi_event_shims.h
#pragma once

#include "esp_log.h"
#include "esp_wifi.h"
#include "freertos/event_groups.h"

extern "C" {

	extern void handle_ip_event(void *event_data, int32_t event_id);
	extern void handle_wifi_event(void *event_data, int32_t event_id);


	wifi_init_config_t get_default_wifi_init_config_shim(void);

	void ip_event_cb_shim(void *arg, esp_event_base_t event_base, int32_t event_id, void *event_data);

	void wifi_event_cb_shim(void *arg, esp_event_base_t event_base, int32_t event_id, void *event_data);

}
