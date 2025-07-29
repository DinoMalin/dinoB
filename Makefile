PROG = arithmetic
TOKEN = scanner.l
PARSE = parser.y

TOKEN_COMP = lex.yy.c
PARSE_COMP = parser.tab.c

$(PROG): all

all: $(TOKEN_COMP) $(PARSE_COMP)
	gcc $(TOKEN_COMP) $(PARSE_COMP) -o $(PROG)

$(TOKEN_COMP): $(TOKEN)
	flex $(TOKEN)

$(PARSE_COMP): $(PARSE)
	bison -d $(PARSE)

clean:
	rm -f $(TOKEN_COMP) $(PARSE_COMP) parser.tab.h
