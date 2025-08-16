char(str, index) {
	return (*(str+index));
}

strlen(str) {
	auto i;
	i = 0;
	while (char(str, i)) {
		i++;
	}
	return (i);
}

putstr(str) {
	extrn syscall;
	syscall(4, 1, str, strlen(str));
	return (0);
}

main() {
	putstr("dino\n");
	return(0);
}
