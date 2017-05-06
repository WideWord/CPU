#include "lexer.h"
#include <stdio.h>

int main(int argc, char** argv) {
	
	CCLexer* lexer = cc_new_lexer(fopen(argv[1], "r"), argv[1]);

	for (;;) {
		CCToken* token = cc_lexer_next_token(lexer);
		if (token->value != NULL) {
			printf("%s : '%s'\n", cc_token_type_name(token->type), token->value);
		} else {
			printf("%s\n", cc_token_type_name(token->type));
		}	
		if (token->type == CCT_EOF || token->type == CCT_ERROR) {
			cc_destroy_token(token);
			return 0;
		} else {
			cc_destroy_token(token);
		}
	}


}