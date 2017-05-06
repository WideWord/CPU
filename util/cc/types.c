#include "types.h"
#include <stdlib.h>

CCType* cc_new_type(CCTypeKind kind, int size) {
	CCType* type;
	if (kind == CC_TYPE_FUNC) {
		type = (CCType*)malloc(CCFuncType);
	} else {
		type = (CCType*)malloc(CCType);
	}
	type->kind = kind;
	type->size = size;
	type->subtype = NULL;
}

void cc_destroy_type(CCType* type) {
	if (type == NULL) return;
	if (type->kind == CC_TYPE_FUNC) {
		CCFuncType* ftype = (CCFuncType*)type;
		cc_destroy_type(ftype->resultType);
		for (int i = 0; i < ftype->argsTypes->len; ++i) {
			CCType* argType = (CCType*)ftype->argsTypes->data[i];
			cc_destroy_type(argType);
		}
		cc_destroy_array(ftype->argsTypes);
	}
	cc_destroy_type(type->subtype);
	free(type);
}


