#include "mqtt_shim.h"

extern "C" esp_mqtt_client_config_t make_mqtt_config(const char *hostname,
													 uint32_t port,
													 const char *client_id,
													 const char *username,
													 const char *password) {
	
	
//	esp_netif_t *wifi_netif;
//	
//	// 1. Initialize the network interface system
//	esp_err_t result = esp_netif_init();
//	if (result != ESP_OK) {
//		printf("esp_netif_init failed: %s\n", esp_err_to_name(result));
//	}
//	
//	// 2. Create default Wi-Fi station interface
//	wifi_netif = esp_netif_create_default_wifi_sta();
//	if (wifi_netif == NULL) {
//		printf("Failed to create Wi-Fi station interface\n");
//	}
	
	// 3. Set up Wi-Fi (STA mode) and start Wi-Fi connection
//	esp_wifi_set_mode(WIFI_MODE_STA);
//	esp_wifi_start();
	
//	// 4. Enable IPv6 link-local address for the Wi-Fi interface
//	result = esp_netif_create_ip6_linklocal(wifi_netif);
//	if (result != ESP_OK) {
//		printf("Failed to create IPv6 link-local address: %s\n", esp_err_to_name(result));
//	}
//	
//	result = esp_event_loop_create_default();
//	printf("esp_event_loop_create_default: %s\n", esp_err_to_name(result));
//	
//	result = nvs_flash_init();
//	printf("nvs_flash_init: %s\n", esp_err_to_name(result));
//	
//	ip_addr_t dnsServer;
//	ipaddr_aton("192.168.0.10", &dnsServer);  // Replace with your Mac mini DNS
//	
//	dns_setserver(0, &dnsServer);  // Index 0 = primary DNS
//	printf("🔧 Custom DNS server set\n");
	
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
