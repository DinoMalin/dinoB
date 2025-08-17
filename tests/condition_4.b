main() {
	auto i;
	i = 0;
	if (i) {
		syscall(4, 1, "dino\n", 5);
	} else {
		syscall(4, 1, "not dino\n", 9);
	}
	return (0);
}
