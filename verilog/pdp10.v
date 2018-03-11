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

		pdp10.fm_enable_sw = 1;
		pdp10.key_repeat_bypass_sw = 0;
		pdp10.rdi_sel = 4;

		pdp10.sw_power = 0;
		#20 pdp10.sw_power = 1;
	end

	initial begin: meminit
		integer i;
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
		pdp10.mem0.core['o1002] = 36'o201000_000003;
	end

	initial begin
		pdp10.ka10.ma = 3;
		pdp10.ka10.ar = 1234;
		pdp10.ka10.pc = 22;
//		pdp10.as = 3;
		pdp10.as = 'o26;
//		pdp10.as = 100000;
//		pdp10.ds = 36'o1234;
		pdp10.ds = 36'o777777777777;
//		pdp10.key_repeat_sw = 1;
//		pdp10.key_adr_stop = 1;

		#96 `TESTKEY = 1;
//		pdp10.ka10.pi_act = 1;
//		pdp10.ka10.pio = 7'b1111111;

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
