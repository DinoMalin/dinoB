%{
#include "parser.tab.h"
%}

%x COMMENT

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

"/*"			{ BEGIN(COMMENT); }
<COMMENT>"*/"	{ BEGIN(INITIAL); }
<COMMENT>.		;
<COMMENT>\n		;

"//".*			;

.		{ printf("Unknown caracter: %s\n", yytext); }
%%

int yywrap() {
	return 1;
}
