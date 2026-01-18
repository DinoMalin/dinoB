main() {
	auto i, a;
	a = &i;
	*a = 42;
	syscall(4, 1, a, 1);
	*a = 10;
	syscall(4, 1, a, 1);
}
