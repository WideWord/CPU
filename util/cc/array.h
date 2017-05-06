#pragma once

typedef struct CCArray {
	void** data;
	int len;
	int size;
} CCArray;

CCArray* cc_new_array();
void cc_destroy_array(CCArray* array);
void cc_array_ensure_size(CCArray* array, int size);
void cc_array_push(CCArray* array, void* value);
