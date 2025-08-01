%{
#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define ENTER "push ebp\nmov ebp, esp\n"
	
int yylex(void);
void yyerror(const char *s);
extern int yylineno;
%}

%debug
%union {
	int ival;
	char *str;
}

%token <ival> NUM
%token <str> IDENT
%token <str> CHAR
%token <str> STRING
%token PLUS MINUS MUL DIV MOD

%token LPAREN RPAREN
%token LBRACE RBRACE
%token LBRACK RBRACK

%token SEMICOLON AMPERSAND INTERROGATION COLON COMMA
%token AUTO EXTRN IF ELSE WHILE GOTO RETURN
%token ASSIGN INC DEC NOT OR
%token EQUAL UNEQUAL INF INFEQUAL SUP SUPEQUAL
%token LSHIFT RSHIFT

%left PLUS MINUS
%left MUL DIV

%type <str> definition
%type <str> ivals
%type <str> statement
%type <str> statements
%type <str> condition
%type <str> rvalue
%type <str> lvalue
%type <str> rvalues
%type <str> incdec
%type <str> unary
%type <str> binary
%type <str> constant
%type <str> assign
%type <str> variables
%type <str> idents

%%

program:
	definition			{ printf("%s", $1); free($1); }
  |	definition program	{ printf("%s", $1); free($1); }

definition:
	IDENT SEMICOLON	{ asprintf(&$$, "%s;\n", $1); }
  |	IDENT ivals SEMICOLON { asprintf(&$$, "%s %s;", $1, $2); free($2); }

  |	IDENT LBRACK RBRACK SEMICOLON	{ asprintf(&$$, "%s[];\n", $1); }
  |	IDENT LBRACK RBRACK ivals SEMICOLON	{ asprintf(&$$, "%s [] %s;\n", $1, $4);
  		free($4);
	}

  |	IDENT LBRACK NUM RBRACK SEMICOLON	{ asprintf(&$$, "%s [%d];\n", $1, $3); }
  |	IDENT LBRACK NUM RBRACK ivals SEMICOLON { asprintf(&$$, "%s [%d] %s;", $1, $3, $5);
		free($5);	
	}

  |	IDENT LPAREN RPAREN statements {
  		asprintf(&$$, ".globl %s\n%s:\n"ENTER"%s", $1, $1, $4);
		free($4);
	}
  |	IDENT LPAREN idents RPAREN statements {
  		asprintf(&$$, ".globl %s\n%s:\n"ENTER"%s", $1, $1, $5);
  		free($5); 
  }

statement:
	  LBRACE statements RBRACE       { asprintf(&$$, "{\n%s}\n", $2); free($2); }
	| AUTO variables SEMICOLON {
			asprintf(&$$, "auto %s;\n", $2); free($2);
		}
	| EXTRN idents SEMICOLON  {
			asprintf(&$$, "extrn %s;\n", $2); free($2);
		}
	| IDENT COLON statement {
			asprintf(&$$, "%s:\n%s", $1, $3); free($3);
		}
	| IF condition statement {
			asprintf(&$$, "if%s\n%s", $2, $3); free($2); free($3);
		}
	| IF condition statement ELSE statement {
			asprintf(&$$, "if%s\n%s\nelse\n%s", $2, $3, $5);
			free($2); free($3); free($5);
		}
	| WHILE condition statement {
			asprintf(&$$, "while%s\n%s", $2, $3); free($2); free($3);
		}
	| GOTO rvalue SEMICOLON {
			asprintf(&$$, "jmp %s\n", $2); free($2);
		}
	| RETURN LPAREN rvalue RPAREN SEMICOLON {
			asprintf(&$$, "return(%s);\n", $3); free($3);
		}
	| RETURN SEMICOLON {
			asprintf(&$$, "return;\n");
		}
	| rvalue SEMICOLON {
			asprintf(&$$, "%s;\n", $1); free($1);
		}
  	| SEMICOLON { $$ = strdup(";\n"); }
;

statements:
		  					{ $$ = strdup(""); }
  |	statement statements	{ asprintf(&$$, "%s%s", $1, $2); free($1); free($2); }

condition:
	LPAREN rvalue RPAREN {
		asprintf(&$$, "(%s)", $2); free($2);
	}
;

rvalue:
	  LPAREN rvalue RPAREN {
			asprintf(&$$, "(%s)", $2); free($2);
		}
	| lvalue                    { $$ = $1; }
	| lvalue assign rvalue      {
			asprintf(&$$, "%s = %s", $1, $3); free($1); free($3);
		}
	| incdec lvalue            {
			asprintf(&$$, "%s%s", $1, $2); free($1); free($2);
		}
	| lvalue incdec            {
			asprintf(&$$, "%s%s", $1, $2); free($1); free($2);
		}
	| unary rvalue              {
			asprintf(&$$, "%s%s", $1, $2); free($1); free($2);
		}
	| AMPERSAND lvalue          {
			asprintf(&$$, "&%s", $2); free($2);
		}
	| rvalue binary rvalue      {
			asprintf(&$$, "(%s %s %s)", $1, $2, $3); free($1); free($2); free($3);
		}
	| rvalue INTERROGATION rvalue COLON rvalue {
			asprintf(&$$, "(%s ? %s : %s)", $1, $3, $5); free($1); free($3); free($5);
		}
	| rvalue LPAREN rvalues RPAREN {
			asprintf(&$$, "%s(%s)", $1, $3); free($1); free($3);
		}
	| rvalue LPAREN RPAREN {
			asprintf(&$$, "%s()", $1); free($1);
		}
	| constant { asprintf(&$$, "%s", $1); free($1); }
;

rvalues:
	rvalue COMMA rvalues {
		asprintf(&$$, "%s, %s", $1, $3); free($1); free($3);
	}
  | rvalue { $$ = $1; }
;

lvalue:
	  IDENT { $$ = $1; }
	| MUL rvalue {
			asprintf(&$$, "*%s", $2); free($2);
		}
	| rvalue LBRACK rvalue RBRACK {
			asprintf(&$$, "%s[%s]", $1, $3); free($1); free($3);
		}
;

incdec:
	INC { asprintf(&$$, "++"); }
  | DEC { asprintf(&$$, "--"); }
;

unary:
	MINUS { asprintf(&$$, "-"); }
  | NOT   { asprintf(&$$, "!"); }
;

binary:
	OR        	{ asprintf(&$$, "||"); }
  | AMPERSAND   { asprintf(&$$, "&&"); }
  | EQUAL     	{ asprintf(&$$, "=="); }
  | UNEQUAL   	{ asprintf(&$$, "!="); }
  | INF       	{ asprintf(&$$, "<"); }
  | INFEQUAL  	{ asprintf(&$$, "<="); }
  | SUP       	{ asprintf(&$$, ">"); }
  | SUPEQUAL  	{ asprintf(&$$, ">="); }
  | LSHIFT    	{ asprintf(&$$, "<<"); }
  | RSHIFT    	{ asprintf(&$$, ">>"); }
  | PLUS      	{ asprintf(&$$, "+"); }
  | MINUS     	{ asprintf(&$$, "-"); }
  | MUL       	{ asprintf(&$$, "*"); }
  | DIV       	{ asprintf(&$$, "/"); }
  | MOD			{ asprintf(&$$, "%%"); }
;

constant:
	NUM			{ asprintf(&$$, "%d", $1); }
  |	CHAR		{ asprintf(&$$, "%s", $1); free($1); }
  |	STRING		{ asprintf(&$$, "%s", $1); free($1); }

assign:
	ASSIGN { asprintf(&$$, "="); }
  | ASSIGN binary {
		asprintf(&$$, "=%s", $2); free($2);
	}
;

variables:
	  IDENT						{ $$ = $1; }
	| IDENT NUM                 {
			asprintf(&$$, "%s %d", $1, $2); free($1);
		}
	| IDENT COMMA variables     {
			asprintf(&$$, "%s, %s", $1, $3); free($1); free($3);
		}
	| IDENT COMMA NUM variables {
			asprintf(&$$, "%s, %d %s", $1, $3, $4); free($1); free($4);
		}
;

ivals:
	  NUM COMMA ivals   { asprintf(&$$, "%d, %s", $1, $3); free($3); }
	| NUM               { asprintf(&$$, "%d", $1); }
;

idents:
	  IDENT COMMA idents { asprintf(&$$, "%s, %s", $1, $3); free($3); }
	| IDENT              { asprintf(&$$, "%s", $1); }
;

%%

void yyerror(const char *s) {
	fprintf(stderr, "Error l.%d: %s\n", yylineno, s);
}

int main() {
	printf("Enter an arithmetic expression:\n");
	yyparse();
	return 0;
}
