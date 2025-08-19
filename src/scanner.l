%{
#include "parser.tab.h"
%}

%x COMMENT

%%
";"		return SEMICOLON;
"&"		return AMPERSAND;
"?"		return INTERROGATION;
":"		return COLON;
","		return COMMA;

"+"		return PLUS;
"-"		return MINUS;
"*"		return MUL;
"/"		return DIV;
"%"		return MOD;

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

"++"		return INC;
"--"		return DEC;
"!"			return NOT;
"|"			return OR;

"="			return ASSI;
"=+"		return ASSIADD;
"=-"		return ASSISUB;
"=*"		return ASSIMUL;
"=/"		return ASSIDIV;
"=%"		return ASSIMOD;
"=>>"		return ASSISHR;
"=<<"		return ASSISHL;
"=>="		return ASSISUPEQ;
"=<="		return ASSIINFEQ;
"=>"		return ASSISUP;
"=<"		return ASSIINF;
"==="		return ASSIEQUAL;
"=!="		return ASSIUNEQ;
"=&"		return ASSIAND;
"=|"		return ASSIOR;

"=="		return EQUAL;
"!="		return UNEQUAL;
"<"			return INF;
"<="		return INFEQUAL;
">"			return SUP;
">="		return SUPEQUAL;
"<<"		return LSHIFT;
">>"		return RSHIFT;

'\\*[^']'|'.'	{ yylval.str = strdup(yytext); return CHAR; }
\".*\"			{ yylval.str = strdup(yytext); return STRING; }


[0-9]+					{ yylval.ival = atoi(yytext); return NUM; }
[a-zA-Z][a-zA-Z0-9]*    { yylval.str = strdup(yytext); return IDENT; }
[ \t\r]+	;
"\n"		{ yylineno++; }

"/*"			{ BEGIN(COMMENT); }
<COMMENT>"*/"	{ BEGIN(INITIAL); }
<COMMENT>.		;
<COMMENT>\n		;

"//".*			;

.		{ printf("Error: Unknown caracter: %s\n", yytext); }
%%

int yywrap() {
	return 1;
}
