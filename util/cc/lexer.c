#include "lexer.h"
#include <stdlib.h>
#include <string.h>

CCToken* cc_new_token(CCTokenType type, char* data) {
	CCToken* res = (CCToken*)malloc(sizeof(CCToken));
	res->type = type;
	res->value = data;
	return res;
}

void cc_destroy_token(CCToken* token) {
	if (token->value) {
		free(token->value);
	}
	free(token);
}



CCLexer* cc_new_lexer(FILE* stream, char* filename) {
	CCLexer* res = (CCLexer*)malloc(sizeof(CCLexer));
	res->stream = stream;
	res->value = NULL;
	res->value_size = 0;
	res->value_len = 0;
	res->lexem_start_in_stream = ftell(stream);
	res->line = 0;
	res->lexem_start_line = 1;
	res->filename = filename;
	ungetc('\n', stream);
	return res;
}

void cc_destroy_lexer(CCLexer* lexer) {
	if (lexer->value != NULL) {
		free(lexer->value);
	}
	free(lexer);
}

void cc_lexer_ensure_value_size(CCLexer* lexer, int new_len);

char cc_lexer_getc(CCLexer* lexer) {
	int ch = fgetc(lexer->stream);
	if (ch == EOF) {
		return '\0';
	} else {
		if (ch == '\n') {
			lexer->line += 1;
		}
		cc_lexer_ensure_value_size(lexer, lexer->value_len + 1);
		lexer->value[lexer->value_len++] = ch;
		return ch;
	}
}

void cc_lexer_ensure_value_size(CCLexer* lexer, int new_len) {
	if (new_len > lexer->value_size) {
		if (lexer->value == NULL) {
			int initial_size = 12;
			lexer->value = (char*)malloc(sizeof(char) * initial_size);
			lexer->value_size = initial_size;
		} else {
			int size = lexer->value_size * 2;
			lexer->value = (char*)realloc(lexer->value, sizeof(char) * size);
			lexer->value_size = size;
		}
	}
}

void cc_lexer_ungetc(CCLexer* lexer) {
	char ch = lexer->value[--lexer->value_len];
	if (ch == '\n') {
		lexer->line -= 1;
	}
	ungetc(ch, lexer->stream);
}

CCToken* cc_lexer_accept(CCLexer* lexer, CCTokenType type) {
	cc_lexer_ensure_value_size(lexer, lexer->value_len + 1);
	lexer->value[lexer->value_len] = '\0';
	CCToken* res = cc_new_token(type, lexer->value);
	lexer->value = NULL;
	lexer->value_len = 0;
	lexer->value_size = 0;
	lexer->lexem_start_in_stream = ftell(lexer->stream);
	lexer->lexem_start_line = lexer->line;
	return res;
}

void cc_lexer_skip(CCLexer* lexer) {
	free(lexer->value);
	lexer->value = NULL;
	lexer->value_len = 0;
	lexer->value_size = 0;
	lexer->lexem_start_in_stream = ftell(lexer->stream);
	lexer->lexem_start_line = lexer->line;
}


void cc_lexer_reject(CCLexer* lexer) {
	free(lexer->value);
	lexer->value = NULL;
	lexer->value_len = 0;
	lexer->value_size = 0;
	fseek(lexer->stream, lexer->lexem_start_in_stream, SEEK_SET);
	lexer->line = lexer->lexem_start_line;
}

CCToken* cc_lexer_error(CCLexer* lexer, const char* msg) {
	fprintf(stderr, "error: %s:%d %s\n", lexer->filename, lexer->lexem_start_line, msg);
	return cc_new_token(CCT_ERROR, NULL);
}

bool cc_is_dec_digit(char ch) {
	return ch >= '0' && ch <= '9';
}

bool cc_is_hex_digit(char ch) {
	return (ch >= 'a' && ch <= 'h') || (ch >= 'A' && ch <= 'H') || cc_is_dec_digit(ch);
}

bool cc_is_one_of(char ch, const char* list) {
	while(*list != '\0') {
		if (ch == *list) return true;
		list += sizeof(char);
	}
	return false;
}

bool cc_is_letter(char ch) {
	return (ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z') || cc_is_one_of(ch, "_$");
}



char cc_unescape(char escape) {
	switch (escape) {
		case 'n': return '\n';
		case 't': return '\t';
		case 'r': return '\r';
		case '0': return '\0';
		default: return escape;
	}
}

CCToken* cc_lexer_next_token(CCLexer* lexer) {
	char ch = cc_lexer_getc(lexer);

	

	for (;;) {
		if (ch == '\n') {
			for (;;) {
				ch = cc_lexer_getc(lexer);
				if (!cc_is_one_of(ch, " \t\n")) {
					if (ch == '#') {
						lexer->value_len = 0;
						for (;;) {
							ch = cc_lexer_getc(lexer);
							if (ch == '\n' || ch == '\0') { 
								cc_lexer_ungetc(lexer);
								return cc_lexer_accept(lexer, CCT_PPC);
							}
						}
					} else {
						cc_lexer_ungetc(lexer);
						cc_lexer_skip(lexer);
						ch = cc_lexer_getc(lexer);
						break;
					}
				}
			}
		} else if (ch == '\0') {
			return cc_lexer_accept(lexer, CCT_EOF);
		} else if (cc_is_one_of(ch, " \t\r")) {
			cc_lexer_skip(lexer);
			ch = cc_lexer_getc(lexer);
		} else if (ch == '/') {
			ch = cc_lexer_getc(lexer);
			if (ch == '/') {
				for (;;) {
					ch = cc_lexer_getc(lexer);
					if (ch == '\n' || ch == '\0') { 
						cc_lexer_skip(lexer);
						ch = cc_lexer_getc(lexer);
						break;
					}
				}
			} else if (ch == '*') {
				char last = '\0';
				for (;;) {
					ch = cc_lexer_getc(lexer);
					if (ch == '/' && last == '*') { 
						cc_lexer_skip(lexer);
						ch = cc_lexer_getc(lexer);
						break;
					} else if (ch == '\0') {
						return cc_lexer_error(lexer, "no matching */ for comment");
					}
					last = ch;
				}
			} else {
				cc_lexer_reject(lexer);
				ch = cc_lexer_getc(lexer);
				break;
			}
		} else break;
	}

	if (cc_is_one_of(ch, "()[]{},.:?;\\")) {
		return cc_lexer_accept(lexer, CCT_TERM);
	}

	if (ch == '-') {
		ch = cc_lexer_getc(lexer);
		if (ch == '>') {
			return cc_lexer_accept(lexer, CCT_TERM);
		} else {
			cc_lexer_reject(lexer);
			ch = cc_lexer_getc(lexer);
		}
	}

	if (cc_is_one_of(ch, "><+-*/=!^|&%")) {
		ch = cc_lexer_getc(lexer);
		if (ch == '=') {
			return cc_lexer_accept(lexer, CCT_TERM);
		} else {
			cc_lexer_ungetc(lexer);
			return cc_lexer_accept(lexer, CCT_TERM);
		}
	}

	if (ch == '0') {
		ch = cc_lexer_getc(lexer);
		if (ch == 'x') {
			bool firstDigit = true;
			lexer->value_len = 0;
			for (;;) {
				ch = cc_lexer_getc(lexer);
				if (!cc_is_hex_digit(ch)) {
					if (firstDigit || cc_is_letter(ch)) {
						return cc_lexer_error(lexer, "invalid hex constant");
					} else {
						cc_lexer_ungetc(lexer);
						return cc_lexer_accept(lexer, CCT_HEX_CONST);
					}	
				}
				firstDigit = false;
			}
		} else {
			cc_lexer_reject(lexer);
			ch = cc_lexer_getc(lexer);
		}
	}

	if (cc_is_dec_digit(ch)) { // decimal constant
		for (;;) {
			ch = cc_lexer_getc(lexer);
			if (!cc_is_dec_digit(ch)) {
				if (cc_is_letter(ch)) {
					return cc_lexer_error(lexer, "invalid dec constant");
				} else {
					cc_lexer_ungetc(lexer);
					return cc_lexer_accept(lexer, CCT_DEC_CONST);
				}
			}
		}
	}

	if (cc_is_letter(ch)) {
		for (;;) {
			ch = cc_lexer_getc(lexer);
			if (!cc_is_letter(ch) && !cc_is_dec_digit(ch)) {
				cc_lexer_ungetc(lexer);


				CCToken* token = cc_lexer_accept(lexer, CCT_ID);

				char* terms[] = { "return", "while", "for", "do", "typedef", "struct", "enum", "union" };
				for (int i = 0; i < sizeof(terms) / sizeof(*terms); ++i) {
					if (strcmp(token->value, terms[i]) == 0) {
						token->type = CCT_TERM;
						break;
					}
				}
				return token;
			}
		}
	}

	if (ch == '"') {
		char last = ch;
		for (;;) {
			ch = cc_lexer_getc(lexer);
			if (ch == '"' && last != '\\') {
				CCToken* token = cc_lexer_accept(lexer, CCT_STRING_CONST);
				char* old_value = token->value;
				char* new_value = (char*)malloc(strlen(old_value));
				char* p = old_value + 1;
				char* n = new_value;
				char oldp = *old_value;
				for (;;) {
					if (oldp == '\\') {
						*(n++) = cc_unescape(*p);
					} else if (*p == '"') {
						break;
					} else if (*p != '\\') {
						*(n++) = *p;
					}
					oldp = *(p++);
				}
				*n = '\0';
				token->value = new_value;
				free(old_value);
				return token;
			} else if (ch == '\0') {
				return cc_lexer_error(lexer, "no matching \" for string");
			}
			last = ch;
		}
	}

	if (ch == '\'') {
		char last = ch;
		for (;;) {
			ch = cc_lexer_getc(lexer);
			if (ch == '\'' && last != '\\') {
				CCToken* token = cc_lexer_accept(lexer, CCT_CHAR_CONST);
				char* old_value = token->value;
				char* new_value = (char*)malloc(strlen(old_value));
				char* p = old_value + 1;
				char* n = new_value;
				char oldp = *old_value;
				for (;;) {
					if (oldp == '\\') {
						*(n++) = cc_unescape(*p);
					} else if (*p == '\'') {
						break;
					} else if (*p != '\\') {
						*(n++) = *p;
					}
					oldp = *(p++);
				}
				*n = '\0';
				token->value = new_value;
				free(old_value);
				return token;
			} else if (ch == '\0') {
				return cc_lexer_error(lexer, "no matching ' for char constant");
			}
			last = ch;
		}
	}

	return cc_lexer_error(lexer, "bad character");

}

bool cc_token_is_term(CCToken* token, const char* term) {
	if (token->type == CCT_TERM) {
		return strcmp(token->term, term) == 0;
	} else {
		return false;
	}
}

const char* cc_token_type_name(CCTokenType type) {
	switch (type) {
		case CCT_ERROR: return "error";
		case CCT_NONE: return "none";
		case CCT_DEC_CONST: return "dec constant";
		case CCT_HEX_CONST: return "hex constant";
		case CCT_TERM: return "term";
		case CCT_ID: return "id";
		case CCT_STRING_CONST: return "string const";
		case CCT_CHAR_CONST: return "char const";
		case CCT_PPC: return "preprocessor";
		case CCT_EOF: return "eof";
	}
}

