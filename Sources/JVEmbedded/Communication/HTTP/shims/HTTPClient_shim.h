//
//  HTTPClient_shim.h
//  JVEmbedded
//
//  Created by Jan Verrept on 21/06/2025.
//

#pragma once
#include "esp_http_client.h"
#include <cstddef>

extern "C" {


typedef enum {
	HTTPRES_OK = 0,
	HTTPRES_OK_NOT_MODIFIED,
	HTTPRES_NOT_FOUND,
	HTTPRES_BAD_REQUEST,
	HTTPRES_SERVER_ERROR,
	HTTPRES_REDIRECTED,
	HTTPRES_LOST_CONNECTION
} HTTPResult;

typedef size_t HTTP_read_callback(void *ptr, size_t size, size_t nmemb, void *stream);

typedef struct {
	char *date;
	int size;
	int status;
	void *data;
} HTTP_ctx;

// Primary shimmed function
HTTPResult http_get_shim(HTTP_ctx* http, const char* url, const char* user, const char* pass, HTTP_read_callback* cb);

}
