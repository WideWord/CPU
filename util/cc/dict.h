#pragma once

typedef struct CCDictChain CCDictChain;

typedef struct CCDictChain {
	const char* key;
	void* value;
	CCDictChain* next;
} CCDictChain;

#define CC_DICT_TABLE_SIZE 101

typedef struct CCDict {
	CCDictChain* table[CC_DICT_TABLE_SIZE];
} CCDict;

CCDict* cc_new_dict();
void cc_destroy_dict(CCDict* dict);
int cc_dict_hash(const char* key);
void cc_dict_set(CCDict* dict, const char* key, void* value);
void* cc_dict_get(CCDict* dict, const char* key);
void* cc_dict_remove(CCDict* dict, const char* key);
