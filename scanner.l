%{
#include "parser.tab.h"
%}

%x COMMENT

%%
[0-9]+		{ yylval.ival = atoi(yytext); return NUM; }
[a-bA-B]+	{ yylval.str = yytext; return IDENT; } // todo: should be alpha then alpha-digit
[ \t\n\r]+	;

";"		return SEMICOLON;
"&"		return AMPERSAND;
"?"		return INTERROGATION;
":"		return COLON;
","		return COMMA;

"+"		return PLUS;
"-"		return MINUS;
"*"		return MUL;
"/"		return DIV;
"%"		return MODULO;

"("		return LPAREN;
")"		return RPAREN;
"{"		return LBRACE;
"}"		return RBRACE;
"["		return LBRACK;
"]"		return RBRACK;

"auto"		return AUTO;
"extrn"		return EXTRN;
"if"		return IF;
"else"		return ELSE;
"while"		return WHILE;
"goto"		return GOTO;
"return"	return RETURN;

"="			return ASSIGN;
"++"		return INC;
"--"		return DEC;
"!"			return NOT;
"|"			return OR;
"&"			return AND;

"=="		return EQUAL;
"!="		return UNEQUAL;
"<"			return INF;
"<="		return INFEQUAL;
">"			return SUP;
">="		return SUPEQUAL;
"<<"		return LSHIFT;
">>"		return RSHIFT;

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
