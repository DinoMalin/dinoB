putstr(str, len) {
	extrn syscall;
	syscall(4, 1, str, len);
	return (0);
}

main() {
	putstr("dino\n", 5);
	return (0);
}
