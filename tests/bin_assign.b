main() {
	extrn syscall;
	auto i;
	i = 0;
	while (i < 4) {
		syscall(4, 1, "dino\n", 5);
		i =+ 1;
	}
	return (0);
}
