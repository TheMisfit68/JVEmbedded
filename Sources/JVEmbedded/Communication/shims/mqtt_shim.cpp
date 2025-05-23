#include "mqtt_shim.h"

extern "C" esp_mqtt_client_config_t make_mqtt_config(const char *hostname,
													 uint32_t port,
													 const char *client_id,
													 const char *username,
													 const char *password) {
	
	esp_mqtt_client_config_t config = {};
	
	config.broker.address.hostname = hostname;
	config.broker.address.port = port;
	config.broker.address.transport = MQTT_TRANSPORT_OVER_SSL;
	
	config.broker.verification.use_global_ca_store = true;
	
	config.credentials.client_id = client_id;
	config.credentials.username = username;
	config.credentials.authentication.password = password;
	
	config.session.keepalive = 60;
	config.buffer.size = 4096;
	config.task.stack_size = 8192;

	return config;
}
