#pragma once
#include <stdbool.h>
#include <stdio.h>

typedef struct CCLexer {
	FILE* stream;
	char* value;
	size_t value_len;
	size_t value_size;
	long int lexem_start_in_stream;
	int line;
	int lexem_start_line;
	char* filename;
} CCLexer;

typedef enum CCTokenType {
	CCT_ERROR,
	CCT_NONE,
	CCT_DEC_CONST,
	CCT_HEX_CONST,
	CCT_TERM,
	CCT_ID,
	CCT_STRING_CONST,
	CCT_CHAR_CONST,
	CCT_PPC,
	CCT_EOF
} CCTokenType;

typedef struct CCToken {
	char* value;
	CCTokenType type;
} CCToken;

CCLexer* cc_new_lexer(FILE* stream, char* filename); 
void cc_destroy_lexer(CCLexer* lexer);
CCToken* cc_lexer_next_token(CCLexer* lexer);
void cc_destroy_token(CCToken* token);
bool cc_token_is_term(CCToken* token, const char* term);
const char* cc_token_type_name(CCTokenType type);

