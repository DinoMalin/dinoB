PROG = B
TOKEN = scanner.l
PARSE = parser.y

TOKEN_COMP = lex.yy.c
PARSE_COMP = parser.tab.c

BIN = ./bin
ASM = bin/asm.s
OBJ = bin/obj.o

$(PROG): all

all: $(TOKEN_COMP) $(PARSE_COMP)
	gcc $(TOKEN_COMP) $(PARSE_COMP) -o $(PROG)

$(TOKEN_COMP): $(TOKEN)
	flex $(TOKEN)

$(PARSE_COMP): $(PARSE)
	bison -d $(PARSE)

clean:
	rm -f $(TOKEN_COMP) $(PARSE_COMP) parser.tab.h

compile: $(PROG) $(BIN) $(OBJ)
	ld -m elf_i386 bin/obj.o brt0.o

$(ASM): $(BIN)
	./B < input.dino > bin/asm.s

$(OBJ): $(ASM)
	gcc -c -m32 -x assembler bin/asm.s -o bin/obj.o

$(BIN):
	mkdir -p bin

adjust:
	gcc -c -m32 -x assembler bin/asm.s -o bin/obj.o
	ld -m elf_i386 bin/obj.o brt0.o

