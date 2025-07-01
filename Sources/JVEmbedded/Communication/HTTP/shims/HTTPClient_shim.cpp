// httpclient_shim.cpp

#include "httpclient_shim.h"

#include "esp_log.h"


extern "C" esp_http_client_config_t make_http_config(const char *url,
													 uint32_t port,
													 const char *client_id,
													 const char *user,
													 const char *pass) {
	
	esp_http_client_config_t config = {};
	config.url = url;
	config.username = user;
	config.password = pass;
	config.auth_type = HTTP_AUTH_TYPE_BASIC;
	
	return config;
}



static const char* TAG = "HTTPClient_shim";

// Event handler for HTTP events
esp_err_t _http_event_handle(esp_http_client_event_t *evt)
{
	switch(evt->event_id) {
		case HTTP_EVENT_ERROR:
			ESP_LOGI(TAG, "HTTP_EVENT_ERROR");
			break;
		case HTTP_EVENT_ON_CONNECTED:
			ESP_LOGI(TAG, "HTTP_EVENT_ON_CONNECTED");
			break;
		case HTTP_EVENT_HEADER_SENT:
			ESP_LOGI(TAG, "HTTP_EVENT_HEADER_SENT");
			break;
		case HTTP_EVENT_ON_HEADER:
			ESP_LOGI(TAG, "HTTP_EVENT_ON_HEADER");
			printf("%.*s", evt->data_len, (char*)evt->data);
			break;
		case HTTP_EVENT_ON_DATA:
			ESP_LOGI(TAG, "HTTP_EVENT_ON_DATA, len=%d", evt->data_len);
			if (!esp_http_client_is_chunked_response(evt->client)) {
				printf("%.*s", evt->data_len, (char*)evt->data);
			}
			break;
		case HTTP_EVENT_ON_FINISH:
			ESP_LOGI(TAG, "HTTP_EVENT_ON_FINISH");
			break;
		case HTTP_EVENT_DISCONNECTED:
			ESP_LOGI(TAG, "HTTP_EVENT_DISCONNECTED");
			break;
	}
	return ESP_OK;
}


extern "C" HTTPResult http_get_shim(HTTP_ctx* http, const char* url, const char* user, const char* pass, HTTP_read_callback* cb) {
	
	esp_http_client_handle_t client = esp_http_client_init(&config);
	esp_err_t err = esp_http_client_perform(client);
	
	if (err == ESP_OK) {
		ESP_LOGI(TAG, "Status = %d, content_length = %d",
				 esp_http_client_get_status_code(client),
				 esp_http_client_get_content_length(client));
	}
	esp_http_client_cleanup(client);
	
}
