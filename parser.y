%{
#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
	
int yylex(void);
void yyerror(const char *s);
extern int yylineno;
%}

%union {
	int ival;
	char *str;
}

%token <ival> NUM
%token <str> IDENT
%token PLUS MINUS MUL DIV MOD

%token LPAREN RPAREN
%token LBRACE RBRACE
%token LBRACK RBRACK

%token SEMICOLON AMPERSAND INTERROGATION COLON COMMA
%token AUTO EXTRN IF ELSE WHILE GOTO RETURN
%token ASSIGN INC DEC NOT OR
%token EQUAL UNEQUAL INF INFEQUAL SUP SUPEQUAL
%token LSHIFT RSHIFT
%token CHAR STRING

%left PLUS MINUS
%left MUL DIV

%type <str> definition
%type <str> ivals
%type <str> params
%type <str> statement
%type <str> statements
%type <str> condition
%type <str> rvalue
%type <str> lvalue
%type <str> rvalues
%type <str> incdec
%type <str> unary
%type <str> binary
%type <str> assign
%type <str> variables
%type <str> idents

// faudra free des trucs
%%

program:
	definition			{ printf("%s\n", $1); free($1); }
  |	definition program	{ printf("%s\n", $1); free($1); } // this probably need to change

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

  |	IDENT LPAREN RPAREN statements { asprintf(&$$, "%s()\n%s", $1, $4); free($4); }
  |	IDENT LPAREN params RPAREN statements { asprintf(&$$, "%s(%s)\n%s", $1, $3, $5);
  		free($5); 
  }

ivals:
	  NUM COMMA ivals   { asprintf(&$$, "%d, %s", $1, $3); free($3); }
	| NUM               { asprintf(&$$, "%d", $1); }
;

params:
	  IDENT COMMA params { asprintf(&$$, "%s, %s", $1, $3); free($3); }
	| IDENT              { asprintf(&$$, "%s", $1); }
;

statement:
	  LBRACE statements RBRACE       { asprintf(&$$, "{\n%s}", $2); free($2); }
	| AUTO variables SEMICOLON statements {
			asprintf(&$$, "auto %s;\n%s", $2, $4); free($2); free($4);
		}
	| EXTRN idents SEMICOLON statements {
			asprintf(&$$, "extern %s;\n%s", $2, $4); free($2); free($4);
		}
	| IDENT COLON statements {
			asprintf(&$$, "%s:\n%s", $1, $3); free($3);
		}
	| IF condition statements {
			asprintf(&$$, "if%s\n%s", $2, $3); free($2); free($3);
		}
	| IF condition statements ELSE statements {
			asprintf(&$$, "if%s\n%s\nelse\n%s", $2, $3, $5);
			free($2); free($3); free($5);
		}
	| WHILE condition statements {
			asprintf(&$$, "while%s\n%s", $2, $3); free($2); free($3);
		}
	| GOTO rvalue SEMICOLON {
			asprintf(&$$, "goto %s;", $2); free($2);
		}
	| RETURN LPAREN rvalue RPAREN SEMICOLON {
			asprintf(&$$, "return(%s);", $3); free($3);
		}
	| RETURN SEMICOLON {
			asprintf(&$$, "return;");
		}
	| rvalue SEMICOLON {
			asprintf(&$$, "%s;", $1); free($1);
		}
;

statements:
		  					{ $$ = strdup(""); }
  |	statement statements	{ asprintf(&$$, "%s\n%s", $1, $2); free($1); free($2); }

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
	| NUM {
			asprintf(&$$, "%d", $1);
		}
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

idents:
	  IDENT         { $$ = $1; }
	| IDENT idents	{
			asprintf(&$$, "%s %s", $1, $2); free($1); free($2);
		}
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
