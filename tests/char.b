main(ac, av, env)
{
	extrn syscall;
	auto a;
	a = 'a';
	auto newline;
	newline = '\n';

	syscall(4, 1, &a, 1);
	syscall(4, 1, &newline, 1);

	return (0);
}
