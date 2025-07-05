// httpclient_shim.cpp

#include "http_shim.h"

extern "C" esp_http_client_config_t make_http_config(const char *url,
													 const char *user,
													 const char *pass,
													 esp_err_t (*callback)(esp_http_client_event_t *evt))
{
	
	esp_http_client_config_t config = {};
	config.url = url;
	config.username = user;
	config.password = pass;
	config.auth_type = HTTP_AUTH_TYPE_BASIC;
	config.event_handler = callback;
	
	return config;
}
