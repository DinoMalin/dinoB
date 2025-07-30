%{
#include "parser.tab.h"
%}

%%
[0-9]+		{ yylval.ival = atoi(yytext); return NUM; }
[ \t\n\r]+	;

"+"		return PLUS;
"-"		return MINUS;
"*"		return MUL;
"/"		return DIV;
"("		return LPAREN;
")"		return RPAREN;
"{"		return LBRACE;
"}"		return RBRACE;

.		{ printf("Unknown caracter: %s\n", yytext); }
%%

int yywrap() {
	return 1;
}
