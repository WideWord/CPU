#include "array.h"

CCArray* cc_new_array() {
	CCArray* array = (CCArray*)malloc(sizeof(CCArray));
	array->data = NULL;
	array->size = 0;
	array->len = 0;
	return array;
}

void cc_destroy_array(CCArray* array) {
	if (array->data != NULL) {
		free(array->data);
	}
	free(array);
}

void cc_array_ensure_size(CCArray* array, int size) {
	if (array->data == NULL) {
		array->data = malloc(size * sizeof(void*));
		array->size = size;
	} else if (array->size < size) {
		int new_size = size * 2;
		while (new_size < size) new_size *= 2;
		array->data = (void**)realloc(array->data, new_size * sizeof(void*));
		array->size = new_size;
	}
}

void cc_array_push(CCArray* array, void* value) {
	cc_array_ensure_size(array->len + 1);
	array->data[array->len++] = value;
}
