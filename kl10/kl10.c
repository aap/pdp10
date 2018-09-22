#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <stdarg.h>
#include <assert.h>

#define nil NULL
typedef unsigned int uint;
typedef uint64_t word;	/* A PDP-10 word (36 bits) */
typedef uint32_t hword;	/* A PDP-10 half word (18 bits) */
typedef uint32_t aword;	/* A PDP-10 address word (23 bits) */

#define M3 07ULL
#define M4 017ULL
#define M6 077ULL
#define M8 0377ULL
#define M9 0777ULL
#define M10 01777ULL
#define M11 03777ULL
#define M18 0000000777777ULL
#define R18 M18
#define L18 0777777000000ULL
#define L20 03777777000000ULL
#define M23 0000037777777ULL
#define MSEC 037000000ULL
#define M24 0000077777777ULL
#define M36 0777777777777ULL
#define M38 03777777777777ULL
#define S36 0400000000000ULL
#define SXT36 (~M36)
#define FB0 0400000000000ULL
#define FB1 0200000000000ULL
#define FB2 0100000000000ULL
#define FB3 0040000000000ULL
#define FB4 0020000000000ULL
#define FB5 0010000000000ULL
#define FB6 0004000000000ULL
#define FB7 0002000000000ULL
#define FB8 0001000000000ULL
#define FB9 0000400000000ULL
#define FB10 0000200000000ULL
#define FB11 0000100000000ULL
#define FB12 0000040000000ULL
#define FB18 0000000400000ULL
#define MPOS 0770000000000ULL
#define MSZ 0007700000000ULL

#define LT(w) ((w) & L18)
#define RT(w) ((w) & R18)

// TODO: figure out which is more efficient
#define SETMASK(l, r, m) l = ((l)&~(m) | (r)&(m))
//#define SETMASK(l, r, m) l ^= ((l)^(r)) & (m)

enum
{
	/* COND field */
	COND_ARLL_LOAD = 01,
	COND_ARLR_LOAD = 02,
	COND_ARR_LOAD = 03,
	COND_AR_CLR = 04,
	COND_ARX_CLR = 05,
	COND_ARL_IND = 06,
	COND_REG_CTL = 07,

	COND_FM_WRITE = 010,
	COND_PCF_FM_NUM = 011,
	COND_FE_SHRT = 012,
	COND_AD_FLAGS = 013,
	COND_LOAD_IR = 014,
	COND_SPEC_INSTR = 015,
	COND_SR_FM_NUM = 016,
	COND_SEL_VMA = 017,

	COND_DIAG_FUNC = 020,
	COND_EBOX_STATE = 021,
	COND_EBUS_CTL = 022,
	COND_MBOX_CTL = 023,

	COND_VMA_FM_NUM = 030,
	COND_VMA_FM_NUM_TRAP = 031,
	COND_VMA_FM_NUM_MODE = 032,
	COND_VMA_FM_NUM_AR32_35 = 033,
	COND_VMA_FM_NUM_PI_2 = 034,
	COND_VMA_DEC = 035,
	COND_VMA_INC = 036,
	COND_LOAD_VMA_HELD = 037,

	/* SPEC field */
	DISP_AREAD = 002,
	DISP_RETURN = 003,
	DISP_NICOND = 006,
	DISP_MUL = 030,
	DISP_DIV = 031,
	DISP_NORM = 035,
	DISP_EA_MOD = 036,

	SPEC_INH_CRY_18 = 011,
	SPEC_MQ_SHIFT = 012,
	SPEC_SCM_ALT = 013,
	SPEC_CLR_FPD = 014,
	SPEC_LOAD_PC = 015,
	SPEC_XCRY_AR0 = 016,
	SPEC_GEN_CRY_18 = 017,
	SPEC_STACK_UPDATE = 020,	// SEC HOLD?
	SPEC_SBR_CALL = 021,
	SPEC_ARL_IND = 022,
	SPEC_MTR_CTL = 023,
	SPEC_FLAG_CTL = 024,
	SPEC_SAVE_FLAGS = 025,
	SPEC_SP_MEM_CYCLE = 026,
	SPEC_AD_LONG = 027
};

enum
{
	FLG_OV = FB0,
	FLG_CRY0 = FB1,
	FLG_CRY1 = FB2,
	FLG_FOV = FB3,
	FLG_FPD = FB4,
	FLG_USER = FB5,
	FLG_USER_IOT = FB6,
	FLG_PUBLIC = FB7,
	FLG_ADR_BRK_INH = FB8,
	FLG_TRAP_REQ_2 = FB9,
	FLG_TRAP_REQ_1 = FB10,
	FLG_FXU = FB11,
	FLG_DIV_CHK = FB12
};

#define COND_AR_FM_EXP (kl->cram_cond == COND_REG_CTL && kl->cram_num & 010)
#define KERNEL_MODE ((kl->c.pc_flags & (FLG_USER|FLG_PUBLIC)) == 0)

/* A DRAM word */
typedef struct Dword Dword;
struct Dword
{
	int a, b;
};
/* A CRAM word */
typedef struct Cword Cword;
struct Cword
{
	int a, b, c, d, e, f, g;
};

// KL10STRUCT	tag for the plumber
typedef struct KL10regs KL10regs;
struct KL10regs
{
	/* data path registers */
	word mq;
	word ar, arx;
	word br, brx;

	/* address path registers */
	aword pc;
	aword vma;
	aword vma_held;
	aword adr_break;
	aword vma_prev_sec;

	/* fastmem blocks */
	int apr_current_block;
	int apr_prev_block;
	int apr_vma_block;

	/* shift and exp */
	uint sc;	/* bits sign,0-9 */
	uint fe;	/* bits sign,0-9 */

	Cword cram;	/* latched control word */

	/* PC flags, badly named SCD */
	word pc_flags;	/* everything visible in PC */
	int scd_trap_cyc;
	int scd_pcp;
	int scd_private_instr;
	int scd_adr_brk_cyc;

	hword ir;

	/* control flops */
	int con_pi_cycle;	// CON5
	int con_mem_cycle;	// CON5
};

typedef struct KL10 KL10;
struct KL10
{

	/* combinational logic */
	word ad, adx;
	int ad_cry_n2, ad_cry_1, ad_overflow;
	int adx_cry_0;
	aword vma_in;
	aword vma_ad;
	aword vma_held_or_pc;
	uint scad;	/* bits sign,0-9 */

	word fm;
	word cache_data;
	word ebus;
	word sh;
	int pi;

	/* flip flops */
	KL10regs c;	// current state
	KL10regs n;	// next state

	Cword cram[2048];	// 1280 in model A
	Dword dram[512];
	word fastmem[16*8];

	int dr_adr;
	int dram_a, dram_b, dram_j;

	uint cra_adr;
	uint cra_adr_dbg;
	int cram_j;
	int cram_ad, cram_ada, cram_adb;
	int cram_ar, cram_arx;
	int cram_br, cram_brx;
	int cram_mq;
	int cram_fm_adr_sel;
	int cram_scad_sel;
	int cram_scada_sel;
	int cram_scadb_sel;
	int cram_sc_sel;
	int cram_fe_load;
	int cram_sh_armm_sel;
	int cram_vma_sel;
	int cram_t;
	int cram_mem;
	int cram_cond;
	int cram_spec;
	int cram_num;	// bits 0-8

	/* AD control */
	int ctl_ad_long;	// CTL1
	int ctl_adx_cry_36;	// CTL1
	int ctl_gen_cry_18;	// CTL1
	int ctl_inh_cry_18;	// CTL1

	/* AR control */
	int ctl_ar_00_08_load;	// CTL2
	int ctl_ar_09_17_load;	// CTL2
	int ctl_arr_load;	// CTL2
	int ctl_ar_00_11_clr;	// CTL2
	int ctl_ar_12_17_clr;	// CTL2
	int ctl_arr_clr;	// CTL2
	int ctl_arl_sel;	// CTL2
	int ctl_arr_sel;	// CTL2

	/* ARX control */
	int ctl_arx_load;	// CTL2
	int ctl_arxl_sel;	// CTL2
	int ctl_arxr_sel;	// CTL2

	/* MQ control */
	int ctl_mqm_en;		// CTL2
	int ctl_mqm_sel;	// CTL2
	int ctl_mq_sel;		// CTL2

	/* address control */
	int con_vma_sel;	// CON1
	int con_load_prev_context;
	int ctl_load_pc;

	/* memory control */
	int mcl_vma_fm_ad;
	int mcl_vma_inc;
	int mcl_vmax_sel;
	int mcl_vmax_en;
	int mcl_load_vma_held;
	int mcl_xr_previous;
	int mcl_load_vma_context;
	int mcl_vma_prev_en;

	/* fastmem control */
	int apr_fm_block;	// APR5
	int apr_fm_adr;		// APR4
	int con_fm_write;	// CON5

	/* shift matrix control */
	int shm_instr_format;

	/* misc, TODO */
	int con_pc_inc_inh;	// CON4

	hword serial;
};

int dotrace;

void
trace(char *fmt, ...)
{
	va_list ap;
	va_start(ap, fmt);
	if(dotrace){
		fprintf(stdout, "  ");
		vfprintf(stdout, fmt, ap);
	}
	va_end(ap);
}


int
getdradr(hword ir)
{
	int dr;
	// TODO: IO AND JRST
	if((ir & 0700000) == 0700000){
		dr = 0700;
		dr |= ir>>5 & 7;
		if(ir & 0074000)
			dr |= 070;
		else
			dr |= ir>>6 & 070;
	}else
		dr = ir>>9 & 0777;
	return dr;
}

void
fetchdr(KL10 *kl)
{
	Dword dw;
	assert(kl->dr_adr < 01000);
	dw = kl->dram[kl->dr_adr];
	kl->dram_a = dw.a>>9 & 7;
	kl->dram_b = dw.a>>6 & 07;
	if((kl->n.ir & 0777000) == 0254000){
		kl->dram_j = dw.b & 01600;
		kl->dram_j |= kl->n.ir>>5 & 017;
	}else{
		kl->dram_j = dw.b & 01717;
	}
}

word
sxt36(word w)
{
	return w & S36 ? w|SXT36 : w&M36;
}

void
update_adx(KL10 *kl)
{
	int c, m, func;
	word adxa, adxb;
	word nadxa, nadxb;
	word a, b;

	adxa = kl->cram_ada & 4 ? 0 : kl->c.arx;
	adxa &= M36;
	nadxa = ~adxa & M36;

	switch(kl->cram_adb){
	case 0: adxb = M36; break;	/* TODO: or 0? */
	case 1: adxb = kl->c.brx<<1; break;	/* TODO: lower bits? */
	case 2: adxb = kl->c.brx; break;
	case 3: adxb = kl->c.arx<<2; break;	/* TODO: lower bits? */
	default: assert(0);	/* can't happen */
	}
	adxb &= M36;
	nadxb = ~adxb & M36;

	c = kl->ctl_adx_cry_36;
	m = kl->cram_ad>>4 & 1;
	func = kl->cram_ad & 017;

	if(m){
		switch(func){
		case 000: kl->adx = nadxa; break;
		case 001: kl->adx = nadxa | nadxb; break;
		case 002: kl->adx = nadxa | adxb; break;
		case 003: kl->adx = M36; break;
		case 004: kl->adx = nadxa & nadxb; break;
		case 005: kl->adx = nadxb; break;
		case 006: kl->adx = adxa ^ nadxb; break;
		case 007: kl->adx = adxa | nadxb; break;
		case 010: kl->adx = nadxa & adxb; break;
		case 011: kl->adx = adxa ^ adxb; break;
		case 012: kl->adx = adxb; break;
		case 013: kl->adx = adxa | adxb; break;
		case 014: kl->adx = 0; break;
		case 015: kl->adx = adxa & nadxb; break;
		case 016: kl->adx = adxa & adxb; break;
		case 017: kl->adx = adxa; break;
		}
	}else{
		switch(func){
		case 000:
			a = adxa;
			b = 0;
			break;
		case 001:
			a = adxa;
			b = adxa & nadxb;
			break;
		case 002:
			a = adxa;
			b = adxa & adxb;
			break;
		case 003:
			a = adxa;
			b = adxa;
			break;
		case 004:
			a = adxa | adxb;
			b = 0;
			break;
		case 005:
			a = adxa | adxb;
			b = adxa & nadxb;
			break;
		case 006:
			a = adxa;
			b = adxb;
			break;
		case 007:
			a = adxa;
			b = adxa | adxb;
			break;
		case 010:
			a = adxa | nadxb;
			b = 0;
			break;
		case 011:
			a = adxa;
			b = nadxb;
			break;
		case 012:
			a = adxa | adxb;
			b = adxa & adxb;
			break;
		case 013:
			a = adxa;
			b = adxa | nadxb;
			break;
		case 014:
			a = 0;
			b = M36;
			break;
		case 015:
			a = adxa & nadxb;
			b = M36;
			break;
		case 016:
			a = adxa & adxb;
			b = M36;
			break;
		case 017:
			a = adxa;
			b = M36;
			break;
		}
		kl->adx = a + b + c;
	}
	kl->adx_cry_0 = kl->adx>>36 & 1;
	kl->adx &= M36;
}

void
update_ad(KL10 *kl)
{
	int c, m, func;
	word ada, adb;
	word nada, nadb;
	word a, b;

	switch(kl->cram_ada){
	case 0:	ada = kl->c.ar; break;
	case 1:	ada = kl->c.arx; break;
	case 2:	ada = kl->c.mq; break;
	case 3:	ada = kl->vma_held_or_pc; break;	/* TODO, upper bits? */
	default: ada = 0; break;
	}
	ada = sxt36(ada) & M38;
	nada = ~ada & M38;

	switch(kl->cram_adb){
	case 0: adb = sxt36(kl->fm); break;	/* TODO: parity */
	case 1: adb = sxt36(kl->c.br)<<1 | kl->c.brx>>35 & 1; break;
	case 2: adb = sxt36(kl->c.br); break;
	case 3: adb = sxt36(kl->c.ar)<<2 | kl->c.arx>>34 & 3; break;
	default: assert(0);	/* can't happen */
	}
	adb &= M38;
	nadb = ~adb & M38;

//	printf("ADA: %012lo, ADB: %012lo\n", ada, adb);

	c = kl->adx_cry_0 & kl->ctl_ad_long;
	m = kl->cram_ad>>4 & 1;
	func = kl->cram_ad & 017;

	if(m){
		switch(func){
		case 000: kl->ad = nada; break;
		case 001: kl->ad = nada | nadb; break;
		case 002: kl->ad = nada | adb; break;
		case 003: kl->ad = M38; break;
		case 004: kl->ad = nada & nadb; break;
		case 005: kl->ad = nadb; break;
		case 006: kl->ad = ada ^ nadb; break;
		case 007: kl->ad = ada | nadb; break;
		case 010: kl->ad = nada & adb; break;
		case 011: kl->ad = ada ^ adb; break;
		case 012: kl->ad = adb; break;
		case 013: kl->ad = ada | adb; break;
		case 014: kl->ad = 0; break;
		case 015: kl->ad = ada & nadb; break;
		case 016: kl->ad = ada & adb; break;
		case 017: kl->ad = ada; break;
		}
	}else{
		switch(func){
		case 000:
			a = ada;
			b = 0;
			break;
		case 001:
			a = ada;
			b = ada & nadb;
			break;
		case 002:
			a = ada;
			b = ada & adb;
			break;
		case 003:
			a = ada;
			b = ada;
			break;
		case 004:
			a = ada | adb;
			b = 0;
			break;
		case 005:
			a = ada | adb;
			b = ada & nadb;
			break;
		case 006:
			a = ada;
			b = adb;
			break;
		case 007:
			a = ada;
			b = ada | adb;
			break;
		case 010:
			a = ada | nadb;
			b = 0;
			break;
		case 011:
			a = ada;
			b = nadb;
			break;
		case 012:
			a = ada | adb;
			b = ada & adb;
			break;
		case 013:
			a = ada;
			b = ada | nadb;
			break;
		case 014:
			a = 0;
			b = M38;
			break;
		case 015:
			a = ada & nadb;
			b = M38;
			break;
		case 016:
			a = ada & adb;
			b = M38;
			break;
		case 017:
			a = ada;
			b = M38;
			break;
		}
		if(kl->ctl_inh_cry_18)
			kl->ad = (a&L20)+(b&L20) | RT(a + b + c);
		else
			kl->ad = a + b + c;
		/* called CTL SPEC/GEN CRY 18 in drawings,
		   that's probably wrong */
		if(kl->ctl_gen_cry_18)
			kl->ad += 01000000;
	}
	kl->ad_cry_n2 = kl->ad>>38 & 1;
	kl->ad_cry_1 = 0x9966 >> (kl->ad>>35 & 017) & 1;
	kl->ad_overflow = 0x7E >> (kl->ad>>35 & 7) & 1;
	kl->ad &= M38;
}

void
load_ar(KL10 *kl)
{
	word arl, arr;
	word arm, armm;

	/* TODO: bit 12 */
	armm = kl->vma_in & MSEC | kl->serial;
	switch(kl->cram_sh_armm_sel){
	case 0: armm |= (word)kl->cram_num<<27; break;
	case 1: armm |= kl->c.ar & S36 ? 0777000000000 : 0; break;
	case 2:
		armm |= (word)(kl->scad&0377)<<27;
		if(COND_AR_FM_EXP || kl->c.ar>>27 & kl->scad & 0400)
			armm |= FB0;
		break;
	case 3:
		armm |= ((word)kl->scad<<27)&MPOS | kl->c.ar&MSZ;
		break;
	default: assert(0);	/* can't happen */
	}
	armm &= M36;

	switch(kl->ctl_arl_sel){
	case 0: arl = armm; break;
	case 1: arl = kl->cache_data; break;
	case 2: arl = kl->ad; break;
	case 3: arl = kl->ebus; break;
	case 4: arl = kl->sh; break;
	case 5: arl = kl->ad<<1; break;
	case 6: arl = kl->adx; break;
	case 7: arl = kl->ad>>2; break;
	default: assert(0);	/* can't happen */
	}
	switch(kl->ctl_arr_sel){
	case 0: arr = armm; break;
	case 1: arr = kl->cache_data; break;
	case 2: arr = kl->ad; break;
	case 3: arr = kl->ebus; break;
	case 4: arr = kl->sh; break;
	case 5: arr = kl->ad<<1 | kl->adx>>35 & 1; break;
	case 6: arr = kl->adx; break;
	case 7: arr = kl->ad>>2; break;
	default: assert(0);	/* can't happen */
	}

	arm = LT(arl) | RT(arr);

	if(kl->ctl_ar_00_11_clr)
		arm &= 0000077777777;
	if(kl->ctl_ar_12_17_clr)
		arm &= 0777700777777;
	if(kl->ctl_arr_clr)
		arm &= 0777777000000;

	if(kl->ctl_ar_00_08_load)
		SETMASK(kl->n.ar, arm, 0777000000000);
	if(kl->ctl_ar_09_17_load)
		SETMASK(kl->n.ar, arm, 0000777000000);
	if(kl->ctl_arr_load)
		SETMASK(kl->n.ar, arm, 0000000777777);
}

void
load_arx(KL10 *kl)
{
	word arxl, arxr;

	if(!kl->ctl_arx_load)
		return;

	switch(kl->ctl_arxl_sel){
	case 0: arxl = 0; break;
	case 1: arxl = kl->cache_data; break;
	case 2: arxl = kl->ad; break;
	case 3: arxl = kl->c.mq; break;
	case 4: arxl = kl->sh; break;
	case 5: arxl = kl->adx<<1; break;
	case 6: arxl = kl->adx; break;
	case 7: arxl = kl->ad<<34 | kl->adx>>2; break;
	default: assert(0);	/* can't happen */
	}
	switch(kl->ctl_arxr_sel){
	case 0: arxr = 0; break;
	case 1: arxr = kl->cache_data; break;
	case 2: arxr = kl->ad; break;
	case 3: arxr = kl->c.mq; break;
	case 4: arxr = kl->sh; break;
	case 5: arxr = kl->adx<<1  | kl->c.mq>>35 & 1; break;
	case 6: arxr = kl->adx; break;
	case 7: arxr = kl->adx>>2; break;
	default: assert(0);	/* can't happen */
	}

	kl->n.arx = LT(arxl) | RT(arxr);
}

void
load_br(KL10 *kl)
{
	if(kl->cram_br)
		kl->n.br = kl->c.ar;
}

void
load_brx(KL10 *kl)
{
	if(kl->cram_brx)
		kl->n.brx = kl->c.arx;
}

void
load_mq(KL10 *kl)
{
	word mqm;

	if(kl->ctl_mq_sel < 2){
		if(kl->ctl_mqm_en) switch(kl->ctl_mqm_sel){
		case 0: mqm = kl->c.mq>>2 | kl->adx<<34; break;
		case 1: mqm = kl->sh; break;
		case 2: mqm = kl->ad; break;
		case 3: mqm = M36; break;
		default: assert(0);	/* can't happen */
		}else
			mqm = 0;
		mqm &= M36;
	}

	switch(kl->ctl_mq_sel){
	case 0:
		kl->n.mq = mqm;
		break;
	case 1:
		kl->n.mq = mqm<<1 & 0444444444444 |
		         kl->c.mq>>1 & 0333333333333;
		break;
	case 2:
		kl->n.mq = kl->c.mq << 1;
		kl->n.mq |= kl->ad_cry_n2;
		break;
	case 3:
		break;
	default: assert(0);	/* can't happen */
	}
	kl->n.mq &= M36;
}

void
update_fm(KL10 *kl)
{
	uint a, b;

	if(kl->mcl_load_vma_context)
		kl->n.apr_vma_block = kl->mcl_vma_prev_en ?
			kl->c.apr_prev_block : kl->c.apr_current_block;

	switch(kl->cram_fm_adr_sel){
	case 0:
		kl->apr_fm_adr = kl->c.ir>>5;
		kl->apr_fm_block = kl->c.apr_current_block;
		break;
	case 1:
		kl->apr_fm_adr = (kl->c.ir>>5)+1;
		kl->apr_fm_block = kl->c.apr_current_block;
		break;
	case 2:
		kl->apr_fm_adr = kl->c.arx >>
			(kl->shm_instr_format ? 18 : 30);
		kl->apr_fm_block = kl->mcl_xr_previous ?
			kl->c.apr_prev_block : kl->c.apr_current_block;
		break;
	case 3:
		kl->apr_fm_adr = kl->c.vma;
		kl->apr_fm_block = kl->c.apr_vma_block;
		break;
	case 4:
		kl->apr_fm_adr = (kl->c.ir>>5)+2;
		kl->apr_fm_block = kl->c.apr_current_block;
		break;
	case 5:
		kl->apr_fm_adr = (kl->c.ir>>5)+3;
		kl->apr_fm_block = kl->c.apr_current_block;
		break;
	case 6:
		a = kl->c.ir>>5;
		b = kl->cram_num;
		switch(kl->cram_num>>4 & 037){
		/* Arithmetic */
		case 000: kl->apr_fm_adr = a; break;
		case 001: kl->apr_fm_adr = a + (a&~b); break;
		case 002: kl->apr_fm_adr = a + (a&b); break;
		case 003: kl->apr_fm_adr = a + a; break;
		case 004: kl->apr_fm_adr = a|b; break;
		case 005: kl->apr_fm_adr = (a|b) + (a&~b); break;
		case 006: kl->apr_fm_adr = a + b; break;
		case 007: kl->apr_fm_adr = a + (a|b); break;
		case 010: kl->apr_fm_adr = a|~b; break;
		case 011: kl->apr_fm_adr = a + ~b; break;
		case 012: kl->apr_fm_adr = (a|~b) + (a&b); break;
		case 013: kl->apr_fm_adr = a + (a|~b); break;
		case 014: kl->apr_fm_adr = ~0; break;
		case 015: kl->apr_fm_adr = (a&~b) + ~0; break;
		case 016: kl->apr_fm_adr = (a&b) + ~0; break;
		case 017: kl->apr_fm_adr = a + ~0; break;
		/* Boole */
		case 020: kl->apr_fm_adr = ~a; break;
		case 021: kl->apr_fm_adr = ~a | ~b; break;
		case 022: kl->apr_fm_adr = ~a | b; break;
		case 023: kl->apr_fm_adr = ~0; break;
		case 024: kl->apr_fm_adr = ~a & ~b; break;
		case 025: kl->apr_fm_adr = ~b; break;
		case 026: kl->apr_fm_adr = a ^ ~b; break;
		case 027: kl->apr_fm_adr = a | ~b; break;
		case 030: kl->apr_fm_adr = ~a & b; break;
		case 031: kl->apr_fm_adr = a ^ b; break;
		case 032: kl->apr_fm_adr = b; break;
		case 033: kl->apr_fm_adr = a | b; break;
		case 034: kl->apr_fm_adr = 0; break;
		case 035: kl->apr_fm_adr = a & ~b; break;
		case 036: kl->apr_fm_adr = a & b; break;
		case 037: kl->apr_fm_adr = a; break;
		}
		kl->apr_fm_block = kl->c.apr_current_block;
		break;
	case 7:
		kl->apr_fm_adr = kl->cram_num;
		kl->apr_fm_block = kl->cram_num >> 4;
		break;
	default: assert(0);	/* can't happen */
	}
	kl->apr_fm_adr &= M4;
	kl->apr_fm_block &= M3;

	kl->fm = kl->fastmem[kl->apr_fm_adr | kl->apr_fm_block<<4];
}

void
write_fm(KL10 *kl)
{
	if(kl->con_fm_write)
		kl->fastmem[kl->apr_fm_adr | kl->apr_fm_block<<4] = kl->c.ar;
}

void
update_vma_ad(KL10 *kl)
{
	if(kl->cram_cond >= COND_VMA_FM_NUM &&
	   kl->cram_cond <= COND_VMA_FM_NUM_PI_2){
		uint trap_mix;
		switch(kl->cram_cond){
		case COND_VMA_FM_NUM:
			trap_mix = kl->cram_num;
			break;
		case COND_VMA_FM_NUM_TRAP:
			trap_mix = kl->cram_num & 014 | kl->c.scd_trap_cyc;
			break;
		case COND_VMA_FM_NUM_MODE:
			trap_mix = kl->cram_num & 010 |
				!!(kl->c.pc_flags&FLG_USER)<<2 |
				!!(kl->c.pc_flags&FLG_PUBLIC)<<1 |
				!!kl->c.scd_trap_cyc;
			break;
		case COND_VMA_FM_NUM_AR32_35:
			trap_mix = kl->c.ar;
			break;
		case COND_VMA_FM_NUM_PI_2:
			trap_mix = kl->pi << 1;
			break;
		}
		if(kl->cram_vma_sel&2 && !kl->con_pc_inc_inh)
			trap_mix |= 1;
		trap_mix &= 017;
		kl->vma_ad = kl->cram_num&0760 | trap_mix;
	}else
		// + trap_mix, but it's 0
		kl->vma_ad = kl->c.pc + kl->mcl_vma_inc;
	kl->vma_ad &= M18;
}

void
update_vma_held_or_pc(KL10 *kl)
{
	if(kl->cram_cond == COND_SEL_VMA)
		kl->vma_held_or_pc = kl->c.vma_held;
	else
		kl->vma_held_or_pc = kl->c.pc;
}

void
load_vma(KL10 *kl)
{
	word vma_mix;

	if(kl->mcl_vmax_en) switch(kl->mcl_vmax_sel){
	case 0: kl->vma_in = kl->c.vma; break;
	case 1: kl->vma_in = kl->c.pc; break;
	case 2: kl->vma_in = kl->c.vma_prev_sec; break;
	case 3: kl->vma_in = kl->ad; break;
	default: assert(0);	/* can't happen */
	}else
		kl->vma_in = 0;
	kl->vma_in &= 077000000;

	switch(kl->con_vma_sel){
	case 0:
		break;
	case 1:
		kl->n.vma = kl->c.vma+1 & M24;
		break;
	case 2:
		kl->n.vma = kl->c.vma-1 & M24;
		break;
	case 3:
		if(kl->mcl_vma_fm_ad)
			vma_mix = kl->ad;
		else{
			update_vma_ad(kl);
			vma_mix = kl->vma_ad;
		}
		kl->n.vma = kl->vma_in | vma_mix & M18;
		break;
	default: assert(0);	/* can't happen */
	}
}

void
load_prev_sec(KL10 *kl)
{
	if(kl->con_load_prev_context)
		kl->n.vma_prev_sec = kl->ad & MSEC;
}

void
load_vma_held(KL10 *kl)
{
	if(kl->mcl_load_vma_held)
		kl->n.vma_held = kl->c.vma & M23;
}

void
load_pc(KL10 *kl)
{
	if(kl->ctl_load_pc){
		kl->n.pc = kl->c.vma & M23;
		if((kl->c.vma & MSEC) == 0)
			kl->n.pc |= 040000000;
	}
}

void
update_sh(KL10 *kl)
{
	switch(kl->cram_sh_armm_sel){
	case 0:
		if(kl->c.sc < 36)
			kl->sh = kl->c.ar << kl->c.sc |
				kl->c.arx >> 36-kl->c.sc;
		else
	case 2:		kl->sh = kl->c.arx;
		break;
	case 1:
		kl->sh = kl->c.ar;
		break;
	case 3:
		kl->sh = RT(kl->c.ar)<<18 | LT(kl->c.ar)>>18;
		break;
	default: assert(0);	/* can't happen */
	}
	kl->sh &= M36;
}

void
update_scad(KL10 *kl)
{
	uint scada, scadb;

	switch(kl->cram_scada_sel){
	case 0: scada = kl->c.fe; break;
	case 1: scada = kl->c.ar>>30 & M6; break;
	case 2:
		scada = kl->c.ar>>27 & M8;
		if(kl->c.ar & FB0)
			scada ^= M8;
		break;
	case 3: scada = kl->cram_num | kl->cram_num<<1 & 01000; break;
	case 4:
	case 5:
	case 6:
	case 7: scada = 0; break;
	default: assert(0);	/* can't happen */
	}
	scada &= M10;
	scada |= scada<<1 & 02000;

	switch(kl->cram_scadb_sel){
	case 0: scadb = kl->c.sc; break;
	case 1: scadb = kl->c.ar>>24 & M6; break;
	case 2: scadb = kl->c.ar>>27 & M9; break;
	case 3: scadb = kl->cram_num; break;
	default: assert(0);	/* can't happen */
	}
	scadb &= M10;
	scadb |= scadb<<1 & 02000;

	switch(kl->cram_scad_sel){
	case 0: kl->scad = scada; break;
	case 1: kl->scad = scada + ~scadb; break;
	case 2: kl->scad = scada + scadb; break;
	case 3: kl->scad = scada + ~0; break;
	case 4: kl->scad = scada + 1; break;
	case 5: kl->scad = scada + ~scadb + 1; break;
	case 6: kl->scad = scada | scadb; break;
	case 7: kl->scad = scada & scadb; break;
	default: assert(0);	/* can't happen */
	}
	kl->scad &= M11;
}

void
load_sc_fe(KL10 *kl)
{
	uint scm;

	switch(kl->cram_sc_sel<<1 | kl->cram_spec==SPEC_SCM_ALT){
	case 0: scm = kl->c.sc; break;
	case 1: scm = kl->c.fe; break;
	case 2: scm = kl->scad; break;
	case 3:
		scm = kl->c.ar & M8;
		if(kl->c.ar & FB18)
			scm |= 01400;
		break;
	default: assert(0);	/* can't happen */
	}
	kl->n.sc = scm & M10;

	if(kl->cram_fe_load){
		kl->n.fe = kl->scad & M10;
		kl->n.fe |= kl->n.fe<<1 & 02000;
	}else if(kl->cram_cond == COND_FE_SHRT){
		kl->n.fe >>= 1;
		kl->n.fe |= kl->n.fe<<1 & 02000;
	}
}

/* TODO: replace this losing code */
void
load_pc_flags(KL10 *kl)
{
	if(kl->cram_spec == SPEC_FLAG_CTL){
		int load_flags, portal, jfcl, leave_user;
		load_flags = !!(kl->cram_num & 020);
		portal = !!(kl->cram_num & 010);
		jfcl = !!(kl->cram_num & 0200);
		leave_user = !(kl->cram_num & 0400) ||
			!(kl->cram_num & 2) && KERNEL_MODE;

		/* user bit */
		if(load_flags && kl->c.ar&FLG_USER)
			kl->n.pc_flags |= FLG_USER;
		else if(leave_user)
			kl->n.pc_flags &= ~FLG_USER;

		/* user iot bit */
		if(load_flags && kl->c.ar&FLG_USER_IOT &&
		   (leave_user || !(kl->c.pc_flags&FLG_USER)))
			kl->n.pc_flags |= FLG_USER_IOT;
		else if(leave_user ||
		   (load_flags && !(kl->c.ar&FLG_USER_IOT)))
			kl->n.pc_flags &= ~FLG_USER_IOT;

		/* public bit */
		if(load_flags && kl->c.ar&FLG_PUBLIC)
			kl->n.pc_flags |= FLG_PUBLIC;
		else if(leave_user ||
		   portal && kl->c.scd_private_instr ||
		   load_flags && kl->c.ar&FLG_USER && !(kl->c.pc_flags&FLG_USER))
			kl->n.pc_flags &= ~FLG_PUBLIC;
		// TODO: page stuff somewhere else

		/* private instr bit */

		/* adr brk inh bit */
		if(load_flags && kl->c.ar&FLG_ADR_BRK_INH)
			kl->n.pc_flags |= FLG_ADR_BRK_INH;
		else if(load_flags)
			kl->n.pc_flags &= ~FLG_ADR_BRK_INH;
		// TODO: instr abort somewhere else

		/* adr brk cyc bit */
		if(load_flags)
			kl->n.scd_adr_brk_cyc = 0;
		// TODO: nicond somewhere else


		if(load_flags){
			word m;
			m = FLG_OV | FLG_CRY0 | FLG_CRY1 |
				FLG_FOV | FLG_FXU | FLG_DIV_CHK |
				FLG_FPD | FLG_TRAP_REQ_1 | FLG_TRAP_REQ_2;
			SETMASK(kl->n.pc_flags, kl->c.ar, m);
		}
//printf("%d %d %d %d\n", kl->n.scd_trap_cyc, kl->n.scd_pcp, kl->n.scd_private_instr, kl->n.scd_adr_brk_cyc);
	}else if(kl->cram_spec == SPEC_SAVE_FLAGS && kl->c.con_pi_cycle){
		/* PI&SAVE FLAGS, implies LEAVE USER */

		kl->n.pc_flags &= ~FLG_USER;

		if(kl->c.pc_flags&FLG_USER)
			kl->n.pc_flags |= FLG_USER_IOT;
		else
			kl->n.pc_flags &= ~FLG_USER_IOT;
	}
}

void
update_cram(KL10 *kl)
{
	kl->cram_j = kl->c.cram.a & 03777;
	kl->cram_ad = kl->c.cram.b>>6 & 077;
	kl->cram_ada = kl->c.cram.b>>3 & 7;
	kl->cram_adb = kl->c.cram.b & 3;
	kl->cram_ar = kl->c.cram.c>>9 & 7;
	kl->cram_arx = kl->c.cram.c>>6 & 7;
	kl->cram_br = kl->c.cram.c>>5 & 1;
	kl->cram_brx = kl->c.cram.c>>4 & 1;
	kl->cram_mq = kl->c.cram.c>>3 & 1;
	kl->cram_fm_adr_sel = kl->c.cram.c & 7;
	kl->cram_scad_sel = kl->c.cram.d>>9 & 7;
	kl->cram_scada_sel = kl->c.cram.d>>6 & 7;
	kl->cram_scadb_sel = kl->c.cram.d>>3 & 7;
	kl->cram_sc_sel = kl->c.cram.d>>1 & 1;
	kl->cram_fe_load = kl->c.cram.d & 1;
	kl->cram_sh_armm_sel = kl->c.cram.e>>9 & 3;
	kl->cram_vma_sel = kl->c.cram.e>>6 & 3;
	kl->cram_t = kl->c.cram.e>>4 & 3;
	kl->cram_mem = kl->c.cram.e & 017;
	kl->cram_cond = kl->c.cram.f>>6 & 077;
	kl->cram_spec = kl->c.cram.f & 077;
	// TODO: bit 74???
	kl->cram_num = kl->c.cram.g & 0777;
}

void
printcram(KL10 *kl)
{
#include "disasm.inc"
	trace("CRAM %04o:\n", kl->cra_adr_dbg);
	trace(" J/%o\n", kl->cram_j);
	trace(" AD/%s\tADA/%s\tADB/%s\n",
		ad_def[kl->cram_ad],
		ada_def[kl->cram_ada], adb_def[kl->cram_adb]);
	trace(" AR/%s\tARX/%s\n", ar_def[kl->cram_ar], arx_def[kl->cram_arx]);
	trace(" BR/%s\tBRX/%s\n", br_def[kl->cram_br], brx_def[kl->cram_brx]);
	trace(" MQ/%o\tFM/%s\n", kl->cram_mq, fm_def[kl->cram_fm_adr_sel]);
	trace(" SCAD/%s\tSCADA/%s\tSCADB/%s\n",
		scad_def[kl->cram_scad_sel], scada_def[kl->cram_scada_sel],
		scadb_def[kl->cram_scadb_sel]);
	trace(" SC/%s\tFE/%s\n", sc_def[kl->cram_sc_sel],
		fe_def[kl->cram_fe_load]);
	trace(" SH/%s\tARMM/%s\tVMA/%s\n",
		sh_def[kl->cram_sh_armm_sel],
		armm_def[kl->cram_sh_armm_sel],
		vma_def[kl->cram_vma_sel]);
	trace(" TIME/%s\tMEM/%s\n",
		t_def[kl->cram_t], mem_def[kl->cram_mem]);
	trace(" %s/%s\t",
		kl->cram_cond & 040 ? "SKIP" : "COND",
		cond_skip_def[kl->cram_cond]);
	trace("%s/%s\t",
		9>>(kl->cram_spec>>3) & 1 ? "DISP" : "SPEC",
		disp_spec_def[kl->cram_spec]);
	trace("#/%o\n", kl->cram_num);
}

void
printdp(KL10 *kl)
{
	trace("AR/%012lo ARX/%012lo MQ/%012lo\n",
		kl->n.ar, kl->n.arx, kl->n.mq);
	trace("BR/%012lo BRX/%012lo\n", kl->n.br, kl->n.brx);
	trace("AD/%012lo ADX/%012lo\n", kl->ad, kl->adx);
	trace("PC/%012lo VMA/%08lo\n", kl->n.pc | kl->n.pc_flags, kl->n.vma);
}

/*
 * Combinational logic
 * Set combinational elements from current state
 * and other combinational elements.
 * Have to be careful to do this in right order!
 */
void
update_ebox(KL10 *kl)
{
	update_cram(kl);
	// TODO: decode everything here
	kl->cra_adr_dbg = kl->cra_adr;	// remember where we fetched from for prining
	kl->cra_adr = kl->cram_j;	// TODO

	/* Data path */
	update_fm(kl);
	update_sh(kl);
	update_vma_held_or_pc(kl);
	update_adx(kl);
	/* depends on:
	 *  adx carry
	 *  vma_held_or_pc
	 *  fm */
	update_ad(kl);
	/* depends on:
	 * pi */
	// update_vma_ad(kl);	// done by load_vma
	update_scad(kl);
}

/*
 * Sequential logic
 * Here we do our conceptional clock tick.
 * Set next state of clocked elements
 * from current state and combinational logic.
 */
void
tick_mbox(KL10 *kl)
{
	trace("MBox tick\n");
}

void
tick_edp(KL10 *kl)
{
	trace("EBox EDP tick\n");
	load_ar(kl);
	load_arx(kl);
	load_br(kl);
	load_brx(kl);
	load_mq(kl);
}

void
tick_crm(KL10 *kl)
{
	trace("EBox CRM tick\n");

	kl->n.cram = kl->cram[kl->cra_adr];
}

void
tick_ctl(KL10 *kl)
{
	trace("EBox CTL tick\n");

	/* VMA */
	load_pc(kl);
	load_vma(kl);
	load_vma_held(kl);
	load_prev_sec(kl);

	/* SCD */
	load_sc_fe(kl);
	load_pc_flags(kl);

	/* TODO: APR, CON, MCL, IR */
}

/* TODO: remove this perhaps? */
void
reset(KL10 *kl)
{
	kl->serial = 0162534;

	/* MR RESET can be tied to a
	 * shift signal of a shift register with
	 * shift input 0. Since it is asserted
	 * for a lot of clock ticks, this zeroes
	 * a shift register. */
	memset(&kl->n.cram, 0, sizeof(Cword));
	kl->n.fe = 0;

	kl->n.sc = 0;

	kl->n.pc_flags &= ~(FLG_USER|FLG_USER_IOT|FLG_PUBLIC);
	kl->n.scd_private_instr = 1;

	/* TODO */

	kl->c = kl->n;
}

/* This is a sketch of the general way we execute */
void
clocktest(KL10 *kl)
{
	#define T 0

	int mticks;
	int eticks;
	int ebox_sync;
	int ebox_en;
	int t;
	int waiting;

	waiting = 0;
	t = T;
	ebox_en = 0;
	eticks = 0;
	for(mticks = 0; mticks < 100; mticks++){
		tick_mbox(kl);
		if(ebox_en){
			eticks++;
			update_ebox(kl);
			tick_crm(kl);
			tick_edp(kl);
			tick_ctl(kl);

	printcram(kl);
	printdp(kl);

			t = T;
			ebox_en = 0;
		}

		/* Advance time */
		kl->c = kl->n;

		if(eticks >= 3)
			break;

		if(ebox_sync){
			ebox_en = 1;
			ebox_sync = 0;
		}else if(t == 0 && !waiting)
			ebox_sync = 1;
		if(t)
			t--;
	}
}

void
loaducode(KL10 *kl, const char *filename)
{
	FILE *f;
	char line[100], *l;
	char type;
	int addr;
	Dword dw;
	Cword cw;

	f = fopen(filename, "r");
	if(f == nil)
		return;
	while(l = fgets(line, 100, f)){
		for(; *l; l++){
			if(*l == ',')
				*l = ' ';
			if(*l == '\n'){
				*l = '\0';
				break;
			}
		}
		sscanf(line, "%c %o", &type, &addr);
		if(type == 'D'){
			sscanf(line, "%c %o   %o %o",
				&type, &addr,
				&dw.a, &dw.b);
			if(addr >= 512)
				fprintf(stderr, "DRAM address %o too high\n", addr);
			else if(dw.b & 060)
				fprintf(stderr, "DRAM J %o bits 5,6 != 0\n", dw.b & 01777);
			else
				kl->dram[addr] = dw;
		}else if(type == 'U'){
			sscanf(line, "%c %o   %o %o %o %o %o %o %o",
				&type, &addr,
				&cw.a, &cw.b, &cw.c, &cw.d, &cw.e, &cw.f, &cw.g);
			if(addr >= 1280)
				fprintf(stderr, "CRAM address %o too high\n", addr);
			else
				kl->cram[addr] = cw;
		}else
			fprintf(stderr, "unknown type %c\n", type);
	}
	fclose(f);
	for(addr = 0; addr < 512; addr += 2)
		if(addr != 0254 &&	// JRST is a special case
		   (kl->dram[addr].b & 01710) != (kl->dram[addr+1].b & 01710))
			fprintf(stderr, "DRAM bits not same at %03o\n", addr);
}

int
main()
{
	KL10 *kl10;

	printf("sizeof KL10regs: %d. bytes\n", sizeof(KL10regs));

	kl10 = malloc(sizeof(KL10));
	memset(kl10, 0, sizeof(KL10));

	loaducode(kl10, "ucode/u1.txt");

	reset(kl10);
	dotrace = 1;
	kl10->n.pc_flags = 0777740000000;
//	kl10->n.pc_flags = 0000000000000;
//	kl10->n.ar = 0777777000100;
	kl10->n.ar = 0000000000100;
	clocktest(kl10);

	return 0;
}
