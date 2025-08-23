#pragma once
#include "esp_wifi.h"

#ifdef __cplusplus
extern "C" {
#endif

wifi_init_config_t get_default_wifi_init_config_shim(void);

#ifdef __cplusplus
}
#endif
