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
	auto l;
	l = strlen(str);
	syscall(4, 1, str, l);
	return (0);
}

main() {
	putstr("dino\n");
	return(0);
}
