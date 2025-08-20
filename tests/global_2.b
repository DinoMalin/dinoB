arr[] 100, 105, 110, 111, 10, 0;

char(str, index) {
	return (*(str+index));
}

putstr(str) {
	extrn syscall;
	auto i;
	i = 0;
	while (str[i]) {
		syscall(4, 1, (str+i*4), 1);
		i++;
	}
	return (0);
}

main() {
	putstr(&arr);
	return (0);
}
