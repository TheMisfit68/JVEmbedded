#include "networkmanager3_shim.h"
#include "esp_wifi.h"   // 👈 defines wifi_init_config_t and WIFI_INIT_CONFIG_DEFAULT

extern "C" {

	// Return the default Wi-Fi init config struct
	wifi_init_config_t get_default_wifi_init_config_shim(void) {
		return WIFI_INIT_CONFIG_DEFAULT();
	}

}
