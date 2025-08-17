main() {
	auto i;
	i = 0;
	if (i) {
		syscall(4, 1, "dino\n", 5);
	}
	return (0);
}
