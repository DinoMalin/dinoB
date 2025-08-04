%{
#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

#define MAX_VARS 511

#define ENTER "push ebp\nmov ebp, esp\n"
#define ASSIGNEMENT "%s"					\
					"push eax\n"			\
					"%s"					\
					"pop ebx\n"				\
					"mov [ebx], eax\n"

#define CONST_STR	".section .rodata\n"	\
					".LC%d:\n"				\
					".string %s\n"			\
					".text\n"				\
					"mov eax, LC%d\n"

#define PR_INCREMENT	"%s"					\
						"mov ebx, [eax]\n"		\
						"add ebx, %d\n"			\
						"mov [eax], ebx\n"		\
						"mov eax, ebx\n"

#define PST_INCREMENT	"%s"					\
						"mov ebx, [eax]\n"		\
						"mov ecx, ebx\n"		\
						"add ebx, %d\n"			\
						"mov [eax], ebx\n"		\
						"mov eax, ecx\n"

#define NOT_ASM		"cmp eax, 0\n"			\
					"sete al\n"				\
					"movzx eax, al\n"

#define ACCESS	"%s"						\
				"push eax\n"				\
				"%s"						\
				"pop ebx\n"					\
				"shl eax, 2\n"				\
				"lea eax, [ebx + eax]\n"	\
				"mov eax, [eax]\n"

#define ARITHMETIC	"%s"						\
					"push eax\n"				\
					"%s"						\
					"pop ebx\n"					\
					"%s"


int yylex(void);
void yyerror(const char *s);
extern int yylineno;

int label_count = 0;
int var_count = 0;
int id_count = 0;

typedef struct {
	char *ident;
	int pos;
	bool func;
} variable;

variable vars[MAX_VARS];

#define ADD_ID(_ident, _func)							\
	{													\
		if (id_count >= MAX_VARS) {						\
			yyerror("too many identifiers");			\
			YYABORT;									\
		} else {										\
			vars[id_count].ident = strdup(_ident);		\
			if (_func) {								\
				vars[id_count].func = true;				\
				vars[id_count].pos = -1;				\
			} else {									\
				vars[id_count].pos = (var_count+1)*4;	\
				var_count++;							\
			}											\
			id_count++;									\
		}												\
	}

#define RESET_STACK()								\
	{												\
		for (int i = 0; i < id_count; i++) {		\
			free(vars[i].ident);					\
		}											\
		id_count = 0;								\
	}

#define RETRIEVE_POS(_ident, dst)					\
	{												\
		int i = 0;									\
		for (; i < id_count; i++) {					\
			if (!strcmp(vars[i].ident, _ident)) {	\
				dst = vars[i].pos;					\
				break;								\
			}										\
		}											\
		if (i == id_count) {						\
			yyerror("identifier doesn't exist");	\
			YYABORT;								\
		}											\
	}
	extern int yydebug;
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
%type <ival> incdec
%type <str> unary
%type <str> binary
%type <str> constant
%type <str> assign
%type <str> variables
%type <str> idents
%type <str> extrn

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
  		RESET_STACK();
  		asprintf(&$$, ".globl %s\n%s:\n"ENTER"%s", $1, $1, $4);
		free($4);
	}
  |	IDENT LPAREN idents RPAREN statements {
		RESET_STACK();
  		asprintf(&$$, ".globl %s\n%s:\n"ENTER"%s", $1, $1, $5);
  		free($5); 
  }

statement:
	  LBRACE statements RBRACE       {
	  		asprintf(&$$, "%s", $2);
			free($2);
		}
	| AUTO variables SEMICOLON {
			$$ = $2;
		}
	| EXTRN extrn SEMICOLON  {
			$$ = $2;
		}
	| IDENT COLON statement {
			asprintf(&$$, "%s:\n%s", $1, $3);
			free($1);
			free($3);
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
			asprintf(&$$, "jmp %s\n", $2);
			free($2);
		}
	| RETURN LPAREN rvalue RPAREN SEMICOLON {
			asprintf(&$$, "return(%s);\n", $3); free($3);
		}
	| RETURN SEMICOLON {
			asprintf(&$$, "return;\n");
		}
	| rvalue SEMICOLON {
			$$ = $1;
		}
  	| SEMICOLON { $$ = strdup(""); }
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
			asprintf(&$$, "%s", $2);
			free($2);
		}
	| lvalue assign rvalue      {
			asprintf(&$$, ASSIGNEMENT, $1, $3);
			free($1);
			free($3);
		}
	| incdec lvalue            {
			asprintf(&$$, PR_INCREMENT, $2, $1);
			free($2);
		}
	| lvalue incdec            {
			asprintf(&$$, PST_INCREMENT, $1, $2);
			free($1);
		}
	| unary rvalue              {
			asprintf(&$$, "%s%s", $2, $1);
			free($1);
			free($2);
		}
	| AMPERSAND lvalue          {
			$$ = $2;
		}
	| rvalue binary rvalue      {
			asprintf(&$$, ARITHMETIC, $3, $1, $2);
			free($1);
			free($2);
			free($3);
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
	| constant { $$ = $1; }
	| lvalue                    { $$ = $1; }
;

rvalues:
	rvalue COMMA rvalues {
		asprintf(&$$, "%s, %s", $1, $3); free($1); free($3);
	}
  | rvalue { $$ = $1; }
;

lvalue:
	IDENT { 
			int pos;
			RETRIEVE_POS($1, pos);
			if (pos != -1)
				asprintf(&$$, "lea eax, [ebp - %d]\n", pos);
			else
				asprintf(&$$, "lea eax, \"%s\"\n", $1);
			free($1);
	}
	| MUL rvalue {
			$$ = strdup("mov eax, [eax]\n");
			free($2);
	}
	| rvalue LBRACK rvalue RBRACK {
			asprintf(&$$, ACCESS, $1, $3);
			free($1);
			free($3);
	}
;

incdec:
	INC { $$ = 1; }
  | DEC { $$ = -1; }
;

unary:
	MINUS { $$ = strdup("neg eax"); }
  | NOT   { $$ = strdup(NOT_ASM); }
;

binary:
	OR        	{ asprintf(&$$, "or eax, ebx\n"); }
  | AMPERSAND   { asprintf(&$$, "and eax, ebx\n"); }
  | EQUAL     	{ asprintf(&$$, "cmp eax, ebx\nsete al\nmovzx eax, al\n"); }
  | UNEQUAL   	{ asprintf(&$$, "cmp eax, ebx\nsetne al\nmovzx eax, al\n"); }
  | INF       	{ asprintf(&$$, "cmp eax, ebx\nsetl al\nmovzx eax, al\n"); }
  | INFEQUAL  	{ asprintf(&$$, "cmp eax, ebx\nsetle al\nmovzx eax, al\n"); }
  | SUP       	{ asprintf(&$$, "cmp eax, ebx\nsetg al\nmovzx eax, al\n"); }
  | SUPEQUAL  	{ asprintf(&$$, "cmp eax, ebx\nsetge al\nmovzx eax, al\n"); }
  | LSHIFT    	{ asprintf(&$$, "mov ecx, ebx\nshl eax, cl\n"); }
  | RSHIFT    	{ asprintf(&$$, "mov ecx, ebx\nshr eax, cl\n"); }
  | PLUS      	{ asprintf(&$$, "add eax, ebx\n"); }
  | MINUS     	{ asprintf(&$$, "sub eax, ebx\n"); }
  | MUL       	{ asprintf(&$$, "mul ebx\n"); }
  | DIV       	{ asprintf(&$$, "cdq\nidiv ebx\n"); }
  | MOD			{ asprintf(&$$, "cdq\nidiv ebx\nmov edx, eax\n"); }
;

constant:
	NUM			{
		asprintf(&$$, "mov eax, %d\n", $1);
	}
  |	CHAR		{
  		int c = strcspn($1, "'") != 2 ? $1[1] : $1[2];
  		asprintf(&$$, "mov eax, %d\n", c);
		free($1);
	}
  |	STRING		{
  		asprintf(&$$, CONST_STR, label_count, $1, label_count);
		free($1);
  		label_count++;
	}

/* todo: no assign/binary, separate the tokens */
assign:
	ASSIGN { asprintf(&$$, "="); }
  | ASSIGN binary {
		asprintf(&$$, "=%s", $2); free($2);
	}
;

variables:
	  IDENT						{ ADD_ID($1, false); $$ = strdup(""); free($1); }
	| IDENT NUM                 { ADD_ID($1, false); $$ = strdup(""); free($1); }
	| variables COMMA IDENT     { ADD_ID($3, false); $$ = strdup(""); free($1); }
	| variables COMMA IDENT NUM { ADD_ID($3, false); $$ = strdup(""); free($1); }
;

ivals:
	  NUM COMMA ivals   { asprintf(&$$, "%d, %s", $1, $3); free($3); }
	| NUM               { asprintf(&$$, "%d", $1); }
;

idents:
	  IDENT COMMA idents { asprintf(&$$, "%s, %s", $1, $3); free($1); }
	| IDENT              { asprintf(&$$, "%s", $1); free($1); }

extrn:
	  IDENT COMMA extrn	{ ADD_ID($1, true); $$ = strdup(""); free($1); }
	| IDENT            	{ ADD_ID($1, true); $$ = strdup(""); free($1); }
;

%%

void yyerror(const char *s) {
	fprintf(stderr, "Error l.%d: %s\n", yylineno, s);
}

int main() {
	yydebug = 0;
	printf("Enter some B code:\n");
	yyparse();
	return 0;
}
