//
//  HTTPClient_shim.h
//  JVEmbedded
//
//  Created by Jan Verrept on 21/06/2025.
//

#pragma once
#include "esp_http_client.h"

extern "C" {

esp_http_client_config_t make_http_config(const char *url,
										  const char *user,
										  const char *pass,
										  esp_err_t (*callback)(esp_http_client_event_t *evt));

}
