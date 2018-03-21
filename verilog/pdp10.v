`default_nettype none
`timescale 1ns/1ns
`define simulation

module pdp10(
	input wire clk,
	input wire reset
);
	reg sw_power;
	reg key_stop_sw;
	reg key_exa_sw;
	reg key_ex_nxt_sw;
	reg key_dep_sw;
	reg key_dep_nxt_sw;
	reg key_reset_sw;
	reg key_exe_sw;
	reg key_sta_sw;
	reg key_rdi_sw;
	reg key_cont_sw;

	reg key_sing_inst;
	reg key_sing_cycle;
	reg key_adr_inst;
	reg key_adr_rd;
	reg key_adr_wr;
	reg key_adr_stop;
	reg key_adr_brk;
	reg key_par_stop;
	reg key_nxm_stop;
	reg key_repeat_sw;

	reg [0:35] ds;
	reg [18:35] as;

	reg fm_enable_sw;
	reg key_repeat_bypass_sw;
	reg [3:9] rdi_sel;


	wire iobus_iob_reset;
	wire iobus_iob_dr_split = 0;
	wire [3:9] iobus_ios;
	wire iobus_datao_clear;
	wire iobus_datao_set;
	wire iobus_cono_clear;
	wire iobus_cono_set;
	wire iobus_iob_datai;
	wire iobus_iob_coni;
	wire iobus_rdi_pulse;
	wire iobus_rdi_data = 0;
	wire [0:35] iobus_iob_out;
	wire [1:7] iobus_pi = 0;
	wire [0:35] iobus_iob_in = iobus_iob_out;


	/* KA10 */
	wire membus_rd_rq_p0;
	wire membus_wr_rq_p0;
	wire membus_rq_cyc_p0;
	wire membus_wr_rs_p0;
	wire [18:35] membus_ma_p0;
	wire [0:35] membus_mb_out_p0_p;
	wire membus_fmc_select_p0;

	/* memory 0 */
	wire [0:35] membus_mb_out_p0_0;
	wire membus_addr_ack_p0_0;
	wire membus_rd_rs_p0_0;

	wire membus_addr_ack_p0 = membus_addr_ack_p0_0;
	wire membus_rd_rs_p0 = membus_rd_rs_p0_0;
	wire [0:35] membus_mb_in_p0 = membus_mb_out_p0_p | membus_mb_out_p0_0;

	ka10 ka10(
		.clk(clk), 
		.reset(reset),
		.sw_power(sw_power),
		.key_stop_sw(key_stop_sw),
		.key_exa_sw(key_exa_sw),
		.key_ex_nxt_sw(key_ex_nxt_sw),
		.key_dep_sw(key_dep_sw),
		.key_dep_nxt_sw(key_dep_nxt_sw),
		.key_reset_sw(key_reset_sw),
		.key_exe_sw(key_exe_sw),
		.key_sta_sw(key_sta_sw),
		.key_rdi_sw(key_rdi_sw),
		.key_cont_sw(key_cont_sw),

		.key_sing_inst(key_sing_inst),
		.key_sing_cycle(key_sing_cycle),
		.key_adr_inst(key_adr_inst),
		.key_adr_rd(key_adr_rd),
		.key_adr_wr(key_adr_wr),
		.key_adr_stop(key_adr_stop),
		.key_adr_brk(key_adr_brk),
		.key_par_stop(key_par_stop),
		.key_nxm_stop(key_nxm_stop),
		.key_repeat_sw(key_repeat_sw),

		.ds(ds),
		.as(as),

		.membus_rd_rq(membus_rd_rq_p0),
		.membus_wr_rq(membus_wr_rq_p0),
		.membus_rq_cyc(membus_rq_cyc_p0),
		.membus_addr_ack(membus_addr_ack_p0),
		.membus_rd_rs(membus_rd_rs_p0),
		.membus_wr_rs(membus_wr_rs_p0),
		.membus_ma(membus_ma_p0),
		.membus_mb_out(membus_mb_out_p0_p),
		.membus_mb_in(membus_mb_in_p0),
		.membus_fmc_select(membus_fmc_select_p0),

		.iobus_iob_reset(iobus_iob_reset),
		.iobus_iob_dr_split(iobus_iob_dr_split),
		.iobus_ios(iobus_ios),
		.iobus_datao_clear(iobus_datao_clear),
		.iobus_datao_set(iobus_datao_set),
		.iobus_cono_clear(iobus_cono_clear),
		.iobus_cono_set(iobus_cono_set),
		.iobus_iob_datai(iobus_iob_datai),
		.iobus_iob_coni(iobus_iob_coni),
		.iobus_rdi_pulse(iobus_rdi_pulse),
		.iobus_rdi_data(iobus_rdi_data),
		.iobus_iob_out(iobus_iob_out),
		.iobus_pi(iobus_pi),
		.iobus_iob_in(iobus_iob_in),


		.fm_enable_sw(fm_enable_sw),
		.key_repeat_bypass_sw(key_repeat_bypass_sw),
		.rdi_sel(rdi_sel)
	);

	core161c
	#(.memsel_p0(4'b0), .memsel_p1(4'b0),
	  .memsel_p2(4'b0), .memsel_p3(4'b0))
	mem0(
		.clk(clk),
		.reset(reset),
		.power(sw_power),
		.sw_single_step(1'b0),
		.sw_restart(1'b0),

		.membus_rd_rq_p0(membus_rd_rq_p0),
		.membus_wr_rq_p0(membus_wr_rq_p0),
		.membus_rq_cyc_p0(membus_rq_cyc_p0),
		.membus_addr_ack_p0(membus_addr_ack_p0_0),
		.membus_rd_rs_p0(membus_rd_rs_p0_0),
		.membus_wr_rs_p0(membus_wr_rs_p0),
		.membus_ma_p0(membus_ma_p0[21:35]),
		.membus_sel_p0(membus_ma_p0[18:21]),
		.membus_fmc_select_p0(membus_fmc_select_p0),
		.membus_mb_in_p0(membus_mb_in_p0),
		.membus_mb_out_p0(membus_mb_out_p0_0),

		.membus_rq_cyc_p1(1'b0),
		.membus_sel_p1(4'b0),
		.membus_fmc_select_p1(1'b0),

		.membus_rq_cyc_p2(1'b0),
		.membus_sel_p2(4'b0),
		.membus_fmc_select_p2(1'b0),

		.membus_rq_cyc_p3(1'b0),
		.membus_sel_p3(4'b0),
		.membus_fmc_select_p3(1'b0)
	);
endmodule

module clock(output reg clk);
	initial
		clk = 0;
	always
		#5 clk = ~clk;
endmodule

//`define TESTKEY pdp10.key_exa_sw
//`define TESTKEY pdp10.key_dep_sw
//`define TESTKEY pdp10.key_exe_sw
`define TESTKEY pdp10.key_sta_sw
//`define TESTKEY pdp10.key_rdi_sw
//`define TESTKEY pdp10.key_ex_nxt_sw
//`define TESTKEY pdp10.key_cont_sw
//`define TESTKEY pdp10.key_stop_sw

module test;
	wire clk;
	reg reset;
	reg stop;

	clock clock(clk);
	pdp10 pdp10(.clk(clk), .reset(reset));

	initial begin
		$dumpfile("dump.vcd");
		$dumpvars();

		stop = 0;
		reset = 1;
		#8 reset = 0;
		#40000 stop = 1;
		$finish;
	end

	initial begin
		pdp10.key_stop_sw = 0;
		pdp10.key_exa_sw = 0;
		pdp10.key_ex_nxt_sw = 0;
		pdp10.key_dep_sw = 0;
		pdp10.key_dep_nxt_sw = 0;
		pdp10.key_reset_sw = 0;
		pdp10.key_exe_sw = 0;
		pdp10.key_sta_sw = 0;
		pdp10.key_rdi_sw = 0;
		pdp10.key_cont_sw = 0;

		pdp10.key_sing_inst = 0;
		pdp10.key_sing_cycle = 0;
		pdp10.key_adr_inst = 0;
		pdp10.key_adr_rd = 0;
		pdp10.key_adr_wr = 0;
		pdp10.key_adr_stop = 0;
		pdp10.key_adr_brk = 0;
		pdp10.key_par_stop = 0;
		pdp10.key_nxm_stop = 0;
		pdp10.key_repeat_sw = 0;

		pdp10.ds = 0;
		pdp10.as = 0;

		pdp10.fm_enable_sw = 0;
		pdp10.key_repeat_bypass_sw = 0;
		pdp10.rdi_sel = 4;

		pdp10.sw_power = 0;
		#20 pdp10.sw_power = 1;
	end

	function [0:35] Inst;
		input [0:8] op;
		input [9:12] ac;
		input i;
		input [14:17] x;
		input [18:35] y;
		begin
			Inst = { op, ac, i, x, y };
		end
	endfunction

	function [0:35] IoInst;
		input [10:12] op;
		input [3:11] dev;
		input i;
		input [14:17] x;
		input [18:35] y;
		begin
			IoInst = { 3'o7, dev[3:9], op, i, x, y };
		end
	endfunction

	initial begin: meminit
		integer i;
/*
		for(i = 0; i < 'o40000; i = i + 1)
			pdp10.mem0.core[i] = i + 36'o10000000;
		for(i = 0; i < 'o20; i = i + 1) begin
			pdp10.mem0.core[i] = i + 36'o1000;
			pdp10.ka10.fmem[i] = i + 36'o1000;
		end

		pdp10.mem0.core[2] = 36'o001000_000123;
		pdp10.ka10.fmem[2] = 36'o001000_000123;

		pdp10.mem0.core['o20] = 36'o200121_000001;
		pdp10.mem0.core['o21] = 36'o213121_000001;
		pdp10.mem0.core['o22] = 36'o202121_000001;
		pdp10.mem0.core['o23] = 36'o244100_000000;
		pdp10.mem0.core['o24] = 36'o262100_000000;
		pdp10.mem0.core['o25] = 36'o267100_000000;
		pdp10.mem0.core['o26] = 36'o145000_123456;
		pdp10.mem0.core['o42] = 36'o265740_000000;
		pdp10.mem0.core['o1002] = 36'o201000_000003;
*/

		for(i = 0; i < 'o40000; i = i + 1)
			pdp10.mem0.core[i] = 0;
		for(i = 0; i < 'o20; i = i + 1) begin
			pdp10.mem0.core[i] = 0;
			pdp10.ka10.fmem[i] = 0;
		end

		pdp10.ka10.fmem[1] = 36'o123000_000321;
		pdp10.ka10.fmem[2] = 36'o456000_000654;
		pdp10.ka10.fmem[3] = 36'o056000_000654;
		pdp10.ka10.fmem[4] = 36'o000003_000111;
		pdp10.ka10.fmem[5] = 36'o777776_000111;
		pdp10.ka10.fmem['o7] = 36'o777777_777777;
		pdp10.ka10.fmem['o10] = 36'o000000_000000;
		pdp10.ka10.fmem['o11] = 36'o000000_000001;
		pdp10.ka10.fmem['o17] = 36'o000000_000300;
		for(i = 0; i < 'o20; i = i + 1) begin
			pdp10.mem0.core[i] = pdp10.ka10.fmem[i];
		end

		pdp10.mem0.core['o141] = 36'o000000000001;
		pdp10.mem0.core['o142] = 36'o000000000002;
		pdp10.mem0.core['o200] = 36'o777740000100;
		pdp10.mem0.core['o300] = 36'o123456111222;
		pdp10.mem0.core['o002000] = 36'o006000001001;

		// IO tests
		pdp10.mem0.core['o20] = IoInst(`DATAO, 0, 0, 0, 'o002000);
//		pdp10.mem0.core['o20] = IoInst(`DATAO, 0, 0, 0, 'o200);

		// FWT tests
//		pdp10.mem0.core['o20] = Inst(`MOVE, 2, 0, 0, 1);
//		pdp10.mem0.core['o20] = Inst(`MOVS, 2, 0, 0, 1);
//		pdp10.mem0.core['o20] = Inst(`MOVSS, 0, 0, 0, 1);
//		pdp10.mem0.core['o20] = Inst(`MOVN, 2, 0, 0, 1);
//		pdp10.mem0.core['o20] = Inst(`MOVN, 2, 0, 0, 0);
//		pdp10.mem0.core['o20] = Inst(`MOVM, 2, 0, 0, 1);
//		pdp10.mem0.core['o20] = Inst(`MOVM, 1, 0, 0, 2);
//		pdp10.mem0.core['o20] = Inst(`MOVEM, 2, 0, 0, 1);

		// HWT tests
//		pdp10.mem0.core['o20] = Inst(`HLL, 2, 0, 0, 1);
//		pdp10.mem0.core['o20] = Inst(`HLLI, 2, 0, 0, 1);
//		pdp10.mem0.core['o20] = Inst(`HRR, 2, 0, 0, 1);
//		pdp10.mem0.core['o20] = Inst(`HRRI, 2, 0, 0, 1);
//		pdp10.mem0.core['o20] = Inst(`HRL, 2, 0, 0, 1);
//		pdp10.mem0.core['o20] = Inst(`HRLI, 2, 0, 0, 1);
//		pdp10.mem0.core['o20] = Inst(`HLR, 2, 0, 0, 1);
//		pdp10.mem0.core['o20] = Inst(`HLRI, 2, 0, 0, 1);
//		pdp10.mem0.core['o20] = Inst(`HLLO, 2, 0, 0, 1);
//		pdp10.mem0.core['o20] = Inst(`HLLE, 2, 0, 0, 1);
//		pdp10.mem0.core['o20] = Inst(`HLLZ, 2, 0, 0, 1);
//		pdp10.mem0.core['o20] = Inst(`HLLO, 2, 0, 0, 1);
//		pdp10.mem0.core['o20] = Inst(`HLLE, 2, 0, 0, 1);
//		pdp10.mem0.core['o20] = Inst(`HLLE, 2, 0, 0, 2);

		// Misc tests
//		pdp10.mem0.core['o20] = Inst('o034, 2, 0, 0, 1);
//		pdp10.mem0.core['o20] = Inst(`EXCH, 2, 0, 0, 'o200);
//		pdp10.mem0.core['o20] = Inst(`AOBJP, 4, 0, 0, 'o100);
//		pdp10.mem0.core['o20] = Inst(`AOBJP, 5, 0, 0, 'o100);
//		pdp10.mem0.core['o20] = Inst(`AOBJN, 4, 0, 0, 'o100);
//		pdp10.mem0.core['o20] = Inst(`AOBJN, 5, 0, 0, 'o100);
//		pdp10.mem0.core['o20] = Inst(`XCT, 0, 0, 0, 'o100);
//		pdp10.mem0.core['o20] = Inst(`PUSHJ, 'o17, 0, 0, 'o100);
//		pdp10.mem0.core['o20] = Inst(`PUSH, 'o17, 0, 0, 'o200);
//		pdp10.mem0.core['o20] = Inst(`POP, 'o17, 0, 0, 'o200);
//		pdp10.mem0.core['o20] = Inst(`POPJ, 'o17, 0, 0, 'o200);

		// Add/Sub tests
//		pdp10.mem0.core['o20] = Inst(`ADD, 2, 0, 0, 1);
//		pdp10.mem0.core['o20] = Inst(`ADDM, 2, 0, 0, 1);
//		pdp10.mem0.core['o20] = Inst(`SUB, 2, 0, 0, 1);

		// Boole tests
//		pdp10.mem0.core['o20] = Inst(`SETZ, 2, 0, 0, 1);
//		pdp10.mem0.core['o20] = Inst(`SETZB, 2, 0, 0, 1);
//		pdp10.mem0.core['o20] = Inst(`AND, 2, 0, 0, 1);
//		pdp10.mem0.core['o20] = Inst(`ANDCA, 2, 0, 0, 1);
//		pdp10.mem0.core['o20] = Inst(`SETM, 2, 0, 0, 1);
//		pdp10.mem0.core['o20] = Inst(`ANDCM, 2, 0, 0, 1);
//		pdp10.mem0.core['o20] = Inst(`SETA, 2, 0, 0, 1);
//		pdp10.mem0.core['o20] = Inst(`XOR, 2, 0, 0, 1);
//		pdp10.mem0.core['o20] = Inst(`IOR, 2, 0, 0, 1);
//		pdp10.mem0.core['o20] = Inst(`ANDCB, 2, 0, 0, 1);
//		pdp10.mem0.core['o20] = Inst(`EQV, 2, 0, 0, 1);
//		pdp10.mem0.core['o20] = Inst(`SETCA, 2, 0, 0, 1);
//		pdp10.mem0.core['o20] = Inst(`ORCA, 2, 0, 0, 1);
//		pdp10.mem0.core['o20] = Inst(`SETCM, 2, 0, 0, 1);
//		pdp10.mem0.core['o20] = Inst(`ORCM, 2, 0, 0, 1);
//		pdp10.mem0.core['o20] = Inst(`ORCB, 2, 0, 0, 1);
//		pdp10.mem0.core['o20] = Inst(`SETO, 2, 0, 0, 1);

		// Jump tests
//		pdp10.mem0.core['o20] = Inst(`JSR, 2, 0, 0, 1);
//		pdp10.mem0.core['o20] = Inst(`JSP, 2, 0, 0, 1);
//		pdp10.mem0.core['o20] = Inst(`JSA, 2, 0, 0, 1);
//		pdp10.mem0.core['o20] = Inst(`JRA, 4, 0, 0, 'o100);
//		pdp10.mem0.core['o20] = Inst(`JFCL, 4, 0, 0, 'o100);
//		pdp10.mem0.core['o20] = Inst(`JFCL, 'o17, 0, 0, 'o100);
//		pdp10.mem0.core['o20] = Inst(`JRST, 0, 0, 0, 'o100);
//		pdp10.mem0.core['o20] = Inst(`JRST, 'o10, 0, 0, 'o100);
//		pdp10.mem0.core['o20] = Inst(`JRST, 4, 0, 0, 'o100);
//		pdp10.mem0.core['o20] = Inst(`JRST, 2, 1, 0, 'o200);
//		pdp10.mem0.core['o20] = Inst(`JRST, 1, 0, 0, 'o100);

		// Boolean Test tests
//		pdp10.mem0.core['o20] = Inst(`TRN, 1, 0, 0, 0);
//		pdp10.mem0.core['o20] = Inst(`TRNE, 1, 0, 0, 1);
//		pdp10.mem0.core['o20] = Inst(`TRNA, 1, 0, 0, 0);
//		pdp10.mem0.core['o20] = Inst(`TRNN, 1, 0, 0, 2);
//		pdp10.mem0.core['o20] = Inst(`TLN, 1, 0, 0, 0);
//		pdp10.mem0.core['o20] = Inst(`TLNE, 1, 0, 0, 'o200000);
//		pdp10.mem0.core['o20] = Inst(`TLNA, 1, 0, 0, 0);
//		pdp10.mem0.core['o20] = Inst(`TLNN, 1, 0, 0, 'o200000);
//		pdp10.mem0.core['o20] = Inst(`TDNE, 1, 0, 0, 'o142);
//		pdp10.mem0.core['o20] = Inst(`TRZN, 1, 0, 0, 'o777);
//		pdp10.mem0.core['o20] = Inst(`TRON, 1, 0, 0, 'o777);
//		pdp10.mem0.core['o20] = Inst(`TRCN, 1, 0, 0, 'o777);
//		pdp10.mem0.core['o20] = Inst(`TLCN, 1, 0, 0, 'o777000);

		// Arithmetic Test tests
//		pdp10.mem0.core['o20] = Inst(`CAI, 'o11, 0, 0, 0);
//		pdp10.mem0.core['o20] = Inst(`CAIL, 'o11, 0, 0, 0);
//		pdp10.mem0.core['o20] = Inst(`CAIE, 'o11, 0, 0, 0);
//		pdp10.mem0.core['o20] = Inst(`CAILE, 'o11, 0, 0, 0);
//		pdp10.mem0.core['o20] = Inst(`CAIA, 'o11, 0, 0, 0);
//		pdp10.mem0.core['o20] = Inst(`CAIGE, 'o11, 0, 0, 0);
//		pdp10.mem0.core['o20] = Inst(`CAIN, 'o11, 0, 0, 0);
//		pdp10.mem0.core['o20] = Inst(`CAIG, 'o11, 0, 0, 0);
//		pdp10.mem0.core['o20] = Inst(`JUMP, 'o7, 0, 0, 'o100);
//		pdp10.mem0.core['o20] = Inst(`JUMPL, 'o7, 0, 0, 'o100);
//		pdp10.mem0.core['o20] = Inst(`JUMPE, 'o7, 0, 0, 'o100);
//		pdp10.mem0.core['o20] = Inst(`JUMPLE, 'o7, 0, 0, 'o100);
//		pdp10.mem0.core['o20] = Inst(`JUMPA, 'o7, 0, 0, 'o100);
//		pdp10.mem0.core['o20] = Inst(`JUMPGE, 'o7, 0, 0, 'o100);
//		pdp10.mem0.core['o20] = Inst(`JUMPN, 'o7, 0, 0, 'o100);
//		pdp10.mem0.core['o20] = Inst(`JUMPG, 'o7, 0, 0, 'o100);
//		pdp10.mem0.core['o20] = Inst(`AOJA, 'o7, 0, 0, 'o100);
//		pdp10.mem0.core['o20] = Inst(`SOJA, 'o7, 0, 0, 'o100);
//		pdp10.mem0.core['o20] = Inst(`SKIPA, 0, 0, 0, 'o7);
//		pdp10.mem0.core['o20] = Inst(`AOSA, 0, 0, 0, 'o7);
//		pdp10.mem0.core['o20] = Inst(`SOSA, 0, 0, 0, 'o7);

//		pdp10.mem0.core['o20] = Inst(`LSHC, 1, 0, 0, 'o7);
	end

	initial begin
		pdp10.ka10.ma = 3;
		pdp10.ka10.ar = 1234;
		pdp10.ka10.pc = 22;
//		pdp10.as = 3;
		pdp10.as = 'o20;
//		pdp10.as = 100000;
//		pdp10.ds = 36'o1234;
		pdp10.ds = 36'o777777777777;
//		pdp10.key_repeat_sw = 1;
//		pdp10.key_adr_stop = 1;

		#96 `TESTKEY = 1;
//		pdp10.ka10.pi_act = 1;
//		pdp10.ka10.pio = 7'b1111111;
//		pdp10.ka10.cpa_clk_en = 1;
//		pdp10.ka10.cpa_clk_flag = 1;
//		pdp10.ka10.cpa_pia = 1;
//		pdp10.ka10.ar_ov_flag = 1;
//		pdp10.ka10.ar_cry0_flag = 1;
//		pdp10.ka10.ar_cry1_flag = 1;
//		pdp10.ka10.ar_fov = 1;

		#1200 `TESTKEY = 0;
	end

	// IR decode test
/*	initial begin: irtest
		integer i;
		#10000;
		pdp10.ka10.ar = 0;
		pdp10.ka10.ir = 0;
		for(i = 0; i < 'o700; i = i+1)
			#10 pdp10.ka10.ir[0:8] = i;
		for(i = 'o700000; i <= 'o700340; i = i + 'o40)
			#10 pdp10.ka10.ir = i;
		#10;
	end
*/
endmodule
