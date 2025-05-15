//
//  Wifi_shim.h
//  JVEmbedded
//
//  Created by Jan Verrept on 12/05/2025.
//


// WiFiEventShim.h

#ifndef WIFI_EVENT_SHIM_H
#define WIFI_EVENT_SHIM_H

#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

void WiFiEventShim_registerHandlers(void);
bool WiFiEventShim_isConnected(void);

#ifdef __cplusplus
}
#endif

#endif /* WIFI_EVENT_SHIM_H */
