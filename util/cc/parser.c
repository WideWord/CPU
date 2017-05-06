#include "parser.h"
#include <stdlib.h>

CCParser* cc_new_parser(CCArray* tokensArray) {
	CCParser* parser = (CCParser*)malloc(sizeof(CCParser));
	parser->types = cc_new_dict();
	parser->tokens = tokensArray;
	parser->position = 0;
	return parser;
}

CCToken* cc_parser_next_token(CCParser* parser) {
	return parser->tokens->data[parser->position++];
}

CCType* cc_parse_type(CCParser* parser, int position) {

}


CCDecl* cc_parse_decl(CCParser* parser) {
	CCType* type = cc_parse_type(parser, position);


}

void cc_parse_program(CCParser* parser) {

}
