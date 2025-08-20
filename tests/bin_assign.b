putchar(c) {
	extrn syscall;
	syscall(4, 1, &c, 1);
	return;
}

putnbr(n) {
    if (n < 0) {
        putchar('-');
        n = -n;
    }
    if (n >= 10) {
        putnbr(n / 10);
	}
    putchar((n % 10) + '0');
	return;
}

test(n) {
	putnbr(n);
	putchar('\n');
	return;
}

main() {
	auto i;

	i = 0;
	test(i);

	i =+ 4;
	test(i);

	i =- 2;
	test(i);

	i =* 10;
	test(i);

	i =/ 2;
	test(i);

	i =% 7;
	test(i);

	i =| 4;
	test(i);

	i =& 10;
	test(i);

	i === 2;
	test(i);
	i === 3;
	test(i);

	i =!= 0;
	test(i);
	i =!= 1;
	test(i);

	i =<= 2;
	test(i);
	i = 2;
	i =<= 2;
	test(i);

	i =>= 2;
	test(i);
	i = 2;
	i =>= 2;
	test(i);

	i => 0;
	test(i);
	i = 0;
	i => 0;
	test(i);

	i =< 0;
	test(i);
	i = -2;
	i =< 0;
	test(i);

	i =<< 2;
	test(i);

	i =>> 1;
	test(i);

	return (0);
}
