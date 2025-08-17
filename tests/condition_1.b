main() {
	auto i;
	i = 42;
	if (i) {
		syscall(4, 1, "dino\n", 5);
	}
	return (0);
}
