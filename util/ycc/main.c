#include "y.tab.h"
#include <stdio.h>

int main(int argc, char** argv) {

	if (argc < 2) {
		printf("Usage: ycc [file.c]");
		return 0;
	}

	yyin = fopen(argv[1], "r");

	yparse();

	fclose(yyin);

	return 0;
}