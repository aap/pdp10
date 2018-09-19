#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
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
#define FB18 0000000400000ULL
#define MPOS 0770000000000ULL
#define MSZ 0007700000000ULL

#define LT(w) ((w) & L18)
#define RT(w) ((w) & R18)

#define SETMASK(l, r, m) l = ((l)&~(m) | (r)&(m))

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

#define COND_AR_FM_EXP (kl->cram_cond == COND_REG_CTL && kl->cram_num & 010)

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
	// TODO: use bits?
	int scd_ov;
	int scd_cry0;
	int scd_cry1;
	int scd_fov;
	int scd_fxu;
	int scd_div_chk;
	int scd_trap_req;
	int scd_trap_cyc;
	int scd_fpd;
	int scd_pcp;
	int scd_user;
	int scd_user_iot;
	int scd_public;
	int scd_private_instr;
	int scd_adr_brk_inh;
	int scd_adr_brk_cyc;

	hword ir;
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
				kl->c.scd_user<<2 |
				kl->c.scd_public<<1 |
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
	printf("CRAM:\n");
	printf(" J/%o\n", kl->cram_j);
	printf(" AD/%s\tADA/%s\tADB/%s\n",
		ad_def[kl->cram_ad],
		ada_def[kl->cram_ada], adb_def[kl->cram_adb]);
	printf(" AR/%s\tARX/%s\n", ar_def[kl->cram_ar], arx_def[kl->cram_arx]);
	printf(" BR/%s\tBRX/%s\n", br_def[kl->cram_br], brx_def[kl->cram_brx]);
	printf(" MQ/%o\tFM/%s\n", kl->cram_mq, fm_def[kl->cram_fm_adr_sel]);
	printf(" SCAD/%s\tSCADA/%s\tSCADB/%s\n",
		scad_def[kl->cram_scad_sel], scada_def[kl->cram_scada_sel],
		scadb_def[kl->cram_scadb_sel]);
	printf(" SC/%s\tFE/%s\n", sc_def[kl->cram_sc_sel],
		fe_def[kl->cram_fe_load]);
	printf(" SH/%s\tARMM/%s\tVMA/%s\n",
		sh_def[kl->cram_sh_armm_sel],
		armm_def[kl->cram_sh_armm_sel],
		vma_def[kl->cram_vma_sel]);
	printf(" TIME/%s\tMEM/%s\n",
		t_def[kl->cram_t], mem_def[kl->cram_mem]);
	printf(" %s/%s\t",
		kl->cram_cond & 040 ? "SKIP" : "COND",
		cond_skip_def[kl->cram_cond]);
	printf("%s/%s\t",
		9>>(kl->cram_spec>>3) & 1 ? "DISP" : "SPEC",
		disp_spec_def[kl->cram_spec]);
	printf("#/%o\n", kl->cram_num);
}

void
step(KL10 *kl)
{
	/* Combinational logic */

	update_cram(kl);

	kl->cra_adr = kl->cram_j;	// TODO

	/* Sequential logic */

	/* latch cram */
	kl->n.cram = kl->cram[kl->cra_adr];

	printcram(kl);

	kl->c = kl->n;
}

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

	/* TODO */

	kl->c = kl->n;
}

void
tick(KL10 *kl)
{
	kl->c = kl->n;
}

void
test(KL10 *kl)
{
	int i, j;
	for(i = 0; i < 8; i++)
		for(j = 0; j < 16; j++)
			kl->fastmem[i*16+j] = 0123456700000 | i<<9 | j;

	kl->shm_instr_format = 1;

	kl->cram_ad = 006;
	kl->cram_ada = 0;
	kl->cram_adb = 2;

	kl->n.ar = 0400123012300;
	kl->n.br = 0001234333000;
	kl->n.arx = 0400000012300;
	kl->n.brx = 0400000000000;

	kl->ctl_adx_cry_36 = 0;
	kl->ctl_ad_long = 0;
	kl->ctl_inh_cry_18 = 0;
	kl->ctl_gen_cry_18 = 0;
	tick(kl);
	update_adx(kl);
	update_ad(kl);

	printf("AR: %012lo, BR: %012lo\n", kl->c.ar, kl->c.br);
	printf("AD: %012lo\n", kl->ad);
	printf("ARX: %012lo, BRX: %012lo\n", kl->c.arx, kl->c.brx);
	printf("ADX: %012lo\n", kl->adx);
	printf("\n");


	kl->ebus = 0665544332211;

	kl->ctl_ar_00_08_load = 1;
	kl->ctl_ar_09_17_load = 1;
	kl->ctl_arr_load = 1;
	kl->ctl_ar_00_11_clr = 0;
	kl->ctl_ar_12_17_clr = 0;
	kl->ctl_arr_clr = 0;
	kl->ctl_arl_sel = 7;
	kl->ctl_arr_sel = 7;
	tick(kl);
	load_ar(kl);

	printf("AR: %012lo, BR: %012lo\n", kl->c.ar, kl->c.br);
	printf("AD: %012lo\n", kl->ad);
	printf("ARX: %012lo, BRX: %012lo\n", kl->c.arx, kl->c.brx);
	printf("ADX: %012lo\n", kl->adx);
	printf("\n");


	kl->adx = 0;
	kl->n.mq = 0123456112233;
	kl->ctl_mqm_en = 1;
	kl->ctl_mqm_sel = 0;
	kl->ctl_mq_sel = 2;
	tick(kl);
	load_mq(kl);
	printf("MQ: %012lo\n", kl->n.mq);
	printf("\n");

	kl->n.pc = 0654321;
	kl->n.vma = 012123456;
	kl->n.vma_prev_sec = 0;
	kl->mcl_vma_inc = 1;
	kl->cram_num = 0777;
	kl->con_vma_sel = 3;
	kl->mcl_vmax_en = 1;
	kl->mcl_vmax_sel = 2;
	kl->mcl_vma_fm_ad = 0;
	kl->cram_cond = COND_VMA_FM_NUM;
	tick(kl);
	load_vma(kl);
	printf("VMA: %08o\n", kl->n.vma);
	printf("\n");

	kl->ctl_load_pc = 1;
	tick(kl);
	load_pc(kl);
	printf("PC: %08o\n", kl->n.pc);
	printf("\n");

	kl->n.ir = 0000740;
	kl->n.arx = 0170017000000;
	kl->n.apr_prev_block = 3;
	kl->n.apr_current_block = 4;
	kl->mcl_xr_previous = 1;
	kl->cram_fm_adr_sel = 2;
	kl->shm_instr_format = 0;
	tick(kl);
	update_fm(kl);
	printf("FM: %012lo\n", kl->fm);
	printf("\n");

	kl->n.ar = 0123456654321;
	kl->n.arx = 0112233445566;
	kl->n.sc = 6;
	kl->cram_sh_armm_sel = 0;
	tick(kl);
	update_sh(kl);
	printf("SH: %012lo\n", kl->sh);
	printf("\n");

	kl->n.fe = 01777;
	kl->n.sc = 01321;
	kl->n.ar = 077451600321;
	kl->cram_num = 01123;
	kl->cram_scada_sel = 3;
	kl->cram_scadb_sel = 2;
	kl->cram_scad_sel = 7;
	tick(kl);
	update_scad(kl);
	printf("SCAD: %04o\n", kl->scad);

	kl->scad = 01111;
	kl->n.sc = 01234;
	kl->n.fe = 03432;
	kl->cram_sc_sel = 1;
	kl->cram_spec = SPEC_SCM_ALT;
	kl->cram_fe_load = 0;
	kl->cram_cond = COND_FE_SHRT;
	tick(kl);
	load_sc_fe(kl);
	printf("SC: %04o FE: %04o\n", kl->n.sc, kl->n.fe);


	kl->vma_in = 077777777;
	kl->cram_num = 0777;
	kl->scad = 0321;
	kl->c.ar = 0701200000000;
	kl->cram_sh_armm_sel = 3;
	load_ar(kl);

/*
	int i, j;
	kl->n.ar = 0;
	for(i = 0; i < 4; i++){
		kl->n.br = 0;
		for(j = 0; j < 4; j++){
			tick(kl);
			update_adx(kl);
			update_ad(kl);
			printf("%o + %o = %02o; %d %d %d\n",
				kl->n.ar>>34 & 3,
				kl->n.br>>34 & 3,
				kl->n.ad>>34 & 017,
				kl->n.ad_cry_n2,
				kl->n.ad_overflow,
				kl->n.ad_cry_1);
			kl->n.br += 0200000000000;
		}
		kl->n.ar += 0200000000000;
	}
*/

	
}

void
dumpdram(KL10 *kl)
{
	static char *A[8] = {
		"I   ",	// 0
		"I-PF",	// 1
		"NA  ",	// 2
		"W   ",	// 3
		"R   ",	// 4
		"R-PF",	// 5
		"RW  ",	// 6
		"RPW ",	// 7
	};
	static char *B[8] = {
		"-     ",	// 0
		"DBL AC",	// 1	DBL AC
		"DBL B ",	// 2	DBL B
		"S     ",	// 3	S
		"NA4   ",	// 4
		"AC    ",	// 5	AC
		"M     ",	// 6	M
		"B     ",	// 7	B
	};
	int i;
	/* regular instructions */
	for(kl->n.ir = 0; kl->n.ir < 0700000; kl->n.ir += 01000){
		kl->dr_adr = getdradr(kl->n.ir);
		fetchdr(kl);
		printf("%06o %03o: A:%s B:%s J:%o\n", kl->n.ir, kl->dr_adr,
			A[kl->dram_a],
			B[kl->dram_b],
			kl->dram_j);
	}
	/* jrst */
	for(kl->n.ir = 0254000; kl->n.ir < 0255000; kl->n.ir += 040){
		kl->dr_adr = getdradr(kl->n.ir);
		fetchdr(kl);
		printf("%06o %03o: A:%s B:%s J:%o\n", kl->n.ir, kl->dr_adr,
			A[kl->dram_a],
			B[kl->dram_b],
			kl->dram_j);
	}
	/* IO */
	for(kl->n.ir = 0700000; kl->n.ir < 01000000; kl->n.ir += 040){
		kl->dr_adr = getdradr(kl->n.ir);
		fetchdr(kl);
		printf("%06o %03o: A:%s B:%s J:%o\n", kl->n.ir, kl->dr_adr,
			A[kl->dram_a],
			B[kl->dram_b],
			kl->dram_j);
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
	reset(kl10);

	loaducode(kl10, "ucode/u1.txt");
//	dumpdram(kl10);

	step(kl10);
	step(kl10);
//	test(kl10);

	return 0;
}
