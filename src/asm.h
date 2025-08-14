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
