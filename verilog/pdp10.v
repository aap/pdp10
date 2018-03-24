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

	reg sc_stop_sw;
	reg fm_enable_sw;
	reg key_repeat_bypass_sw;
	reg mi_prog_dis_sw;
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


		.sc_stop_sw(sc_stop_sw),
		.fm_enable_sw(fm_enable_sw),
		.key_repeat_bypass_sw(key_repeat_bypass_sw),
		.mi_prog_dis_sw(mi_prog_dis_sw),
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

		pdp10.sc_stop_sw = 0;
		pdp10.fm_enable_sw = 1;
		pdp10.key_repeat_bypass_sw = 0;
		pdp10.mi_prog_dis_sw = 0;
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

//`include "test.inc"
`include "test_arith.inc"

	initial begin
		pdp10.ka10.ma = 3;
		pdp10.ka10.ar = 1234;
		pdp10.ka10.pc = 22;
//		pdp10.as = 3;
		pdp10.as = 'o20;
//		pdp10.as = 100000;
		pdp10.ds = 36'o102030_405060;
//		pdp10.ds = 36'o777777777777;
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
