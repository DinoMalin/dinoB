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
					".section .text\n"		\
					"mov eax, .LC%d\n"

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

#define IF_ASM		"%s"			\
					"je .LC%d\n"	\
					"%s"			\
					".LC%d:\n"

#define IFELSE_ASM	"%s"			\
					"je .LC%d\n"	\
					"%s"			\
					"jmp .LC%d\n"	\
					".LC%d:\n"		\
					"%s"			\
					".LC%d:\n"

#define WHILE_ASM	".LC%d:\n"		\
					"%s"			\
					"je .LC%d\n"	\
					"%s"			\
					"je .LC%d\n"	\
					".LC%d:\n"		 

#define BSS			".section .bss\n"	\
					".global %s\n"		\
					"%s: .skip %d\n"

#define DATA		".section .data\n"	\
					".global %s\n"		\
					"%s: .long %s\n"

int yylex(void);
void yyerror(const char *s);
extern int yylineno;

int label_count = 0;
int var_count = 0;
int param_count = 1;
int id_count = 0;
int call_size = 0;

typedef struct {
	char *ident;
	int pos;
	bool func;
	bool param;
} variable;

variable vars[MAX_VARS];

#define ADD_ID(_ident, _func, _param)					\
	{													\
		if (id_count >= MAX_VARS) {						\
			yyerror("too many identifiers");			\
			YYABORT;									\
		} else {										\
			vars[id_count].ident = strdup(_ident);		\
			if (_func) {								\
				vars[id_count].func = true;				\
				vars[id_count].pos = -1;				\
			} else if (_param) {						\
				vars[id_count].param = true;			\
				vars[id_count].pos = (param_count+1)*4;	\
				param_count++;							\
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

#define RETRIEVE_POS(_ident, pos, param)			\
	{												\
		int i = 0;									\
		for (; i < id_count; i++) {					\
			if (!strcmp(vars[i].ident, _ident)) {	\
				pos = vars[i].pos;					\
				param = vars[i].param;				\
				break;								\
			}										\
		}											\
		if (i == id_count) {						\
			pos = 0;								\
		}											\
	}
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
%type <str> numbers
%type <str> statement
%type <str> statements
%type <str> condition
%type <str> rvalue
%type <str> lvalue
%type <str> params
%type <ival> incdec
%type <str> unary
%type <str> binary
%type <str> constant
%type <str> assign
%type <str> variables
%type <str> function_params
%type <str> extrn

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
  |	IDENT numbers SEMICOLON { asprintf(&$$, "%s %s;", $1, $2); free($2); }
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
  		asprintf(&$$, ".section .text\n.global %s\n%s:\n"ENTER"%s", $1, $1, $4);
		free($1);
		free($4);
	}
  |	IDENT LPAREN function_params RPAREN statements {
		RESET_STACK();
  		asprintf(&$$, ".section .text\n.global %s\n%s:\n"ENTER"%s", $1, $1, $5);
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
	| IF condition statement {
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
			asprintf(&$$, "%sleave\nret\n", $3);
			free($3);
		}
	| RETURN SEMICOLON {
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
	| rvalue LPAREN params RPAREN {
			asprintf(&$$, "%s%scall eax\nadd esp, %d\n", $3, $1, call_size);
			call_size = 0;
			free($1);
			free($3);
		}
	| rvalue LPAREN RPAREN {
			asprintf(&$$, "%s\ncall eax\nadd esp, %d\n", $1, call_size);
			call_size = 0;
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
		asprintf(&$$, "%spush eax\n%s", $3, $1);
		call_size += 4;
		free($3);
	}
  | rvalue {
		asprintf(&$$, "%spush eax\n", $1);
		call_size += 4;
		free($1);
	}
;

lvalue:
	IDENT { 
			int pos;
			bool param;
			RETRIEVE_POS($1, pos, param);
			if (!param && pos && pos != -1)
				asprintf(&$$, "lea eax, [ebp - %d]\n", pos);
			else if (param)
				asprintf(&$$, "lea eax, [ebp + %d]\n", pos);
			else
				asprintf(&$$, "lea eax, [%s]\n", $1);
			free($1);
	}
	| MUL rvalue {
			asprintf(&$$, "%smov eax, [eax]\n", $2);
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
	OR        	{ $$ = strdup("or eax, ebx\n"); }
  | AMPERSAND   { $$ = strdup("and eax, ebx\n"); }
  | EQUAL     	{ $$ = strdup("cmp eax, ebx\nsete al\nmovzx eax, al\n"); }
  | UNEQUAL   	{ $$ = strdup("cmp eax, ebx\nsetne al\nmovzx eax, al\n"); }
  | INF       	{ $$ = strdup("cmp eax, ebx\nsetl al\nmovzx eax, al\n"); }
  | INFEQUAL  	{ $$ = strdup("cmp eax, ebx\nsetle al\nmovzx eax, al\n"); }
  | SUP       	{ $$ = strdup("cmp eax, ebx\nsetg al\nmovzx eax, al\n"); }
  | SUPEQUAL  	{ $$ = strdup("cmp eax, ebx\nsetge al\nmovzx eax, al\n"); }
  | LSHIFT    	{ $$ = strdup("mov ecx, ebx\nshl eax, cl\n"); }
  | RSHIFT    	{ $$ = strdup("mov ecx, ebx\nshr eax, cl\n"); }
  | PLUS      	{ $$ = strdup("add eax, ebx\n"); }
  | MINUS     	{ $$ = strdup("sub eax, ebx\n"); }
  | MUL       	{ $$ = strdup("mul ebx\n"); }
  | DIV       	{ $$ = strdup("cdq\nidiv ebx\n"); }
  | MOD			{ $$ = strdup("cdq\nidiv ebx\nmov edx, eax\n"); }
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
;

/* todo: no assign/binary, separate the tokens */
assign:
	ASSIGN { asprintf(&$$, "="); }
  | ASSIGN binary {
		asprintf(&$$, "=%s", $2); free($2);
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
