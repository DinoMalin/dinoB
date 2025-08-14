#!/bin/bash

if [ ! -f ./B ]; then
	make
fi

compile() {
	mkdir -p tests/bin
	code=tests/"$1".b
	asm=tests/bin/"$1".s
	obj=tests/bin/"$1".o
	res=tests/bin/test_"$1"

	./B < $code > $asm
	gcc -c -m32 -x assembler $asm -o $obj
	ld -m elf_i386 $obj brt0.o -o $res
}

for i in tests/*.b; do
	pure=$(echo $i | sed 's/^tests\///' | sed 's/.b$//')
	exp="tests/${pure}.exp"
	compile $pure

	res="tests/bin/res"
	test=$(./tests/bin/test_$pure > $res)
	diff=$(diff $exp $res)

	if [ -n "$diff" ]; then
		echo $pure failed:
		echo $diff
		exit 1
	fi
done
