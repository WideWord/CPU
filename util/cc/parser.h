#pragma once

#include "dict.h"

typedef struct CCParser {
	CCDict* types;
	CCArray* tokens;
	int position;
} CCParser;

CCParser* cc_new_parser();
void cc_parse_program(CCParser* parser);





