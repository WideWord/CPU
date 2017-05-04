#include "dict.h"
#include <stdlib.h>
#include <string.h>

CCDictChain* cc_new_dict_chain(const char* key, void* value) {
	CCDictChain* chain = (CCDictChain*)malloc(sizeof(CCDictChain));
	chain->key = strdup(key);
	chain->value = value;
	chain->next = NULL;
	return chain;
}

void cc_destroy_dict_chain(CCDictChain* chain) {
	if (chain->next != NULL) {
		cc_destroy_dict_chain(chain->next);
	}
	free(chain->key);
	free(chain);
}

CCDict* cc_new_dict() {
	CCDict* dict = (CCDict*)malloc(sizeof(CCDict));
	for (int i = 0; i < CC_DICT_TABLE_SIZE; ++i) {
		dict->table[i] = NULL;
	}
}

void cc_destroy_dict(CCDict* dict) {
	for (int i = 0; i < CC_DICT_TABLE_SIZE; ++i) {
		if (dict->table[i] != NULL) {
			cc_destroy_dict_chain(dict->table[i]);
		}
	}
	free(dict);
}

int cc_dict_hash(const char* key) {
	unsigned hash = 0;
	while (*key != '\0') {
		hash = *(key++) + hash * 31;
	}
	return (int)(hash % CC_DICT_TABLE_SIZE);
}

void cc_dict_set(CCDict* dict, const char* key, void* value) {
	int hash = cc_dict_hash(key);
	CCDictChain** chain = &(dict->table[hash]);
	for (;;) {
		if (*chain == NULL) {
			*chain = cc_new_dict_chain(key, value);
		} else if (strcmp(key, (*chain)->key) == 0) {
			(*chain)->value = value;
		} else {
			chain = &(*chain)->next;
		}
	}
}

void* cc_dict_get(CCDict* dict, const char* key) {
	int hash = cc_dict_hash(key);
	CCDictChain* chain = &(dict->table[hash]);
	for (;;) {
		if (chain == NULL) {
			return NULL;
		} else if (strcmp(key, chain->key) == 0) {
			return chain->value;
		} else {
			chain = chain->next;
		}
	}
}

void* cc_dict_remove(CCDict* dict, const char* key) {
	int hash = cc_dict_hash(key);
	CCDictChain** chain = &(dict->table[hash]);
	for (;;) {
		if (*chain == NULL) {
			return NULL;
		} else if (strcmp(key, (*chain)->key) == 0) {
			void* value = (*chain)->value;
			CCDictChain* chain_to_remove = *chain;
			*chain = (*chain)->next;
			chain_to_remove->next = NULL;
			cc_destroy_dict_chain(chain_to_remove);
			return value;
		} else {
			chain = &(*chain)->next;
		}
	}
}
