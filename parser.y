%{
#include <stdio.h>
#include <stdlib.h>
	
int yylex(void);
void yyerror(const char *s);
%}

%token <ival> NUM
%token IDENT
%token PLUS MINUS MUL DIV

%token LPAREN RPAREN
%token LBRACE RBRACE
%token LBRACK RBRACK

%token SEMICOLON AMPERSAND INTERROGATION COLON COMMA
%token AUTO EXTRN IF WHILE GOTO RETURN
%token ASSIGN INC DEC NOT OR AND
%token EQUAL UNEQUAL INF INFEQUAL SUP SUPEQUAL
%token LSHIFT RSHIFT

%left PLUS MINUS
%left MUL DIV

%union {
	int ival;
	char *str;
}

%type <str> ident
%type <str> definition

%%

program:
	definition			{ printf("%s\n", $1); }
	definition program	{ printf("%s\n", $1); }

definition:
	IDENT SEMICOLON
  |	IDENT LBRACK NUM RBRACK SEMICOLON
  |	IDENT LBRACK NUM RBRACK ivals SEMICOLON
  |	IDENT LPAREN RPAREN statement
  |	IDENT LPAREN ivals RPAREN statement

ivals:
	NUM COMMA ivals
	NUM COMMA

statement:
	LBRACE statement RBRACE
	LBRACE statement statement RBRACE
	AUTO variables SEMICOLON statement
	EXTRN idents SEMICOLON statement
	IDENT COLON statement
	IF condition statement
	IF condition ELSE statement
	WHILE condition statement
	GOTO rvalue SEMICOLON
	RETURN LPAREN rvalue RPAREN SEMICOLON
	RETURN SEMICOLON
	rvalue SEMICOLON

condition:
	   LPAREN rvalue RPAREN

rvalue:
	  LPAREN rvalue RPAREN
	  lvalue
	  lvalue ASSIGN rvalue
	  inc-dec lvalue
	  lvalue inc-dec
	  unary rvalue
	  AMPERSAND lvalue
	  rvalue binary rvalue
	  rvalue INTERROGATION rvalue COLON rvalue
	  rvalue LPAREN rvalues RPAREN
	  rvalue LPAREN RPAREN
	  NUM

rvalues:
	rvalue COMMA rvalues
  |	rvalue

inc-dec:
	INC
  | DEC

unary:
	MINUS
  |	NOT

assign:
	EQUAL
  |	EQUAL binary

binary:
	OR
  |	AND
  |	EQUAL
  |	UNEQUAL
  |	INF
  |	INFEQUAL
  |	SUP
  |	SUPEQUAL
  |	LSHIFT
  |	RSHIFT
  |	PLUS
  |	MINUS
  |	MODULO
  |	MUL
  |	DIV

lvalue:

variables:
	IDENT
  |	IDENT NUM
  |	IDENT COMMA variables
  |	IDENT COMMA NUM variables

idents:
	IDENT
  |	IDENT idents
	




%%

void yyerror(const char *s) {
	fprintf(stderr, "Error: %s\n", s);
}

int main() {
	printf("Enter an arithmetic expression:\n");
	yyparse();
	return 0;
}
