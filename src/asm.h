#define FUNCTION	".section .text\n"		\
					".global %s\n"			\
					"%s:\n"					\
					".long %s + 4\n"		\
					"push ebp\n"			\
					"mov ebp, esp\n"		\
					"%s"

#define ASSIGNEMENT "%s"					\
					"push eax\n"			\
					"%s"					\
					"pop ebx\n"				\
					"mov [ebx], eax\n"

#define CONST_STR	".section .rodata\n"	\
					".LC%d:\n"				\
					".string %s\n"			\
					".section .text\n"		\
					"lea eax, [.LC%d]\n"

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
					"jmp .LC%d\n"	\
					".LC%d:\n"		 

#define RSHIFT_ASM		"mov ecx, ebx\nshr eax, cl\n"
#define LSHIFT_ASM		"mov ecx, ebx\nshl eax, cl\n"
#define SUPEQ_ASM	"cmp eax, ebx\nsetge al\nmovzx eax, al\n"
#define SUP_ASM			"cmp eax, ebx\nsetg al\nmovzx eax, al\n"
#define INFEQ_ASM	"cmp eax, ebx\nsetle al\nmovzx eax, al\n"
#define INF_ASM			"cmp eax, ebx\nsetl al\nmovzx eax, al\n"
#define UNEQ_ASM		"cmp eax, ebx\nsetne al\nmovzx eax, al\n"
#define EQUAL_ASM		"cmp eax, ebx\nsete al\nmovzx eax, al\n"
#define AND_ASM			"and eax, ebx\n"
#define OR_ASM			"or eax, ebx\n"
#define ADD_ASM			"add eax, ebx\n"
#define SUB_ASM			"sub eax, ebx\n"
#define MUL_ASM			"mul ebx\n"
#define DIV_ASM			"cdq\nidiv ebx\n"
#define MOD_ASM			"cdq\nidiv ebx\nmov eax, edx\n"

#define BIN_ASSIGN(bin)	"%spush eax\n%smov ecx, eax\nmov eax, [eax]\npop ebx\n"bin"mov [ecx], eax\n"

#define BSS			".section .bss\n"	\
					".global %s\n"		\
					"%s: .skip %d\n"

#define DATA		".section .data\n"	\
					".global %s\n"		\
					"%s: .long %s\n"
