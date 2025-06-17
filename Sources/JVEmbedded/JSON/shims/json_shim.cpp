//
//  json_shim.cpp
//  JVEmbedded
//
//  Created by Jan Verrept on 11/06/2025.
//


#include "json_shim.h"

extern "C" cJSON *cjson_parse_shim(const char *json) {
	return cJSON_Parse(json);
}

extern "C" void cjson_delete_shim(cJSON *item) {
	cJSON_Delete(item);
}

extern "C" char *cjson_print_unformatted_shim(const cJSON *item) {
	return cJSON_PrintUnformatted(item);  // Caller must free
}

extern "C" const char* cjson_object_get_string_shim(const cJSON* object, const char* key) {
	const cJSON* item = cJSON_GetObjectItem(object, key);
	if (!item || item->type != cJSON_String) return NULL;
	return item->valuestring;
}

extern "C" cJSON *cjson_create_object_shim(void) {
	return cJSON_CreateObject();
}

extern "C" bool cjson_object_set_string_shim(cJSON *object, const char *key, const char *value) {
	cJSON *stringNode = cJSON_CreateString(value);
	if (!stringNode) return false;
	cJSON_ReplaceItemInObject(object, key, stringNode);
	return true;
}
