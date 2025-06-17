//
//  json.h
//  JVEmbedded
//
//  Created by Jan Verrept on 11/06/2025.
//

#pragma once
#include "cJSON.h"

extern "C" {

cJSON *cjson_parse_shim(const char *json);

void cjson_delete_shim(cJSON *item);

char *cjson_print_unformatted_shim(const cJSON *item);

const char* cjson_object_get_string_shim(const cJSON* object, const char* key);

cJSON *cjson_create_object_shim(void);

bool cjson_object_set_string_shim(cJSON *object, const char *key, const char *value);

}
