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

%token IF

%left PLUS MINUS
%left MUL DIV

%union {
	int ival;
}

%type <ival> expr
%type <ival> parenthesis
%type <ival> declaration

%%

input:
	 declaration	{ printf("%d\n", $1); }
;

declaration:
	LBRACE expr RBRACE	{ $$ = $2; }

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
  |	IF parenthesis declaration	{ if ($2) { $$ = $3; } }
  |	parenthesis					{ $$ = $1; }
  |	NUM 						{ $$ = $1; }

parenthesis:
		   LPAREN expr RPAREN { $$ = $2; }

%%

void yyerror(const char *s) {
	fprintf(stderr, "Error: %s\n", s);
}

int main() {
	printf("Enter an arithmetic expression:\n");
	yyparse();
	return 0;
}
