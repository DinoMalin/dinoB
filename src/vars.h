typedef struct {
	char *ident;
	int pos;
	bool func;
	bool param;
} variable;

#define ADD_ID(_ident, _func, _param)					\
	{													\
		if (id_count >= MAX_VARS) {						\
			yyerror("too many identifiers");			\
			YYABORT;									\
		} else {										\
			vars[id_count].ident = strdup(_ident);		\
			if (_func) {								\
				vars[id_count].func = true;				\
				vars[id_count].pos = -1;				\
			} else if (_param) {						\
				vars[id_count].param = true;			\
				vars[id_count].pos = (param_count+1)*4;	\
				param_count++;							\
			} else {									\
				vars[id_count].pos = (var_count+1)*4;	\
				var_count++;							\
			}											\
			id_count++;									\
		}												\
	}

#define RESET_STACK()								\
	{												\
		for (int i = 0; i < id_count; i++) {		\
			free(vars[i].ident);					\
		}											\
		id_count = 0;								\
	}

#define RETRIEVE_POS(_ident, pos, param)			\
	{												\
		int i = 0;									\
		for (; i < id_count; i++) {					\
			if (!strcmp(vars[i].ident, _ident)) {	\
				pos = vars[i].pos;					\
				param = vars[i].param;				\
				break;								\
			}										\
		}											\
		if (i == id_count) {						\
			pos = 0;								\
		}											\
	}
