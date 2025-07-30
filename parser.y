%{
#include <stdio.h>
#include <stdlib.h>
	
int yylex(void);
void yyerror(const char *s);
%}

%token <ival> NUM
%token PLUS MINUS MUL DIV
%token LPAREN RPAREN
%token LBRACE RBRACE

%left PLUS MINUS
%left MUL DIV

%union {
	int ival;
}

%type <ival> expr

%%

input:
	LBRACE expr RBRACE		{ printf("%d\n", $2); }
;

expr:
	expr PLUS expr	{ $$ = $1 + $3; }
  |	expr MINUS expr	{ $$ = $1 - $3; }
  |	expr MUL expr	{ $$ = $1 * $3; }
  |	expr DIV expr	{ 
  						if ($3 == 0) {
							yyerror("division by zero");
							$$ = 0;
						} else {
							$$ = $1 / $3;
						}
					}
  |	LPAREN expr RPAREN { $$ = $2; }
  |	NUM 					{ $$ = $1; }

%%

void yyerror(const char *s) {
	fprintf(stderr, "Error: %s\n", s);
}

int main() {
	printf("Enter an arithmetic expression:\n");
	yyparse();
	return 0;
}
