%{
#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

#include "asm.h"
#include "vars.h"

#define MAX_VARS 511

int yylex(void);
void yyerror(const char *s);
extern int yylineno;

int label_count = 0;
int var_count = 0;
int param_count = 1;
int id_count = 0;
int call_size = 0;
bool ret = false;

variable vars[MAX_VARS];

extern int yydebug;

char* repeat_string(const char* str, int times) {
    if (times <= 0 || str == NULL) return NULL;

    size_t len = strlen(str);
    size_t total_len = len * times;

    // +1 for null terminator
    char* result = malloc(total_len + 1);
    if (!result) return NULL;

    char* ptr = result;
    for (int i = 0; i < times; i++) {
        memcpy(ptr, str, len);
        ptr += len;
    }

    result[total_len] = '\0';
    return result;
}

char get_char(char *str) {
	if (*str == '\\') {
		str++;
		switch (*str) {
			case 'n':	return '\n';
			case 't':	return '\t';
			case 'r':	return '\r';
			case '\\':	return '\\';
			case '0':	return '\0';
			default: 
				return *str;
		}
	}
	return *str;
}
%}

%debug

%code requires {
	typedef struct {
		int nb;
		char *code;
	} param_t;
}

%union {
	int ival;
	char *str;
	param_t param;
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
%token ASSI ASSIADD ASSISUB ASSIMUL ASSIDIV ASSIMOD ASSISHR ASSISHL ASSIAND
%token ASSISUPEQ ASSIINFEQ ASSISUP ASSIINF ASSIEQUAL ASSIUNEQ ASSIOR
%token INC DEC NOT OR
%token EQUAL UNEQUAL INF INFEQUAL SUP SUPEQUAL
%token LSHIFT RSHIFT

%left PLUS MINUS
%left MUL DIV

%type <str> definition
%type <str> numbers
%type <str> statement
%type <str> statements
%type <str> condition
%type <str> rvalue
%type <str> lvalue
%type <param> params
%type <ival> incdec
%type <str> unary
%type <str> binary
%type <str> constant
%type <str> assign
%type <str> variables
%type <str> function_params
%type <str> extrn

%nonassoc IFX
%nonassoc ELSE
%%

program:
	definition			{ printf("%s", $1); free($1); }
  |	program definition	{ printf("%s", $2); free($2); }
;

definition:
	IDENT SEMICOLON	{
		asprintf(&$$, BSS, $1, $1, 4);
		free($1);
	}
  |	IDENT NUM SEMICOLON {
		char *nb; asprintf(&nb, "%d", $2);
  		asprintf(&$$, DATA, $1, $1, nb);
		free($1);
	}
  |	IDENT LBRACK RBRACK numbers SEMICOLON	{
  		asprintf(&$$, DATA, $1, $1, $4);
  		free($1);
  		free($4);
	}
  |	IDENT LBRACK NUM RBRACK SEMICOLON	{
		asprintf(&$$, BSS, $1, $1, $3*4);
		free($1);
	}
  |	IDENT LBRACK NUM RBRACK numbers SEMICOLON {
		char *padding = repeat_string(", 0", $3-(strlen($5)+2)/3);
		char *init; asprintf(&init, "%s%s", $5, padding);
  		asprintf(&$$, DATA, $1, $1, init);
		free($1);
		free($5);
		free(init);
		free(padding);
	}
  |	IDENT LPAREN RPAREN statements {
  		RESET_STACK();
		asprintf(&$$, FUNCTION, $1, $1, $1, $4);
		if (!ret) {
			asprintf(&$$, "%sleave\nret\n", $$);
		}
		ret = false;
		free($1);
		free($4);
	}
  |	IDENT LPAREN function_params RPAREN statement {
		RESET_STACK();
		asprintf(&$$, FUNCTION, $1, $1, $1, $5);
		if (!ret) {
			asprintf(&$$, "%sleave\nret\n", $$);
		}
		ret = false;
  		free($1); 
  		free($3); 
  		free($5); 
  }
;

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
	| IF condition statement %prec IFX {
			asprintf(&$$, IF_ASM, $2, label_count, $3, label_count);
			label_count++;
			free($2);
			free($3);
		}
	| IF condition statement ELSE statement {
			asprintf(&$$, IFELSE_ASM,
				$2, label_count, $3, label_count+1, label_count, $5, label_count+1
			);
			label_count += 2;
			free($2);
			free($3);
			free($5);
		}
	| WHILE condition statement {
			asprintf(&$$, WHILE_ASM,
				label_count, $2, label_count+1, $3, label_count, label_count+1
			);
			label_count += 2;
			free($2);
			free($3);
		}
	| GOTO rvalue SEMICOLON {
			asprintf(&$$, "%sjmp eax\n", $2);
			free($2);
		}
	| RETURN LPAREN rvalue RPAREN SEMICOLON {
			ret = true;
			asprintf(&$$, "%sleave\nret\n", $3);
			free($3);
		}
	| RETURN SEMICOLON {
			ret = true;
			$$ = strdup("leave\nret\n");
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
		asprintf(&$$, "%scmp eax, 0\n", $2);
		free($2);
	}
;

rvalue:
	  LPAREN rvalue RPAREN {
			$$ = $2;
		}
	| assign {
			$$ = $1;
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
	| rvalue LPAREN params RPAREN {
			asprintf(&$$, "%s%scall eax\nadd esp, %d\n", $3.code, $1, $3.nb);
			call_size = 0;
			free($1);
			free($3.code);
		}
	| rvalue LPAREN RPAREN {
			asprintf(&$$, "%s\ncall eax\nadd esp, %d\n", $1);
			free($1);
		}
	| constant { $$ = $1; }
	| lvalue	{
		asprintf(&$$, "%smov eax, [eax]\n", $1);
		free($1);
	}
;

params:
	params COMMA rvalue {
  		$$.nb = $1.nb + 4;
		asprintf(&$$.code, "%spush eax\n%s", $3, $1.code);
		free($1.code);
		free($3);
	}
  | rvalue {
  		$$.nb = 4;
		asprintf(&$$.code, "%spush eax\n", $1);
		free($1);
	}
;

lvalue:
	IDENT { 
			int pos = 0;
			bool param = false;
			RETRIEVE_POS($1, pos, param);
			if (!param && pos && pos != -1)
				asprintf(&$$, "lea eax, [ebp - %d]\n", pos);
			else if (param && pos != -1)
				asprintf(&$$, "lea eax, [ebp + %d]\n", pos);
			else
				asprintf(&$$, "lea eax, %s\n", $1);
			free($1);
	}
	| MUL rvalue {
			asprintf(&$$, "%s", $2);
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
	MINUS { $$ = strdup("neg eax\n"); }
  | NOT   { $$ = strdup(NOT_ASM); }
;

binary:
	OR        	{ $$ = strdup(OR_ASM); }
  | AMPERSAND   { $$ = strdup(AND_ASM); }
  | EQUAL     	{ $$ = strdup(EQUAL_ASM); }
  | UNEQUAL   	{ $$ = strdup(UNEQ_ASM); }
  | INF       	{ $$ = strdup(INF_ASM); }
  | INFEQUAL  	{ $$ = strdup(INFEQ_ASM); }
  | SUP       	{ $$ = strdup(SUP_ASM); }
  | SUPEQUAL  	{ $$ = strdup(SUPEQ_ASM); }
  | LSHIFT    	{ $$ = strdup(LSHIFT_ASM); }
  | RSHIFT    	{ $$ = strdup(RSHIFT_ASM); }
  | PLUS      	{ $$ = strdup(ADD_ASM); }
  | MINUS     	{ $$ = strdup(SUB_ASM); }
  | MUL       	{ $$ = strdup(MUL_ASM); }
  | DIV       	{ $$ = strdup(DIV_ASM); }
  | MOD			{ $$ = strdup(MOD_ASM); }
;

constant:
	NUM			{
		asprintf(&$$, "mov eax, %d\n", $1);
	}
  |	CHAR		{
  		int c = get_char($1+1);
  		asprintf(&$$, "mov eax, %d\n", c);
		free($1);
	}
  |	STRING		{
  		asprintf(&$$, CONST_STR, label_count, $1, label_count);
		free($1);
  		label_count++;
	}
;

assign:
	lvalue ASSI rvalue      {
			asprintf(&$$, ASSIGNEMENT, $1, $3); free($1); free($3);
		}
	| lvalue ASSIADD rvalue {
			asprintf(&$$, BIN_ASSIGN(ADD_ASM), $3, $1); free($1); free($3);
		}
	| lvalue ASSISUB rvalue {
			asprintf(&$$, BIN_ASSIGN(SUB_ASM), $3, $1); free($1); free($3);
		}
	| lvalue ASSIMUL rvalue {
			asprintf(&$$, BIN_ASSIGN(MUL_ASM), $3, $1); free($1); free($3);
		}
	| lvalue ASSIDIV rvalue {
			asprintf(&$$, BIN_ASSIGN(DIV_ASM), $3, $1); free($1); free($3);
		}
	| lvalue ASSIMOD rvalue {
			asprintf(&$$, BIN_ASSIGN(MOD_ASM), $3, $1); free($1); free($3);
		}
	| lvalue ASSIAND rvalue {
			asprintf(&$$, BIN_ASSIGN(AND_ASM), $3, $1); free($1); free($3);
		}
	| lvalue ASSIOR rvalue {
			asprintf(&$$, BIN_ASSIGN(OR_ASM), $3, $1); free($1); free($3);
		}
	| lvalue ASSIEQUAL rvalue {
			asprintf(&$$, BIN_ASSIGN(EQUAL_ASM), $3, $1); free($1); free($3);
		}
	| lvalue ASSIUNEQ rvalue {
			asprintf(&$$, BIN_ASSIGN(UNEQ_ASM), $3, $1); free($1); free($3);
		}
	| lvalue ASSIINF rvalue {
			asprintf(&$$, BIN_ASSIGN(INF_ASM), $3, $1); free($1); free($3);
		}
	| lvalue ASSIINFEQ rvalue {
			asprintf(&$$, BIN_ASSIGN(INFEQ_ASM), $3, $1); free($1); free($3);
		}
	| lvalue ASSISUP rvalue {
			asprintf(&$$, BIN_ASSIGN(SUP_ASM), $3, $1); free($1); free($3);
		}
	| lvalue ASSISUPEQ rvalue {
			asprintf(&$$, BIN_ASSIGN(SUPEQ_ASM), $3, $1); free($1); free($3);
		}
	| lvalue ASSISHR rvalue {
			asprintf(&$$, BIN_ASSIGN(RSHIFT_ASM), $3, $1); free($1); free($3);
		}
	| lvalue ASSISHL rvalue {
			asprintf(&$$, BIN_ASSIGN(LSHIFT_ASM), $3, $1); free($1); free($3);
		}
;

variables:
	IDENT	{
			ADD_ID($1, false, false);
	  		$$ = strdup("sub esp, 4\n");
			free($1);
	}
	| IDENT NUM	{
			ADD_ID($1, false, false);
	  		$$ = strdup("sub esp, 4\n");
			free($1);
	}
	| variables COMMA IDENT     {
			ADD_ID($3, false, false);
			asprintf(&$$, "%ssub esp, 4\n", $1);
			free($1);
			free($3);
	}
	| variables COMMA IDENT NUM {
			ADD_ID($3, false, false);
			asprintf(&$$, "%ssub esp, 4\n", $1);
			free($1);
			free($3);
	}
;

function_params:
	IDENT	{
	  		ADD_ID($1, false, true);
			$$ = strdup("");
			free($1);
	}
	| function_params COMMA IDENT	{
			ADD_ID($3, false, true);
			$$ = strdup("");
			free($1);
	}
;

numbers:
	  NUM COMMA numbers { asprintf(&$$, "%d, %s", $1, $3); free($3); }
	| NUM               { asprintf(&$$, "%d", $1); }
;

extrn:
	IDENT COMMA extrn	{
	  	ADD_ID($1, true, false);
	  	asprintf(&$$, ".extern %s\n", $1);
		free($1);
	}
	| IDENT            	{
		ADD_ID($1, true, false);
		asprintf(&$$, ".extern %s\n", $1);
		free($1);
	}
;

%%

void yyerror(const char *s) {
	fprintf(stderr, "Error l.%d: %s\n", yylineno, s);
}

int main() {
	yydebug = 0;
	printf(".intel_syntax noprefix\n");
	yyparse();
	return 0;
}
