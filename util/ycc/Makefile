
ycc: lex.yy.c y.tab.c y.tab.h main.c
	gcc lex.yy.c y.tab.c main.c -o ycc

lex.yy.c: lexer.l
	lex lexer.l

y.tab.c y.tab.h: parser.y
	yacc -d parser.y


