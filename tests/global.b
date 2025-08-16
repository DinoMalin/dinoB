star 42;
newline 10;

main() {
	syscall(4, 1, &star, 1);
	syscall(4, 1, &newline, 1);
	return (0);
}
