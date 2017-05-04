#pragma once

#include "array.h"

typedef enum {
	CC_TYPE_VOID,
	CC_TYPE_INT,
	CC_TYPE_UINT,
	CC_TYPE_PTR,
	CC_TYPE_ARRAY,
	CC_TYPE_CONST,
	CC_TYPE_FUNC
} CCTypeKind;

typedef struct {
	int size;
	CCTypeKind kind;
	CCType* subtype;
} CCType;

typedef struct CCFuncType {
	CCType base;
	CCType* resultType;
	CCArray* argsTypes;
}

CCType* cc_new_type(CCTypeKind kind, int size);
void cc_destroy_type(CCType* type);


typedef enum {
	CCFuncDeclKind
} CCDeclKind;

typedef struct {

} CCDecl;