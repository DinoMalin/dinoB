putchar(c) {
	extrn syscall;
	syscall(4, 1, &c, 1);
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

main() {
	putnbr(42);
	putchar('\n');
}
