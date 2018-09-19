static char *ad_def[] = {
	"A+XCRY",
	"A+ANDCB",
	"A+AND",
	"A*2",
	"04",
	"OR+ANDCB",
	"A+B",
	"A+OR",
	"10",
	"A-B-1",
	"12",
	"13",
	"14",
	"ANDCB-1",
	"AND-1",
	"A-1",
	"SETCA",
	"ORC",
	"ORCA",
	"1S",
	"ANDC",
	"SETCB",
	"EQV",
	"ORCB",
	"ANDCA",
	"XOR",
	"B",
	"OR",
	"0S",
	"ANDCB",
	"AND",	// CRY A.B#0
	"A",	// CRY A#0
	"A+1",
	"41",
	"42",
	"A*2+1",
	"OR+1",
	"45",
	"A+B+1",
	"47",
	"ORCB+1",
	"A-B",
	"AND+ORCB",
	"A+ORCB",
	"XCRY-1",
	"55",
	"56",
	"57",
	"CRY A EQ -1",
	"61",
	"62",
	"63",
	"64",
	"65",
	"66",
	"67",
	"70",
	"CRY A GE B",
	"72",
	"73",
	"74",
	"75",
	"76",
	"77"
};

static char *ada_def[] = {
	"AR",
	"ARX",
	"MQ",
	"PC",
	"0S",
	"0S",
	"0S",
	"0S"
};

static char *adb_def[] = {
	"FM",
	"BR*2",
	"BR",
	"AR*4"
};

static char *ar_def[] = {
	"AR",	// "ARMM"
	"CACHE",
	"AD",
	"EBUS",
	"SH",
	"AD*2",
	"ADX",
	"AD*.25"
};

static char *arx_def[] = {
	"ARX",
	"CACHE",
	"AD",
	"MQ",
	"SH",
	"ADX*2",
	"ADX",
	"ADX*.25"
};

static char *br_def[] = {
	"BR",
	"AR"
};

static char *brx_def[] = {
	"BRX",
	"ARX"
};

// MQ is ambiguous

static char *fm_def[] = {
	"AC0",
	"AC1",
	"XR",
	"VMA",
	"AC2",
	"AC3",
	"AC4",
	"#B#"
};

static char *scad_def[] = {
	"A",
	"A-B-1",
	"A+B",
	"A-1",
	"A+1",
	"A-B",
	"OR",
	"AND"
};

static char *scada_def[] = {
	"FE",
	"AR0-5",
	"AR EXP",
	"#",
	"0S",
	"0S",
	"0S",
	"0S"
};

static char *scadb_def[] = {
	"SC",
	"AR6-11",
	"AR0-8",
	"#"
};

static char *sc_def[] = {
	"SC|SCAD",
	"FE|AR SHIFT"
};

static char *fe_def[] = {
	"FE",
	"SCAD"
};

static char *sh_def[] = {
	"SHIFT AR!ARX",
	"AR",
	"ARX",
	"AR SWAP"
};

static char *armm_def[] = {
	"#",
	"EXP_SIGN",
	"SCAD EXP",
	"SCAD POS"
};

static char *vma_def[] = {
	"VMA",
	"PC",
	"PC+1",
	"AD"
};

static char *t_def[] = {
	"2T",
	"3T",
	"4T",
	"5T"
};

static char *mem_def[] = {
	"NOP",
	"ARL IND",
	"MB WAIT",
	"SEC 0",
	"A RD",
	"B WRITE",
	"FETCH",
	"REG FUNC",
	"A IND",	// AD FUNC
	"BYTE IND",	// EA CALC
	"LOAD AR",
	"LOAD ARX",
	"AD FUNC",	// RW
	"BYTE RD",	// RPW
	"WRITE",
	"RPW"		// IFET
};

static char *cond_skip_def[] = {
	"NOP",
	"LD AR0-8",
	"LD AR9-17",
	"LD AR18-35",
	"AR CLR",
	"ARX CLR",
	"ARL IND",
	"REG CTL",
	"FM WRITE",
	"PCF_#",
	"FE SHRT",
	"AD FLAGS",
	"LOAD IR",
	"SPEC INSTR",
	"SR_#",
	"SEL VMA",
	"DIAG FUNC",
	"EBOX STATE",
	"EBOX CTL",
	"MBOX CTL",
	"24",
	"25",
	"26",
	"27",
	"VMA_#",
	"VMA_#+TRAP",
	"VMA_#+MODE",
	"VMA_#+AR32-35",
	"VMA_#+PI*2",
	"VMA DEC",
	"VMA INC",
	"LD VMA HELD",

	"SPARE",
	"EVEN PAR",
	"BR0",
	"ARX0",
	"AR18",
	"AR0",
	"AC#0",
	"SC0",
	"SC .LT. 36",
	"SCAD0",
	"SCAD#0",
	"ADX0",
	"AD CRY0",
	"AD0",
	"AD#0",
	"SPARE",
	"FETCH",
	"KERNEL",
	"USER",
	"PUBLIC",
	"RPW REF",
	"PI CYCLE",
	"-EBUS GRANT",
	"-EBUS XFER",
	"INTRPT",
	"-START",
	"RUN",
	"IO LEGAL",
	"P!S XCT",
	"EBOX PF",
	"AC REF",
	"-MTR REQ"
};

static char *disp_spec_def[] = {
	// DISP
	"DIAG",
	"DRAM J",
	"DRAM A RD",
	"RETURN",
	"PG FAIL",
	"SR",
	"NICOND",
	"SH0-3",
	// SPEC
	"NOP",
	"INH CRY18",
	"MQ SHIFT",
	"SCM ALT",
	"CLR FPD",
	"LOAD PC",
	"XCRY AR0",
	"GEN CRY18",
	"SEC HOLD",	// STACK UPDATE
	"CALL",
	"ARL IND",
	"MTR CTL",
	"FLAG CTL",
	"SAVE FLAGS",
	"SP MEM CYCLE",
	"AD LONG"
	// DISP
	"MUL",
	"DIV",
	"SIGNS",
	"DRAM B",
	"BYTE",
	"NORM",
	"EA MOD",
	"EA TYPE"
};
