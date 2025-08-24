#include "networkmanager3_shim.h"

extern "C" {
	
wifi_init_config_t get_default_wifi_init_config_shim(void) {
	return WIFI_INIT_CONFIG_DEFAULT();
}

}
