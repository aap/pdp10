module ka10(
	input wire clk,
	input wire reset,

	input wire sw_power,

	// keys
	input wire key_stop_sw,
	input wire key_exa_sw,
	input wire key_ex_nxt_sw,
	input wire key_dep_sw,
	input wire key_dep_nxt_sw,
	input wire key_reset_sw,
	input wire key_exe_sw,
	input wire key_sta_sw,
	input wire key_rdi_sw,
	input wire key_cont_sw,

	input wire key_sing_inst,
	input wire key_sing_cycle,
	input wire key_adr_inst,
	input wire key_adr_rd,
	input wire key_adr_wr,
	input wire key_adr_stop,
	input wire key_adr_brk,
	input wire key_par_stop,
	input wire key_nxm_stop,
	input wire key_repeat_sw,

	input wire [0:35] ds,
	input wire [18:35] as,

	// Membus
	output wire membus_rd_rq,
	output wire membus_wr_rq,
	output wire membus_rq_cyc,
	input wire membus_addr_ack,	// pulse
	input wire membus_rd_rs,	// pulse
	output wire membus_wr_rs,	// pulse
	output wire [18:35] membus_ma,
	output wire [0:35] membus_mb_out,
	input wire [0:35] membus_mb_in,
	output wire membus_fmc_select,
	// not implemented:
	// ouput wire parity,	// pulse
	// input wire ign_parity,	// pulse

	// IO bus
	output wire iobus_iob_reset,	// pulse
	input wire iobus_iob_dr_split,
	output wire [3:9] iobus_ios,
	output wire iobus_datao_clear,	// pulse
	output wire iobus_datao_set,	// pulse
	output wire iobus_cono_clear,	// pulse
	output wire iobus_cono_set,	// pulse
	output wire iobus_iob_datai,
	output wire iobus_iob_coni,
	output wire iobus_rdi_pulse,	// pulse
	input wire iobus_rdi_data,
	output wire [0:35] iobus_iob_out,
	input wire [1:7] iobus_pi,
	input wire [0:35] iobus_iob_in,

	// maintenance panel:
	// shift cntr maint
	input fm_enable_sw,
	input key_repeat_bypass_sw,
	// mi prog dis
	input wire [3:9] rdi_sel
);

	// TODO: This is used for a second processor with the same memory
	wire ma_trap_offset = 0;
	// Trap floating point and byte ops
	wire ir_fp_trap_sw = 0;

	// ignore parity checks
	wire pn_par_even = 0;

	/* Membus */
	assign membus_rd_rq = mc_rd;
	assign membus_wr_rq = mc_wr;
	assign membus_rq_cyc = mc_req_cyc;
	assign membus_wr_rs = mc_wr_rs;
	assign membus_ma = mai;
	assign membus_fmc_select = 0;
	assign membus_mb_out =
		mc_membus_fm_ar1 ? ar :
		0;
	wire [0:35] membus_pulse;
	pg36 membus_pg(.clk(clk), .reset(reset),
		.in(membus_mb_in),
		.p(membus_pulse));


	/* IObus */
	assign iobus_iob_reset = iot_reset;	// pulse
	wire iob_dr_split = iobus_iob_dr_split;
	assign iobus_ios = ir[3:9];
	assign iobus_datao_clear = iot_datao_clr;	// pulse
	assign iobus_datao_set = iot_datao_set;	// pulse
	assign iobus_cono_clear = iot_cono_clr;	// pulse
	assign iobus_cono_set = iot_cono_set;	// pulse
	assign iobus_iob_datai = iob_datai;
	assign iobus_iob_coni = iob_status;
	assign iobus_rdi_pulse = iot_rdi_pulse;	// pulse
//	input wire iobus_rdi_data,
	assign iobus_iob_out = iob_fm_ar ? ar :
		cpa_status ? cpa_iob :
		pi_status ? pi_iob :
		0;

	wire [1:7] iob_pi = iobus_pi | {7{ cpa_req_enable}}&cpa_req;
	wire [0:35] iob = iobus_iob_in | iobus_iob_out;
	wire iob_status = iot_data_xfer & (iot_consx | iot_coni);
	wire iob_datai = iot_datai & iot_data_xfer;
	wire iob_fm_ar = iot_out_going & iot_data_xfer;

	wire bio_cpa_sel = ir[3:9] == 0;
	wire bio_pi_sel = ir[3:9] == 1;
	wire bio_ptp_sel = ir[3:9] == 'o20;
	wire bio_ptr_sel = ir[3:9] == 'o21;
	wire bio_tty_sel = ir[3:9] == 'o24;


	/* MR */
	wire mr_pwr_clr;
	wire mr_start;
	wire mr_clr;

	pg mr_pg1(.clk(clk), .reset(reset), .in(sw_power), .p(mr_pwr_clr));
	pa mr_pa1(.clk(clk), .reset(reset),
		.in(mr_pwr_clr |
		    kt0a & key_rdi & ~run |
		    kst2),
		.p(mr_start));
	pa mr_pa2(.clk(clk), .reset(reset),
		.in(mr_start |
		    kt1 & ~key_cont |
		    it0),
		.p(mr_clr));		// TODO


	/*
	 * KEY
	 */
	reg key_examine, key_ex_nxt;
	reg key_deposit, key_dep_nxt;
	reg key_reset;
	reg key_execute;
	reg key_start;
	reg key_rdi;
	reg key_cont;
	reg key_rept_sync;
	reg key_pi_inh;
	reg key_sync;
	reg key_sync_rq;
	reg run;
	reg key_rim;
	reg key_f1;
	reg key_rdi_part2;
	wire key_manual = key_rdi_sw | key_sta_sw |
		key_cont_sw | key_reset_sw |
		key_exe_sw | key_exa_sw |
		key_dep_sw | key_ex_nxt_sw |
		key_dep_nxt_sw;
	wire key_next = key_dep_nxt | key_ex_nxt;
	wire key_mem_ref = key_dep_nxt | key_ex_nxt | key_examine | key_deposit;
	wire key_ex_OR_ex_nxt = key_examine | key_ex_nxt;
	wire key_dep_OR_dep_nxt = key_deposit | key_dep_nxt;
	wire key_dep_OR_dep_nxt_OR_exe = key_deposit | key_dep_nxt | key_execute;
	wire key_as_strobe_en = key_examine | key_deposit | key_start;
	wire kt1_en = ~run &
		(key_start | key_rdi | key_examine | key_deposit | key_execute);
	wire key_sync_ops = key_examine | key_deposit | key_execute;
	wire key_mid_inst_stop = mc_stop | sc_stop;
	wire key_prog_stop = ir_jrst & ir[10];
	wire key_fcn_strobe;
	wire key_fcn_clr;
	wire key_rept_dly;
	wire key_clr = mr_clr;
	wire key_run_clr = kst1 |
		et0 & (key_prog_stop | key_sing_inst);
	wire key_it0_en = run & ~pi_ov & (e_xctf | ~key_sync);
	wire key_at_inh;
	wire kt0;
	wire kt0a;
	wire kt1;
	wire kt2;
	wire kt3;
	wire kt3a;
	wire kt4;
	wire knt1;
	wire knt2;
	wire knt3;
	wire kct0;
	wire kst1;
	wire kst2;
	wire key_rdi_dly;
	wire key_rdi_done = st1 & key_rim & pi_ov;
	wire key_done;

	wire key_rept_in, key_at_inh_in;
	pa_dcd4 key_pa1(.clk(clk), .reset(reset),
		.p1(mr_pwr_clr), .l1(1'b1),
		.p2(kt0), .l2(run & (key_ex_nxt | key_dep_nxt | key_start | key_rdi)),
		.p3(key_done), .l3(~key_rept_sync),
		.p4(~key_rept_dly), .l4(~key_rept_sync),
		.q(key_fcn_clr));
	pa_dcd key_pa2(.clk(clk), .reset(reset), 
		.p(~key_manual_D),
		.l(~key_rept_sync), 
		.q(key_fcn_strobe));
	pa_dcd2 key_pa3(.clk(clk), .reset(reset),
		.p1(~key_fcn_strobe_D), .l1(1'b1),
		.p2(~key_rept_dly), .l2(key_rept_sync),
		.q(kt0));
	pa key_pa4(.clk(clk), .reset(reset), .in(kt0), .p(kt0a));
	pa key_pa5(.clk(clk), .reset(reset),
		// TODO
		.in(kt0a_D & kt1_en |
		    knt3_D |
		    st9 & key_sync & ~e_xctf),
		.p(kt1));
	pa key_pa6(.clk(clk), .reset(reset), .in(kt1_D), .p(kt2));
	pa key_pa7(.clk(clk), .reset(reset), .in(kt2_D), .p(kt3));
	pa key_pa8(.clk(clk), .reset(reset), .in(kt3_D), .p(kt3a));
	pa key_pa9(.clk(clk), .reset(reset),
		.in(kt3_D & key_start |
		    mc_rst1 & key_f1 |
		    kct0_D),
		.p(kt4));
	pa key_pa10(.clk(clk), .reset(reset),
		.in(kt0a & (key_cont & key_mid_inst_stop |
		            run & key_cont & ~key_mid_inst_stop) |
		    kt3a & key_execute |
		    kt4 |
		    kst2 |
		    key_run_clr & key_cont |
		    key_rdi_done),
		.p(key_done));
	pa key_pa11(.clk(clk), .reset(reset),
		.in(kt0a & key_next & ~run),
		.p(knt1));
	pa key_pa12(.clk(clk), .reset(reset),
		.in(knt1_D),
		.p(knt2));
	pa key_pa13(.clk(clk), .reset(reset),
		.in(knt2_D),
		.p(knt3));
	pa_dcd2 key_pa14(.clk(clk), .reset(reset),
		.p1(key_done), .l1(key_rept_sync),
		.p2(kt0), .l2(key_repeat_bypass_sw),
		.q(key_rept_in));
	pa key_pa15(.clk(clk), .reset(reset),
		.in(kt0a & ~run & key_cont & ~key_mid_inst_stop),
		.p(kct0));
	pa_dcd2 key_pa16(.clk(clk), .reset(reset),
		.p1(key_stop_sw), .l1(1'b1),
		.p2(kt0), .l2(key_reset & run),
		.q(kst1));
	pa_dcd2 key_pa17(.clk(clk), .reset(reset),
		.p1(key_stop_sw), .l1(1'b1),
		.p2(kt0), .l2(key_reset & run),
		.q(kst1));
	pa_dcd key_pa18(.clk(clk), .reset(reset), 
		.p(~key_at_inh), .l(key_reset), 
		.q(kst2));

	wire key_manual_D;
	wire key_fcn_strobe_D;
	wire kt0a_D, kt1_D, kt2_D, kt3_D;
	wire knt1_D, knt2_D, knt3_D;
	wire kct0_D;
	wire kst1_D;
	// SIM: this delay is 30ms really, to debounce the keys
	ldly0_2us key_dly1(.clk(clk), .reset(reset), 
		.p(key_manual), .l(1'b1),
		.q(key_manual_D));
	ldly1us key_dly2(.clk(clk), .reset(reset),
		.p(key_fcn_strobe), .l(1'b1),
		.q(key_fcn_strobe_D));
	dly165ns key_dly3(.clk(clk), .reset(reset), .in(kt0a), .p(kt0a_D));
	dly90ns key_dly4(.clk(clk), .reset(reset), .in(kt1), .p(kt1_D));
	dly90ns key_dly5(.clk(clk), .reset(reset), .in(kt2), .p(kt2_D));
	dly265ns key_dly6(.clk(clk), .reset(reset), .in(kt3), .p(kt3_D));
	dly90ns key_dly7(.clk(clk), .reset(reset), .in(knt1), .p(knt1_D));
	dly90ns key_dly8(.clk(clk), .reset(reset), .in(knt2), .p(knt2_D));
	dly90ns key_dly9(.clk(clk), .reset(reset), .in(knt3), .p(knt3_D));
	dly165ns key_dly10(.clk(clk), .reset(reset), .in(kct0), .p(kct0_D));
	// TODO: this delay has to be adjustable!
	ldly1us key_dly11(.clk(clk), .reset(reset),
		.p(key_rept_in), .l(1'b1),
		.q(key_rept_dly));
	ldly100us key_dly12(.clk(clk), .reset(reset),
		.p(kst1), .l(1'b1),
		.q(kst1_D));
	ldly100us key_dly13(.clk(clk), .reset(reset),
		.p(key_at_inh_in), .l(1'b1),
		.q(key_at_inh));
	ldly1_5us key_dly14(.clk(clk), .reset(reset),
		.p(kt0), .l(key_rdi & ~run),
		.q(key_rdi_dly));

	wire key_rept_sync_clr, key_rept_sync_set;
	pa_dcd2 key_dcd1(.clk(clk), .reset(reset),
		.p1(key_done), .l1(~key_repeat_sw),
		.p2(key_reset_sw), .l2(1'b1),
		.q(key_rept_sync_clr));
	pa_dcd2 key_dcd2(.clk(clk), .reset(reset),
		.p1(kt0), .l1(key_reset & ~run),
		.p2(~kst1_D), .l2(1'b1),
		.q(key_at_inh_in));

	always @(posedge clk) begin
		if(mr_pwr_clr)
			key_rept_sync <= 0;
		if(key_fcn_clr) begin
			key_examine <= 0;
			key_ex_nxt <= 0;
			key_deposit <= 0;
			key_dep_nxt <= 0;
			key_reset <= 0;
			key_execute <= 0;
			key_start <= 0;
			key_rdi <= 0;
			key_cont <= 0;
		end
		if(mr_start) begin
			key_sync <= 0;
			key_sync_rq <= 0;
			run <= 0;
			key_rim <= 0;
		end
		if(key_clr) begin
			key_f1 <= 0;
			key_pi_inh <= 0;
		end
		if(ex_clr)
			key_rdi_part2 <= 0;
		if(key_run_clr)
			run <= 0;
		if(key_fcn_strobe) begin
			key_examine <= key_exa_sw;
			key_ex_nxt <= key_ex_nxt_sw;
			key_deposit <= key_dep_sw;
			key_dep_nxt <= key_dep_nxt_sw;
			key_reset <= key_reset_sw;
			key_execute <= key_exe_sw;
			key_start <= key_sta_sw;
			key_rdi <= key_rdi_sw;
			key_cont <= key_cont_sw;
		end
		if((key_fcn_strobe | kt0) & key_repeat_sw)
			key_rept_sync <= 1;
		if(key_rept_sync_clr)
			key_rept_sync <= 0;
		if(key_rept_sync_set)
			key_rept_sync <= 1;
		if(key_rdi_done) begin
			key_rim <= 0;
			if(~key_sing_inst)
				run <= 1;
		end
		if(kt0a & key_cont & ~key_mid_inst_stop)
			run <= 1;
		if(kt0a & run & key_sync_ops)
			key_sync_rq <= 1;
		if(kt2 & key_execute)
			key_pi_inh <= 1;
		if(kt3) begin
			if(key_start)
				run <= 1;
			if(key_mem_ref)
				key_f1 <= 1;
			key_sync <= 0;
			key_sync_rq <= 0;
		end
		if(kt3a & key_rdi)
			key_rim <= 1;
		if(kt4)
			key_f1 <= 0;
		if(ft9 & key_sync_rq)
			key_sync <= 1;
	end




	/* I */
	reg if0;
	wire it0;
	wire it1;

	pa i_pa1(.clk(clk), .reset(reset),
		.in(kt4 & run |
		    pi_t0_D |
		    st9 & key_it0_en),
		.p(it0));
	pa i_pa2(.clk(clk), .reset(reset),
		// TODO
		.in(kt3a & (key_execute | key_rim) |
		    mc_rst1 & if0),
		.p(it1));

	always @(posedge clk) begin
		if(mr_start | it1 | key_at_inh)
			if0 <= 0;
		if(it0 | at4)
			if0 <= 1;
	end

	/* A */
	reg af2;
	wire at1;
	wire at2;
	wire at3;
	wire at4;
	wire at6;

	pa a_pa1(.clk(clk), .reset(reset),
		.in(it1 & ~pi_rq & ir[14:17] != 0),
		.p(at1));
	pa a_pa2(.clk(clk), .reset(reset),
		.in(at1_D & mc_fm_en |
		    mc_rst1 & af2),
		.p(at2));
	pa a_pa3(.clk(clk), .reset(reset),
		.in(at2_D |
		    it1 & ~pi_rq & ir[14:17] == 0),
		.p(at3));
	pa a_pa4(.clk(clk), .reset(reset),
		.in(at3_D & ir[13]),
		.p(at4));
	pa a_pa6(.clk(clk), .reset(reset),
		.in(at3_D & ~ir[13]),
		.p(at6));

	wire at1_D, at2_D, at3_D, at6_D;
	dly90ns a_dly1(.clk(clk), .reset(reset),
		.in(at1), .p(at1_D));
	dly90ns a_dly2(.clk(clk), .reset(reset),
		.in(at2), .p(at2_D));
	dly90ns a_dly3(.clk(clk), .reset(reset),
		.in(at3), .p(at3_D));
	dly90ns a_dly4(.clk(clk), .reset(reset),
		.in(at6), .p(at6_D));

	always @(posedge clk) begin
		if(mr_clr | at3)
			af2 <= 0;
		if(at1)
			af2 <= 1;
	end


	/* F */
	reg ff1;
	reg ff2;
	reg ff4;
	wire ft0;
	wire ft1;
	wire ft1a;
	wire ft2;
	wire ft3;
	wire ft4;
	wire ft4a;
	wire ft5;
	wire ft6;
	wire ft7;
	wire ft8;
	wire ft9;

	wire fce = ir_as_dir | ir_fwt_dir | hwt_dir |
		ir_skipx | ir_camx | ir_test_fce |
		ir_push | ir_fp_NOT_imm | ir_md_fce |
		byte_ptr_not_inc | lb_byte_load | iot_datao |
		ir_boole_dir & ~ir_boole_0 & ~ir_boole_5 & ~ir_boole_12 & ~ir_boole_17 |
		ir_ufa | db_byte_dep;
	wire fce_pse = ir_as_mem | ir_as_both | ir_fwt_self | hwt_self |
		ir_dfn | ir_exch | ir_xosx |
		byte_ptr_inc | iot_blk |
		ir_boole & ir[7] & ~ir_boole_0 & ~ir_boole_5 & ~ir_boole_12 & ~ir_boole_17 |
		hwt_3_let & hwt_mem;
	wire fac_inh = ir_fwt_dir | ir_fwt_imm | ir_fwt_self | hwt_self |
		ir_boole_0 | ir_boole_3 | ir_boole_14 | ir_boole_17 |
		ir_skips | byte_ptr_inc | byte_ptr_not_inc | lb_byte_load |
		ir_xct | ir_uuo | ir_iot | ir_254_7 | ir_jsr | ir_jsp |
		ir_hwt & ~hwt_3_let & ~hwt_mem;
	wire fac2 = ir_ashc | ir_rotc | ir_lshc | ir_div | ir_fdvl;
	wire fcc_aclt = ir_jra | ir_blt;
	wire fcc_acrt = ir_pop | ir_popj;

	pa f_pa1(.clk(clk), .reset(reset),
		.in(at6 & fce),
		.p(ft0));
	pa f_pa2(.clk(clk), .reset(reset),
		.in(at6_D & fce_pse),
		.p(ft1));
	pa f_pa3(.clk(clk), .reset(reset),
		.in(at6 & ~ir_fp_imm & ~fce_pse & ~fce |
		    mc_rst1 & ff1 |
		    ft8_D),
		.p(ft1a));
	pa f_pa4(.clk(clk), .reset(reset),
		.in(ft1a & ~fac_inh),
		.p(ft2));
	pa f_pa5(.clk(clk), .reset(reset),
		.in(ft2_D & mc_fm_en |
		    mc_rst1 & ff2),
		.p(ft3));
	pa f_pa6(.clk(clk), .reset(reset),
		.in(ft3_D & fac2),
		.p(ft4));
	pa f_pa7(.clk(clk), .reset(reset),
		.in(ft4_D & mc_fm_en),
		.p(ft5));
	pa f_pa8(.clk(clk), .reset(reset),
		.in(ft5_D |
		    mc_rst1 & ff4),
		.p(ft4a));
	pa f_pa9(.clk(clk), .reset(reset),
		.in(ft3_D & fcc_aclt),
		.p(ft6));
	pa f_pa10(.clk(clk), .reset(reset),
		.in(ft3_D & fcc_acrt |
		    ft6_D),
		.p(ft7));
	pa f_pa11(.clk(clk), .reset(reset),
		.in(at6 & ir_fp_imm),
		.p(ft8));
	pa f_pa12(.clk(clk), .reset(reset),
		.in(ft1a & fac_inh |
		    ft3 & ~fac2 & ~fcc_aclt & ~fcc_acrt |
		    ft4a),
		.p(ft9));

	wire ft2_D, ft3_D, ft4_D, ft5_D, ft6_D, ft8_D;
	wire ft9_D1, ft9_D2;
	dly100ns f_dly1(.clk(clk), .reset(reset), .in(ft2), .p(ft2_D));
	dly90ns f_dly2(.clk(clk), .reset(reset), .in(ft3), .p(ft3_D));
	dly90ns f_dly3(.clk(clk), .reset(reset), .in(ft4), .p(ft4_D));
	dly90ns f_dly4(.clk(clk), .reset(reset), .in(ft5), .p(ft5_D));
	dly115ns f_dly5(.clk(clk), .reset(reset), .in(ft6), .p(ft6_D));
	dly65ns f_dly6(.clk(clk), .reset(reset), .in(ft8), .p(ft8_D));
	dly90ns f_dly7(.clk(clk), .reset(reset), .in(ft9), .p(ft9_D1));
	dly265ns f_dly8(.clk(clk), .reset(reset), .in(ft9), .p(ft9_D2));

	always @(posedge clk) begin
		if(mr_clr) begin
			ff1 <= 0;
			ff2 <= 0;
			ff4 <= 0;
		end
		if(ft0 | ft1)
			ff1 <= 1;
		if(ft1a)
			ff1 <= 0;
		if(ft2)
			ff2 <= 1;
		if(ft3)
			ff2 <= 0;
		if(ft4 | ft7)
			ff4 <= 1;
		if(ft4a)
			ff4 <= 0;
	end


	/* E */
	reg e_uuof;
	reg e_xctf;
	wire e_long = ir_boole_2 | ir_boole_10 | ir_boole_13 | ir_boole_16 |
		hwt_e_long | ir_test |
		ir_26x_e_long | key_prog_stop | ir_dfn | ir_idiv | ir_fsc | ir_blt |
		ir_div_OR_fdvl | ir_jffo;
	wire ef0_long = ir_as | ir_21x | ir_3xx |
		ir_aobjp | ir_aobjn | ir_260_3 |
		ir_idiv | ir_fsb | iot_blk |
		ir_dfn | ir_fdv_NOT_l | ir_jffo;
	wire e_long_OR_st_inh = e_long | st_inh;
	wire et0;
	wire et0_del, et0_dela;
	wire et1;
	wire et2;
	wire et2b_del;

	pa e_pa1(.clk(clk), .reset(reset),
		.in(ft9_D1 & ~ef0_long |
		    ft9_D2 & ef0_long),
		.p(et0));
	pa e_pa2(.clk(clk), .reset(reset),
		.in(et0_del & e_long),
		.p(et1));
	pa e_pa3(.clk(clk), .reset(reset),
		.in(et1_D),
		.p(et2));

	wire et1_D;
	dly140ns e_dly1(.clk(clk), .reset(reset), .in(et0), .p(et0_del));
	dly165ns e_dly2(.clk(clk), .reset(reset), .in(et0), .p(et0_dela));
	dly215ns e_dly3(.clk(clk), .reset(reset), .in(et1), .p(et1_D));
	dly90ns e_dly4(.clk(clk), .reset(reset), .in(et2), .p(et2b_del));

	always @(posedge clk) begin
		if(mr_start | it1) begin
			e_uuof <= 0;
			e_xctf <= 0;
		end
		if(et0 & ir_uuo)
			e_uuof <= 1;
		if(et0 & (ir_uuo | ir_xct) | key_rdi_done)
			e_xctf <= 1;
	end


	/* S */
	// The exact flow is a bit hard to understand from the prints
	// A fast store cycle does not go through ST2 and can
	//     write AR to a fast AC
	//     (read/)write AR to memory (FCE PSE, SCE)
	// control has to go through ST2 to
	//     write AR to AC memory
	//     write MQ to a second AC (SAC2)
	//     write BR to memory (SAR != BR)
	// From ST2:
	//          FCE PSE -> ST5 (complete memory read/write)
	//     else SAR != BR || SCE -> ST6 (write to memory)
	//     else SAC2 -> ST7 (write second AC)
	//     else -> ST9 (ST2 only because no fast ACs)
	reg sf1;
	reg sf6;
	reg sf8;
	wire sce = ir_jsr | ir_uuo | ir_fwt_mem |
		ir_fp_mem | ir_fp_both | ir_md_sce |
		iot_datai | iot_coni | hwt_sce |
		ir_boole & ir[7] & ~fce_pse |
		db_byte_dep;
	wire sar_ne_br = ir_push | ir_pushj | ir_pop |
		ir_jsa | ir_exch | ir_dfn;
	wire sac2 = ir_ashc | ir_fp_long | ir_md_sac2 |
		ir_lshc | ir_rotc;
	wire sac_eq_0 = ir[9:12] == 0;
	wire sac_inh = ir_md_sac_inh | db_byte_dep |
		ir_fp_mem | ir_boole_mem | ir_fwt_mem | hwt_mem |
		ir_cax | ir_jumpx | ir_txnx | ir_jsr | ir_254_7 | ir_uuo |
		ir_iot | ir_as_mem | ir_ibp |
		(ir_fwt_self | hwt_self | ir_skips) & sac_eq_0;
	wire st_inh = // TODO: sr_op
		ir_md | ir_fp | ir_blt | ir_iot | ir_fsc |
		ir_ufa | byte_ptr_inc | byte_ptr_not_inc |
		lb_byte_load | db_byte_dep | ir_jffo;
	wire sar_ne_br_OR_sac2 = sar_ne_br | sac2;
	wire sac_inh_OR_fm_en = sac_inh | mc_fm_en;
	wire sce_OR_fce_pse = sce | fce_pse;
	wire st0;
	wire st1;
	wire st1a;
	wire st2;
	wire st5;
	wire st6;
	wire st6a;
	wire st7;
	wire st8;
	wire st9;

	pa s_pa1(.clk(clk), .reset(reset),
		// TODO
		.in(iot_t4 & ~iot_consx |
		    iot_t5),
		.p(st0));
	pa s_pa2(.clk(clk), .reset(reset),
		.in(et2b_del & ~st_inh |
		    et0_del & ~e_long_OR_st_inh |
		    st0_D),
		.p(st1));
	pa s_pa3(.clk(clk), .reset(reset),
		// TODO
		.in(st1 & ex_pi_sync & sac_inh_OR_fm_en &
		          ~sce_OR_fce_pse & ~sar_ne_br_OR_sac2),
		.p(st1a));
	pa s_pa4(.clk(clk), .reset(reset),
		.in(mc_rst1 & sf1 |
		    st1 & sac_inh_OR_fm_en & sar_ne_br_OR_sac2),
		.p(st2));
	pa s_pa5(.clk(clk), .reset(reset),
		.in(st1 & sac_inh_OR_fm_en & fce_pse & ~sar_ne_br_OR_sac2 |
		    st2 & fce_pse),
		.p(st5));
	pa s_pa6(.clk(clk), .reset(reset),
		.in(st1 & sac_inh_OR_fm_en & sce & ~sar_ne_br_OR_sac2 |
		    st2 & ~fce_pse & sar_ne_br |
		    st2 & sce & ~sar_ne_br),	// SCE implies ~FCE PSE
		.p(st6));
	pa s_pa7(.clk(clk), .reset(reset),
		.in(mc_rst1 & sf6),
		.p(st6a));
	pa s_pa8(.clk(clk), .reset(reset),
		.in(st6a & sac2 |
		    st2 & ~sce_OR_fce_pse & ~sar_ne_br & sac2),
		.p(st7));
	pa s_pa9(.clk(clk), .reset(reset), .in(st7_D), .p(st8));
	pa s_pa10(.clk(clk), .reset(reset),
		// TODO
		.in(st1 & ~ex_pi_sync & sac_inh_OR_fm_en &
		          ~sce_OR_fce_pse & ~sar_ne_br_OR_sac2 |
		    st1a |
		    st2 & ~sce_OR_fce_pse & ~sar_ne_br_OR_sac2 |
		    st6a & ~sac2 |
		    st8 & mc_fm_en |
		    mc_rst1 & sf8),
		.p(st9));

	wire st0_D, st1_D, st7_D;
	dly90ns s_dly1(.clk(clk), .reset(reset), .in(st0), .p(st0_D));
	dly90ns s_dly2(.clk(clk), .reset(reset), .in(st1), .p(st1_D));
	dly115ns s_dly3(.clk(clk), .reset(reset), .in(st7), .p(st7_D));

	always @(posedge clk) begin
		if(mr_clr) begin
			sf1 <= 0;
			sf6 <= 0;
			sf8 <= 0;
		end
		if(st1 & ~sac_inh_OR_fm_en)
			sf1 <= 1;
		if(st2)
			sf1 <= 0;
		if(st5 | st6)
			sf6 <= 1;
		if(st6a)
			sf6 <= 0;
		if(st8 & ~mc_fm_en)
			sf8 <= 1;
		if(st9)
			sf8 <= 0;
	end


	/* PI */
	reg pi_act;
	reg pi_ov;
	reg pi_cyc;
	reg [1:7] pih;
	reg [1:7] pir;
	reg [1:7] pio;
	wire [1:7] pi_req = pir & ~pih & pi_ok;
	wire [1:7] pi_ok = { pi_act, ~pir[1:6] & ~pih[1:6] & pi_ok[1:6] };
	wire [32:34] pi_enc;
	wire pi_rq = (pi_req != 0) & ~pi_cyc & ~key_pi_inh;
	wire pi_data_io = iot_datao | iot_datai;
	wire pi_sel = bio_pi_sel;
	wire pi_status = pi_sel & iob_status;
	// Accept (hold) PI request by any non-IO instruction or
	// a DATA/BLK instruction in the first slot.
	// If we don't but are in a PI cycle, we'll stay in there!
	wire pi_hold = pi_cyc & (~ir_iot | ~pi_ov & pi_data_io);
	// Dismiss PI request with a JRST 10,
	// or if we do IO in the first slot.
	// This means a DATA/BLK in the first slot will hold AND dismiss a PI request
	wire pi_restore = ir_jrst & ir[9] |
		 pi_cyc & ~pi_ov & pi_data_io;
	wire pi_ov_en = pi_cyc | key_rim;

	wire pi_reset =
		mr_start |
		iot_cono_clr & pi_sel & iob[23];
	wire pi_cono_set = iot_cono_set & pi_sel;
	wire pio_set = pi_cono_set & iob[25];
	wire pio_clr = pi_cono_set & iob[26];
	wire pir_fm_iob1 = pi_cono_set & iob[24];
	wire pir_stb = mc_rq_pulse & ~pi_cyc;
	wire pih_fm_pi_chrq = ft9 & pi_hold;
	wire pi_ok_clrs_pih = et0 & pi_restore;
	wire pi_t0;

	assign pi_enc[32] = pi_req[4] | pi_req[5] | pi_req[6] | pi_req[7];
	assign pi_enc[33] = pi_req[2] | pi_req[3] | pi_req[6] | pi_req[7];
	assign pi_enc[34] = pi_req[1] | pi_req[3] | pi_req[5] | pi_req[7];

	wire [18:35] pi_iob = {
		cpa_pwr_fail, cpa_par_err, cpa_par_enb,
		pih, pi_act, pio };

	pa pi_pa0(.clk(clk), .reset(reset),
		.in(it1 & pi_rq |
		    st9 & pi_ov),
		.p(pi_t0));
	wire pi_t0_D;
	dly90ns pi_dly0(.clk(clk), .reset(reset), .in(pi_t0), .p(pi_t0_D));

	always @(posedge clk) begin
		if(mr_start) begin
			pi_ov <= 0;
			pi_cyc <= 0;
		end
		if(st1 & pi_hold)
			pi_cyc <= 0;
		if(pi_t0)
			pi_cyc <= 1;
		if(st1 & pi_hold | key_rdi_done)
			pi_ov <= 0;
		if(et0 & iot_blk & pi_ov_en & ad_cry[0])
			pi_ov <= 1;
		if(pi_reset) begin
			pih <= 0;
			pir <= 0;
			pio <= 0;
			pi_act <= 0;
		end else if(pir_stb)
			pir <= pir | iob_pi & pio;
		else if(pir_fm_iob1)
			pir <= pir | iob[29:35];
		else
			pir <= pir & ~pih;
		if(pih_fm_pi_chrq)
			pih <= pih | pi_req;
		if(pi_ok_clrs_pih)
			pih <= pih & ~pi_ok;
		if(pi_cono_set) begin
			if(iob[27] &  pi_act) pi_act <= 0;
			if(iob[28] & ~pi_act) pi_act <= 1;
		end
		if(pio_clr & ~pio_set)
			pio <= pio & ~iob[29:35];
		if(~pio_clr & pio_set)
			pio <= pio | iob[29:35];
		if(pio_clr & pio_set)
			pio <= pio ^ iob[29:35];
	end


	/* EX */
	reg ex_user;
	reg ex_ill_op;
	reg ex_pi_sync;
	reg ex_mode_sync;
	reg ex_iot_user;
	wire ex_clr = mr_start | iot_datao_clr & bio_cpa_sel;
	wire ex_set = iot_datao_set & bio_cpa_sel;
	wire ex_allow_iots = ex_iot_user | ~ex_user;
	wire ex_trap_cond = ex_pi_sync | ex_ill_op;
	wire ex_rel = ex_user & ~ex_trap_cond &
		~ma18_31_eq_0 & ~mai_fma_sel &
		~key_f1;
	wire ex_non_rel_uuo = ir_uuo &
		(~ex_user | ir[2] | ir[3] | ir[4:8] == 0);

	always @(posedge clk) begin
		if(mr_start) begin
			ex_user <= 0;
			ex_ill_op <= 0;
			ex_iot_user <= 0;
		end
		if(mr_clr) begin
			if(~pi_cyc)	// REV
				ex_pi_sync <= 0;
			ex_mode_sync <= 0;
		end else if(pi_cyc)
			ex_pi_sync <= 1;

		if(et0_del & ex_trap_cond & ar_fm_pcJ_et0)
			ex_user <= 0;
		if(mr_clr & ex_mode_sync)
			ex_user <= 1;

		if(et0 & ex_non_rel_uuo)
			ex_ill_op <= 1;
		if(et0_del & ar_fm_pcJ_et0 |
		   et0 & iot_blk)
			ex_ill_op <= 0;

		if(arf_flags_fm_brJ) begin
			if(~br[6])
				ex_iot_user <= 0;
			else if(br[6] & ~ex_user)
				ex_iot_user <= 1;
		end
		if(arf_flags_fm_brJ & br[5] |
		   et0 & ir_jrst & ir[12])
			ex_mode_sync <= 1;
	end

	/* PR RL */
	reg [18:25] pr;
	reg [18:25] prb;
	reg [18:25] rl;
	reg [18:25] rlb;
	reg pr_wr_prot;
	wire [18:25] rla = rl + ma[18:25];
	wire [18:25] rlc = rlb + ma[18:25];

	wire pr1_ill_adr = ma[18:25] > pr;
	wire pr2_ill_adr = ma[18:25] > prb;
	// Addresses in the upper half of memory can
	// be protected and relocated by a second pair
	// of registers, PRB/RLB.
	// Both PR and PRB count words starting at location 0.
	wire pra_ill_adr =
		ex_rel &
		pr1_ill_adr &
		(pr2_ill_adr | ~ma[18] | pr_wr_prot) &
		(pr2_ill_adr | ~ma[18] | mc_wr);

	always @(posedge clk) begin
		if(ex_clr) begin
			pr <= 0;
			prb <= 0;
			pr_wr_prot <= 0;
			rl <= 0;
			rlb <= 0;
		end
		if(ex_set) begin
			pr <= iob[0:7];
			prb <= iob[9:16];
			pr_wr_prot <= iob[17];
			rl <= iob[18:25];
			rlb <= iob[27:34];
		end
	end


	/* CPA */
	reg cpa_pwr_fail;
	reg cpa_adr_break;
	reg cpa_par_err;
	reg cpa_par_enb;
	reg cpa_pdl_ov;
	reg cpa_mem_prot_flag;
	reg cpa_non_ex_mem;
	reg cpa_clk_en;
	reg cpa_clk_flag;
	reg cpa_fov_en;
	reg cpa_ar_ov_en;
	reg [33:35] cpa_pia;

	wire cpa_req_enable =	// not named
		cpa_pwr_fail |
		cpa_adr_break |
		cpa_par_enb & cpa_par_err |
		cpa_pdl_ov |
		cpa_mem_prot_flag |
		cpa_non_ex_mem |
		cpa_clk_en & cpa_clk_flag |
		cpa_fov_en & ar_fov |
		cpa_ar_ov_en & ar_ov_flag;
	wire [1:7] cpa_req = { cpa_req_enable, 7'b0 } >> cpa_pia;
	wire cpa_status = bio_cpa_sel & iob_status;

	wire cpa_pdl_ov_set =
		et0 & (ir_push | ir_pushj) & ad_cry[0] |
		et0 & ir_pops & ~ad_cry[0];
	wire cpa_cono_set = iot_cono_set & bio_cpa_sel;

	wire [18:35] cpa_iob = {
		1'b0, cpa_pdl_ov, ex_iot_user,
		cpa_adr_break, cpa_mem_prot_flag, cpa_non_ex_mem,
		1'b0, cpa_clk_en, cpa_clk_flag,
		1'b0, cpa_fov_en, ar_fov,
		ma_trap_offset, cpa_ar_ov_en, ar_ov_flag,
		cpa_pia };

	always @(posedge clk) begin
		if(mr_start) begin
			cpa_pwr_fail <= 0;
			cpa_adr_break <= 0;
			cpa_par_err <= 0;
			cpa_par_enb <= 0;
			cpa_pdl_ov <= 0;
			cpa_mem_prot_flag <= 0;
			cpa_non_ex_mem <= 0;
			cpa_clk_en <= 0;
			cpa_clk_flag <= 0;
			cpa_fov_en <= 0;
			cpa_ar_ov_en <= 0;
			cpa_pia <= 0;
		end
		if(cpa_pdl_ov_set)
			cpa_pdl_ov <= 1;
		if(cpa_cono_set) begin
			if(iob[18]) cpa_pdl_ov <= 0;
			if(iob[21]) cpa_adr_break <= 0;
			if(iob[22]) cpa_mem_prot_flag <= 0;
			if(iob[23]) cpa_non_ex_mem <= 0;
			if(iob[24] &  cpa_clk_en) cpa_clk_en <= 0;
			if(iob[25] & ~cpa_clk_en) cpa_clk_en <= 1;
			if(iob[26]) cpa_clk_flag <= 0;
			if(iob[27] &  cpa_fov_en) cpa_fov_en <= 0;
			if(iob[28] & ~cpa_fov_en) cpa_fov_en <= 1;
			// AR FOV cleared in ARF
			if(iob[30] &  cpa_ar_ov_en) cpa_ar_ov_en <= 0;
			if(iob[31] & ~cpa_ar_ov_en) cpa_ar_ov_en <= 1;
			// AR OV cleared in ARF
			cpa_pia <= iob[33:35];
		end
		if(pi_cono_set) begin
			if(iob[18]) cpa_pwr_fail <= 0;
			if(iob[19]) cpa_par_err <= 0;
			if(iob[20] &  cpa_par_enb) cpa_par_enb <= 0;
			if(iob[21] & ~cpa_par_enb) cpa_par_enb <= 1;
		end
	end


	/* AR */
	reg [0:35] ar;
	wire ar_clr =	// this signal isn't explicitly named
		// TODO
		et0 & (iot_datai | iot_coni | iot_consx) |
		mc_rd_rq_pulse |
		mc_rdwr_rq_pulse |
		kt1 | at1 |
		ft2 | ft4;
	wire arlt_clr =
		ar_clr |
		et0 & hwt_arlt_clr_et0 |
		et1 & ir_idiv |
		at3;
	wire arrt_clr =
		ar_clr |
		et1 & ir_idiv |
		et0 & hwt_arrt_clr_et0;
	wire ar_fm_ds1 =
		kt2 & key_dep_OR_dep_nxt_OR_exe |
		iot_t3 & bio_cpa_sel & iob_datai;
	wire ar_fm_pcJ =
		et0 & ar_fm_pcJ_et0 |
		et1 & ir_jsa |
		knt1 |
		knt3;
	wire arrt_fm_pcJ = ar_fm_pcJ;
	wire arlt_fm_ir1 = et0 & ir_uuo;
	wire arlt_fm_flagsJ = et0 & ar_fm_flags_et0;
	wire ar_fm_fm1 =
		// TODO
		at2 & mc_fm_en |
		ft3 & mc_fm_en |
		ft5 |
		fmat1 & mc_rd;
	wire ar_fm_iob1 = iot_t3;
	wire ar_swap = ft6 | ft8;
	wire arlt_fm_arrtJ =
		ar_swap |
		et0 & arlt_fm_arrt_et0 |
		et1 & arlt_fm_arrt_et1 |
		et2 & ar_swap_et2;
	wire arrt_fm_arltJ =
		ar_swap |
		et0 & arrt_fm_arlt_et0 |
		et1 & arrt_fm_arlt_et1 |
		et2 & ar_swap_et2;
	wire ar_fm_adJ =
		st2 & sar_ne_br;
	wire arlt_fm_adJ =
		ar_fm_adJ |
		et0 & arlt_fm_adJ_et0 |
		et1 & arlt_fm_adJ_et1;
	wire arrt_fm_adJ =
		ar_fm_adJ |
		et0 & arrt_fm_adJ_et0 |
		et1 & arrt_fm_adJ_et1 |
		at3 & af2;
	wire ar_fm_ad0 =
		et0 & ar_fm_ad0_et0 |
		et1 & ar_fm_ad0_et1 |
		et2 & ar_fm_adJ_et2;
	wire ar_fm_ad1 =
		et0 & ar_fm_ad1_et0 |
		et1 & ar_fm_ad1_et1 |
		et2 & ar_fm_adJ_et2;
	wire arlt_fm_ad0 = arlt_fm_adJ | ar_fm_ad0;
	wire arlt_fm_ad1 = arlt_fm_adJ | ar_fm_ad1;
	wire arrt_fm_ad0 = arrt_fm_adJ | ar_fm_ad0;
	wire arrt_fm_ad1 = arrt_fm_adJ | ar_fm_ad1;
	wire ar_fm_mqJ = ft4a | st7;	// TODO
	wire ar_fm_mq0 =
		ar_fm_mqJ |
		et0 & ir_pops |
		et1 & ar_fm_mqJ_et1 |
		et2 & ar_fm_mqJ_et2;
	wire ar_fm_mq1 =
		ar_fm_mqJ |
		et0 & ir_pops |
		et1 & ar_fm_mqJ_et1 |
		et2 & ar_fm_mqJ_et2;
	wire arlt_fm_mq0 = ar_fm_mq0;
	wire arlt_fm_mq1 = ar_fm_mq1;
	wire arrt_fm_mq0 = ar_fm_mq0;
	wire arrt_fm_mq1 = ar_fm_mq1;

	wire ar_fm_adJ_et0 =
		ir_as | ir_exch | ir_3xx | ir_aobjp | ir_aobjn | ir_push |
		iot_blk | ir_jra | ir_movnx |
		ar[0] & (ir_movmx | ir_idiv | ir_fdv_NOT_l) |
		ir_dfn | ir_boole_0 | ir_boole_6 |
		ir_boole_11 | ir_boole_12 | ir_boole_14;
	wire ar_fm_ad0_et0 =
		ar_fm_adJ_et0 |
		ir_boole_1 | ir_boole_4 | ir_boole_13 | ir_boole_16;
	wire ar_fm_ad1_et0 =
		ar_fm_adJ_et0 |
		ir_boole_2 | ir_boole_7 | ir_boole_10 | ir_boole_15 | ir_boole_17;
	wire arlt_fm_arrt_et0 =
		ir_movsx | ir_test_swap |
		hwt_lt_fm_rt_et0 | iot_cono |
		ir_blt | jffo_swap;
	wire arrt_fm_arlt_et0 =
		ir_movsx | ir_test_swap |
		hwt_rt_fm_lt_et0 |
		ir_blt | jffo_swap;
	wire arlt_fm_adJ_et0 = hwt_arlt_fm_adJ_et0 | ir_fsb;
	wire arrt_fm_adJ_et0 = hwt_arrt_fm_adJ_et0 | ir_fsb;
	wire ar_fm_pcJ_et0 = ir_pushj | ir_jsa | ir_jsp | ir_jsr | ir_jrst;
	wire ar_fm_flags_et0 = ir_jsr | ir_jsp | ir_pushj;

	wire arlt_fm_arrt_et1 = hwt_lt_fm_rt_et1 | ir_jsa;
	wire arrt_fm_arlt_et1 = hwt_rt_fm_lt_et1;
	wire arlt_fm_adJ_et1 = hwt_e_long & ir[3];
	wire arrt_fm_adJ_et1 = hwt_e_long & ~ir[3];
	wire ar_fm_ad0_et1 = ir_pop | ir_txzx | ir_txcx;
	wire ar_fm_ad1_et1 = ir_pop | ir_txcx | ir_txox;
	wire ar_fm_mqJ_et1 = ir_popj | ir_jra | ir_pushj | jffo_f1;

	wire ar_fm_adJ_et2 = ir_boole | ir_dfn;
	wire ar_swap_et2 = ir_test_swap | ir_jsa;
	wire ar_fm_mqJ_et2 = ir_pop | ir_blt;

	always @(posedge clk) begin: arctl
		integer i;
		if(ar_fm_fm1)
			ar <= ar | fm;
		if(arlt_fm_ir1)
			ar[0:12] <= ar[0:12] | ir[0:12];
		if(ar_fm_iob1)
			ar <= ar | iob;
		if(ar_fm_ds1)
			ar <= ar | ds;
		if(arlt_clr)
			ar[0:17] <= 0;
		if(arrt_clr)
			ar[18:35] <= 0;
		if({36{mc_rd}} & membus_pulse)
			ar <= ar | membus_pulse;
		if(arlt_fm_arrtJ)
			ar[0:17] <= ar[18:35];
		if(arrt_fm_arltJ)
			ar[18:35] <= ar[0:17];
		if(arlt_fm_flagsJ) begin
			ar[0:6] = { ar_ov_flag, ar_cry0_flag, ar_cry1_flag, ar_fov,
				byf6, ex_user, ex_iot_user };
			ar[11:12] = { ar_fxu, ar_dck };
		end
		if(arrt_fm_pcJ)
			ar[18:35] <= pc;
		for(i = 0; i < 18; i = i+1) begin
			if(arlt_fm_ad0 & ~ad[i])
				ar[i] <= 0;
			if(arlt_fm_ad1 & ad[i])
				ar[i] <= 1;
			if(arrt_fm_ad0 & ~ad[i+18])
				ar[i+18] <= 0;
			if(arrt_fm_ad1 & ad[i+18])
				ar[i+18] <= 1;
			if(arlt_fm_mq0 & ~mq[i])
				ar[i] <= 0;
			if(arlt_fm_mq1 & mq[i])
				ar[i] <= 1;
			if(arrt_fm_mq0 & ~mq[i+18])
				ar[i+18] <= 0;
			if(arrt_fm_mq1 & mq[i+18])
				ar[i+18] <= 1;
		end
	end

	/* ARF */
	reg ar_ov_flag;
	reg ar_cry0_flag;
	reg ar_cry1_flag;
	reg ar_fov;
	reg ar_fxu;
	reg ar_dck;
	wire ar_ov_cond = ad_cry[0] ^ ad_cry[1];
	wire ar0_XOR_ar1 = ar[0] ^ ar[1];
	wire arf_flags_fm_brJ = et0 & ir_jrst & ir[11];
	wire ar_jfcl_clr = et0 & ir_jfcl;
	wire arf_cry_stb =
		et0 & (ir_as | ir_3xx & ir[3] | ar_fm_adJ_et0 & ir_21x);
	wire ar_ov_set = 0;

	always @(posedge clk) begin
		if(mr_start) begin
			ar_ov_flag = 0;
			ar_cry0_flag = 0;
			ar_cry1_flag = 0;
			ar_fov = 0;
			ar_fxu = 0;
			ar_dck = 0;
		end
		if(arf_cry_stb & ar_ov_cond | ar_ov_set)
			ar_ov_flag <= 1;
		if(arf_cry_stb & ad_cry[0])
			ar_cry0_flag <= 1;
		if(arf_cry_stb & ad_cry[1])
			ar_cry1_flag <= 1;
		if(ar_jfcl_clr & ir[9])
			ar_ov_flag <= 0;
		if(ar_jfcl_clr & ir[10])
			ar_cry0_flag <= 0;
		if(ar_jfcl_clr & ir[11])
			ar_cry1_flag <= 0;
		if(ar_jfcl_clr & ir[12])
			ar_fov <= 0;
		if(arf_flags_fm_brJ) begin
			ar_ov_flag <= br[0];
			ar_cry0_flag <= br[1];
			ar_cry1_flag <= br[2];
			ar_fov <= br[3];
			ar_fxu <= br[11];
			ar_dck <= br[12];
		end
		if(cpa_cono_set) begin
			if(iob[29]) ar_fov <= 0;
			if(iob[32]) ar_ov_flag <= 0;
		end
	end


	/* BR */
	reg [0:35] br;
	wire br_fm_ar0 =
		br_fm_arJ |
		et1 & ir_test |
		iot_t4 & iot_consx;
	wire br_fm_ar1 = br_fm_arJ;
	wire br_fm_arJ =
		et0 & br_fm_arJ_et0 |
		et1 & br_fm_arJ_et1 |
		et2 & ir_dfn |
		at1 | at3 |
		ft1a & ~ir_jrst;

	wire br_fm_arJ_et0 = ir_jsa | ir_exch | ir_fsb |
		hwt_e_long | ir_dfn | ir_fsc;
	wire br_fm_arJ_et1 = ir_pushj | ir_pop;

	always @(posedge clk) begin: brctl
		integer i;
		for(i = 0; i < 36; i = i+1) begin
			if(br_fm_ar0 & ~ar[i])
				br[i] <= 0;
			if(br_fm_ar1 & ar[i])
				br[i] <= 1;
		end
	end


	/* MQ */
	reg [0:35] mq;
	wire mq_clr = mr_clr | ft6;
	wire mq_fm_adJ =
		et0 & mq_fm_adJ_et0 |
		et1 & (ir_idiv | jffo_f1) |
		et2 & ir_blt |
		ft4 | ft7 | ft4a;

	wire mq_fm_adJ_et0 = ir_pops | ir_pushj;

	always @(posedge clk) begin
		if(mq_clr)
			mq <= 0;
		if(mq_fm_adJ)
			mq <= ad;
	end


	/* AD */
	reg ad_ar_p_en;
	reg ad_ar_m_en;
	reg ad_br_p_en;
	reg ad_br_m_en;
	reg ad_cry_ins;
	reg ad_p1_lh;
	reg ad_m1_lh;
	reg ad_cry_36;

	wire ad_cry_allow =
		ad_ar_p_en & ad_br_p_en |
		ad_ar_p_en & ad_br_m_en |
		ad_ar_m_en & ad_br_p_en |
		ad_ar_m_en & ad_br_m_en |
		ad_cry_36;
	wire ad_cond = ad[0] ^ (ad_cry[0] ^ ad_cry[1]);

	wire ad_ar_p_en_clr =
		ft9 & ~ad_ar_p_en_ft9 |
		et0 & ad_br_p_only_en_et0 |
		et1 & ir_test |
		et2 & ~st_inh |
		st0;
	wire ad_ar_p_en_set =
		mr_clr |
		et0 & ir_idiv;
	wire ad_ar_m_en_clr =
		et0 & ad_br_p_only_en_et0 |
		et0 & ir_idiv |
		et2 & ~st_inh |
		st0;
	wire ad_ar_m_en_set =
		ft9 & ad_ar_m_en_ft9 |
		et1 & ir_boole;

	wire ad_br_p_en_clr =
		at3 |
		et1 & ir_boole;
	wire ad_br_p_en_set =
		mr_clr | at4 |
		ft9 & ad_br_p_en_ft9 |
		et0 & ad_br_p_only_en_et0 |
		et1 & ir_test |
		et2 & ~st_inh |
		st0 |
		iot_t3;
	wire ad_br_m_en_clr = mr_clr |
		et0 & ad_br_p_only_en_et0 |
		et1 & (ir_boole | ir_test) |
		et2 & ~st_inh |
		st0;
	wire ad_br_m_en_set = ft9 & ad_br_m_en_ft9;

	wire ad_clr = mr_clr;	// TODO
	wire ad_cry_ins_clr = et1 | st0;
	wire ad_cry_ins_set = ft9 & ad_cry_ins_ft9;
	wire ad_cry36_clr =
		et0 & (ir_idiv | ad_br_p_only_en_et0) |
		et2 & ~st_inh |
		st0;
	wire ad_cry36_set =
		ft9 & ad_cry36_ft9 |
		et1 & jffo_f1;

	wire [0:35] ad_cry_kill = {
		5'b0, ~ad_cry_allow,
		8'b0, ~ad_cry_allow,
		8'b0, ~ad_cry_allow,
		8'b0, ~ad_cry_allow,
		3'b0 };
	wire [0:35] ad_ar_inp = {36{ad_ar_p_en}} & ar | {36{ad_ar_m_en}} & ~ar;
	wire [0:35] ad_br_inp =
		({36{ad_br_p_en}} & br | {36{ad_br_m_en}} & ~br) &
		 ~{ 17'b0, ad_m1_lh, 18'b0 } |
		{ 17'b0, ad_p1_lh, 18'b0 };

	wire [0:35] ad;
	wire [0:36] ad_cry;
	assign ad_cry[36] = ad_cry_36;
	genvar i;
	generate
		for(i = 0; i < 36; i = i + 1) begin
			adr ad_adr(ad_ar_inp[i], ad_br_inp[i],
				ad_cry[i+1], ad_cry_ins, ad_cry_kill[i],
				ad[i], ad_cry[i]);
		end
	endgenerate

	wire ad_eq_0 = ad == 0;

	/* All crazy levels for FT9 */
	wire ad_inc_both_ft9 = ir_aobjp | ir_aobjn |
		ir_push | ir_pushj |
		iot_blk | ir_blt;
	wire ad_ar_negate_ft9 = ir_21x | ir_idiv | ir_fdv_NOT_l;
	wire ad_minus_br_ft9 = ir_sub | ir_fsb | ir_cax | ir_dfn;
	wire ad_br_pm_ft9 = ir_soxx | ir_pops | hwt_br_pm_en_ft9;
	wire ad_ar_p_en_ft9 = ad_inc_both_ft9 |
		ir_as | ir_3xx | ir_pops | ir_txcx |
		byte_ptr_inc | ir_jffo;
	wire ad_ar_m_en_ft9 = ad_ar_negate_ft9 |
		ir_boole_6 | ir_boole_11 | ir_boole_12 | ir_boole_17 |
		ir_div_OR_fdvl;
	wire ad_br_p_en_ft9 = ad_br_pm_ft9 |
		ir_add | ir_exch | ir_jsa | ir_jra | ir_txox | ir_hwt |
		ir_xmul | ir_boole_1 | ir_boole_6 | ir_boole_7 | ir_boole_10 | ir_boole_16;
	wire ad_br_m_en_ft9 = ad_br_pm_ft9 | ad_minus_br_ft9 |
		ir_txcx | ir_txzx | ir_boole_2 | ir_boole_4 |
		ir_boole_11 | ir_boole_13 | ir_boole_14 | ir_boole_15;
	wire ad_cry_ins_ft9 = ir_boole_6 | ir_boole_11 | ir_txcx;
	wire ad_cry36_ft9 = ad_inc_both_ft9 | ad_minus_br_ft9 |
		ad_ar_negate_ft9 | ir_aoxx | byte_ptr_inc;

	/* ET0 */
	wire ad_br_p_only_en_et0 = hwt_e_long | ir_pops |
		~e_long_OR_st_inh;


	always @(posedge clk) begin
		if(ad_clr) begin
			ad_cry_ins <= 0;
			ad_p1_lh <= 0;
			ad_m1_lh <= 0;
			ad_cry_36 <= 0;
		end
		if(ad_cry_ins_clr)
			ad_cry_ins <= 0;
		if(ad_cry_ins_set)
			ad_cry_ins <= 1;
		if(ad_cry36_clr)
			ad_cry_36 <= 0;
		if(ad_cry36_set)
			ad_cry_36 <= 1;
		if(et0 & ~ir_blt | et2)
			ad_p1_lh <= 0;
		if(ft9 & ad_inc_both_ft9)
			ad_p1_lh <= 1;
		if(et0)
			ad_m1_lh <= 0;
		if(ft9 & ir_pops)
			ad_m1_lh <= 1;
		if(ad_ar_p_en_clr) ad_ar_p_en <= 0;
		if(ad_ar_m_en_clr | ad_clr) ad_ar_m_en <= 0;
		if(ad_ar_p_en_set) ad_ar_p_en <= 1;
		if(ad_ar_m_en_set) ad_ar_m_en <= 1;
		if(ad_br_p_en_clr) ad_br_p_en <= 0;
		if(ad_br_m_en_clr) ad_br_m_en <= 0;
		if(ad_br_p_en_set) ad_br_p_en <= 1;
		if(ad_br_m_en_set) ad_br_m_en <= 1;
	end


	/* PC */
	reg [18:35] pc;
	wire pc_inc_inh =
		ir_xct | ir_uuo | iot_blk |
		ir_blt | pi_cyc | key_pi_inh |
		ir_134_7 & byf5;
	wire pc_cond_p =
		ir[6:8] == 4 |			// A
		~ir[6] & ir[7] & ad_eq_0 |	// E, LE; == 0
		ir[6] & ~ir[8] & ~ad_eq_0;	// A, N; != 0
	wire pc_cond_r =
		~ir[6] & ir[8] & ad[0] |	// L, LE; < 0
		ir[6] & ~ir[7] & ~ad[0] |	// A, GE; >= 0
		ir[6] & ~ad_eq_0 & ~ad[0];	// A, GE, N, G; > 0
	wire pc_cond_q =
		~ir[6] & ir[8] & ad_cond |	// L, LE; signed <
		ir[6] & ~ir[7] & ~ad_cond |	// A, GE; signed >=
		ir[6] & ~ad_eq_0 & ~ad_cond;	// A, GE, N, G; signed >

	wire pc_fm_ma =
		et0 & (pc_set_et0 | ir_jumps & (pc_cond_r | pc_cond_p)) |
		et2 & (ir_popj | ir_jra) |
		knt1 |
		knt3 |
		kt3 & key_start;
	wire pc_inc =
		// TODO
		et0 & ir_skips & (pc_cond_p | pc_cond_r) |
		et0 & ir_cax & (pc_cond_p | pc_cond_q) |
		et2 & pc_inc_et2 |
		ft9 & ~pc_inc_inh |
		knt2 |
		iot_t5 & (iot_conso & ~ad_eq_0 |
		          iot_consz & ad_eq_0);

	wire pc_set_et0 =
		ir_aobjp & ~ad[0] |
		ir_aobjn & ad[0] |
		ir_jffo & ~ad_eq_0 |
		ar_fm_pcJ_et0 |
		ir_jfcl &
			(ir[9] & ar_ov_flag |
			 ir[10] & ar_cry0_flag |
			 ir[11] & ar_cry1_flag |
			 ir[12] & ar_fov);
	wire pc_inc_et2 =
		ir_test & (ir[6:7] == 1 & ad_eq_0 |
		           ir[6:7] == 2 |
		           ir[6:7] == 3 & ~ad_eq_0) |
		ir_jsr | ir_jsa;

	always @(posedge clk) begin
		if(pc_fm_ma)
			pc <= ma;
		if(pc_inc)
			pc <= pc + 1;
	end


	/* IR */
	reg [0:17] ir;
	reg ir_lt_en;
	reg ir_rt_en;
	wire ir_rdi_setup = kt3 & key_rdi;
	wire ir_lt_clr = mr_clr;
	wire ir_rt_clr = mr_clr | at4 | at6 & ir_134_7;

	wire ir_uuo = ir[0:1] == 0 &
			(ir_fp_trap_sw |
			 ir[2] == 0 |
			 ir[3] == 0 & (ir[4] == 0 | ir[5] == 0)) |
		ir_jrsta & ~ex_allow_iots & (ir[9] | ir[10]) |
		ir_iota & ~ex_allow_iots & ~ex_pi_sync;

	wire ir_0xx = ir[0:2] == 0;
	wire ir_1xx = ir[0:2] == 1;
	wire ir_2xx = ir[0:2] == 2;
	wire ir_3xx = ir[0:2] == 3;
	wire ir_boole = ir[0:2] == 4;
	wire ir_hwt = ir[0:2] == 5;
	wire ir_test = ir[0:2] == 6;
	wire ir_iota = ir[0:2] == 7;
	wire ir_iot = ir_iota & ~ir_uuo;

	wire ir_20x = ir_2xx & ir[3:5] == 0;
	wire ir_21x = ir_2xx & ir[3:5] == 1;
	wire ir_xmul = ir_2xx & ir[3:5] == 2;
	wire ir_xdiv = ir_2xx & ir[3:5] == 3;
	wire ir_24x = ir_2xx & ir[3:5] == 4;
	wire ir_25x = ir_2xx & ir[3:5] == 5;
	wire ir_26x = ir_2xx & ir[3:5] == 6;
	wire ir_as = ir_2xx & ir[3:5] == 7;

	wire ir_13x = ir[0:5] == 6'o13 & ~ir_uuo;
	wire ir_134_7 = ir_13x & ir[6];
	wire ir_ufa = ir_13x & ir[6:8] == 0;
	wire ir_dfn = ir_13x & ir[6:8] == 1;
	wire ir_fsc = ir_13x & ir[6:8] == 2;
	wire ir_ibp = ir_13x & ir[6:8] == 3;
	wire ir_ildb = ir_13x & ir[6:8] == 4;
	wire ir_ldb = ir_13x & ir[6:8] == 5;
	wire ir_idpb = ir_13x & ir[6:8] == 6;
	wire ir_dpb = ir_13x & ir[6:8] == 7;

	wire ir_fp = ir_1xx & ir[3] & ~ir_uuo;
	wire ir_fad = ir_fp & ir[4:5] == 0;
	wire ir_fsb = ir_fp & ir[4:5] == 1;
	wire ir_fmp = ir_fp & ir[4:5] == 2;
	wire ir_fdvx = ir_fp & ir[4:5] == 3;
	wire ir_fp_dir = ir_fp & ir[7:8] == 0;
	wire ir_fp_l_i = ir_fp & ir[7:8] == 1;
	wire ir_fp_mem = ir_fp & ir[7:8] == 2;
	wire ir_fp_both = ir_fp & ir[7:8] == 3;
	wire ir_fp_long = ir_fp_l_i & ~ir[6];
	wire ir_fp_imm = ir_fp_l_i & ir[6];
	wire ir_fp_NOT_imm = ir_fp & (~ir[6] | ir[7] | ~ir[8]);
	wire ir_fdvl = ir_fdvx & ir_fp_long;
	wire ir_fdv_NOT_l = ir_fdvx & ~ir_fp_long;

	wire ir_fwt = ir_20x | ir_21x;
	wire ir_movex = ir_fwt & ir[5:6] == 0;
	wire ir_movsx = ir_fwt & ir[5:6] == 1;
	wire ir_movnx = ir_fwt & ir[5:6] == 2;
	wire ir_movmx = ir_fwt & ir[5:6] == 3;
	wire ir_fwt_dir = ir_fwt & ir[7:8] == 0;
	wire ir_fwt_imm = ir_fwt & ir[7:8] == 1;
	wire ir_fwt_mem = ir_fwt & ir[7:8] == 2;
	wire ir_fwt_self = ir_fwt & ir[7:8] == 3;

	wire ir_idiv = ir_xdiv & ~ir[6];
	wire ir_div = ir_xdiv & ir[6];
	wire ir_md = ir_2xx & ~ir[3] & ir[4];
	wire ir_md_sce = ir_md & ir[7];
	wire ir_md_fce = ir_md & (ir[7] | ~ir[8]);
	wire ir_md_sac_inh = ir_md & ir[7] & ~ir[8];
	wire ir_md_sac2 = ~ir_md_sac_inh & (ir_xdiv | ir_xmul & ir[6]);

	wire ir_ash = ir_24x & ir[6:8] == 0;
	wire ir_rot = ir_24x & ir[6:8] == 1;
	wire ir_lsh = ir_24x & ir[6:8] == 2;
	wire ir_jffo = ir_24x & ir[6:8] == 3;
	wire ir_ashc = ir_24x & ir[6:8] == 4;
	wire ir_rotc = ir_24x & ir[6:8] == 5;
	wire ir_lshc = ir_24x & ir[6:8] == 6;
	wire ir_247 = ir_24x & ir[6:8] == 7;

	wire ir_254_7 = ir_25x & ir[6];
	wire ir_exch = ir_25x & ir[6:8] == 0;
	wire ir_blt = ir_25x & ir[6:8] == 1;
	wire ir_aobjp = ir_25x & ir[6:8] == 2;
	wire ir_aobjn = ir_25x & ir[6:8] == 3;
	wire ir_jrsta = ir_25x & ir[6:8] == 4;
	wire ir_jfcl = ir_25x & ir[6:8] == 5;
	wire ir_xct = ir_25x & ir[6:8] == 6;
	wire ir_257 = ir_25x & ir[6:8] == 7;
	wire ir_jrst = ir_jrsta & ~ir_uuo;

	wire ir_26x_e_long = ir_26x & ~ir_jsp;
	wire ir_260_3 = ir_26x & ~ir[6];
	wire ir_pushj = ir_26x & ir[6:8] == 0;
	wire ir_push = ir_26x & ir[6:8] == 1;
	wire ir_pop = ir_26x & ir[6:8] == 2;
	wire ir_popj = ir_26x & ir[6:8] == 3;
	wire ir_jsr = ir_26x & ir[6:8] == 4;
	wire ir_jsp = ir_26x & ir[6:8] == 5;
	wire ir_jsa = ir_26x & ir[6:8] == 6;
	wire ir_jra = ir_26x & ir[6:8] == 7;
	wire ir_pops = ir_pop | ir_popj;

	wire ir_add = ir_as & ~ir[6];
	wire ir_sub = ir_as & ir[6];
	wire ir_as_dir = ir_as & ir[7:8] == 0;
	wire ir_as_imm = ir_as & ir[7:8] == 1;
	wire ir_as_mem = ir_as & ir[7:8] == 2;
	wire ir_as_both = ir_as & ir[7:8] == 3;

	wire ir_caix = ir_3xx & ir[3:5] == 0;
	wire ir_camx = ir_3xx & ir[3:5] == 1;
	wire ir_jumpx = ir_3xx & ir[3:5] == 2;
	wire ir_skipx = ir_3xx & ir[3:5] == 3;
	wire ir_aojx = ir_3xx & ir[3:5] == 4;
	wire ir_aosx = ir_3xx & ir[3:5] == 5;
	wire ir_sojx = ir_3xx & ir[3:5] == 6;
	wire ir_sosx = ir_3xx & ir[3:5] == 7;
	wire ir_cax = ir_caix | ir_camx;
	wire ir_jumps = ir_jumpx | ir_aojx | ir_sojx;
	wire ir_aoxx = ir_aojx | ir_aosx;
	wire ir_soxx = ir_sojx | ir_sosx;
	wire ir_xosx = ir_3xx & ir[3] & ir[5];
	wire ir_skips = ir_3xx & ir[5] & ~ir_camx;

	wire ir_boole_0 = ir_boole & ir[3:6] == 0;
	wire ir_boole_1 = ir_boole & ir[3:6] == 1;
	wire ir_boole_2 = ir_boole & ir[3:6] == 2;
	wire ir_boole_3 = ir_boole & ir[3:6] == 3;
	wire ir_boole_4 = ir_boole & ir[3:6] == 4;
	wire ir_boole_5 = ir_boole & ir[3:6] == 5;
	wire ir_boole_6 = ir_boole & ir[3:6] == 6;
	wire ir_boole_7 = ir_boole & ir[3:6] == 7;
	wire ir_boole_10 = ir_boole & ir[3:6] == 8;
	wire ir_boole_11 = ir_boole & ir[3:6] == 9;
	wire ir_boole_12 = ir_boole & ir[3:6] == 10;
	wire ir_boole_13 = ir_boole & ir[3:6] == 11;
	wire ir_boole_14 = ir_boole & ir[3:6] == 12;
	wire ir_boole_15 = ir_boole & ir[3:6] == 13;
	wire ir_boole_16 = ir_boole & ir[3:6] == 14;
	wire ir_boole_17 = ir_boole & ir[3:6] == 15;
	wire ir_boole_dir = ir_boole & ir[7:8] == 0;
	wire ir_boole_mem = ir_boole & ir[7:8] == 2;

	wire ir_txnx = ir_test & ir[3:4] == 0;
	wire ir_txzx = ir_test & ir[3:4] == 1;
	wire ir_txcx = ir_test & ir[3:4] == 2;
	wire ir_txox = ir_test & ir[3:4] == 3;
	wire ir_test_fce = ir_test & ir[5];
	wire ir_test_swap = ir_test & ir[8];

	wire ir_div_OR_fdvl = ir_div | ir_fdvl;

	always @(posedge clk) begin
		if(ir_lt_clr)
			ir[0:12] <= 0;
		if(ir_rt_clr)
			ir[13:17] <= 0;
		if(ir_lt_en & (| membus_pulse[0:12]))
			ir[0:12] <= ir[0:12] | membus_pulse[0:12];
		if(ir_rt_en & (| membus_pulse[13:17]))
			ir[13:17] <= ir[13:17] | membus_pulse[13:17];

		if(it1) begin
			ir_lt_en <= 0;
			ir_rt_en <= 0;
		end
		if(ft1a)
			ir_rt_en <= 0;
		if(at4 | at6 & ir_134_7)
			ir_rt_en <= 1;
		if(kt2 & key_execute | it0) begin
			ir_lt_en <= 1;
			ir_rt_en <= 1;
		end
		if(st1 & key_rim)
			ir[12] <= 0;
		if(et0 & iot_blk)
			ir[12] <= 1;
		if(ir_rdi_setup) begin
			ir[0:2] <= 3'o7;
			ir[3:9] <= rdi_sel;
			ir[12] <= ~key_rdi_part2;
		end
	end


	/* HWT */
	wire hwt_3_let = ir_hwt & ir[4:5] == 0;
	wire hwt_z = ir_hwt & ir[4:5] == 1;
	wire hwt_o = ir_hwt & ir[4:5] == 2;
	wire hwt_e = ir_hwt & ir[4:5] == 3;
	wire hwt_dir = ir_hwt & ir[7:8] == 0;
	wire hwt_imm = ir_hwt & ir[7:8] == 1;
	wire hwt_mem = ir_hwt & ir[7:8] == 2;
	wire hwt_self = ir_hwt & ir[7:8] == 3;
	wire hwt_e_long = hwt_3_let & ir[6] & ~ir[7];
	wire hwt_sce = hwt_mem & ir[4];

	wire hwt_e_test =
		(ir[3]^ir[6]) & ar[18] |
		~(ir[3]^ir[6]) & ar[0];

	wire hwt_br_pm_en_ft9 = ir_hwt & ir[4];

	wire hwt_lt_fm_rt_et0 = ir_hwt & ir[6] & ~hwt_e_long & ~ir[3];
	wire hwt_rt_fm_lt_et0 = ir_hwt & ir[6] & ~hwt_e_long & ir[3];
	wire hwt_lt_fm_rt_et1 = ir_hwt & ir[6] & hwt_e_long & ~ir[3];
	wire hwt_rt_fm_lt_et1 = ir_hwt & ir[6] & hwt_e_long & ir[3];

	wire hwt_arrt_clr_et0 = hwt_e & ~hwt_e_test & ~ir[3] |
		hwt_z & ~ir[3];
	wire hwt_arlt_clr_et0 = hwt_e & ~hwt_e_test & ir[3] |
		hwt_z & ir[3];
	wire hwt_arrt_fm_adJ_et0 = hwt_e & hwt_e_test & ~ir[3] |
		hwt_e_long |
		hwt_3_let & hwt_mem & ~ir[3] |
		hwt_3_let & ~ir[7] & ir[3] |
		hwt_o & ~ir[3];
	wire hwt_arlt_fm_adJ_et0 = hwt_e & hwt_e_test & ir[3] |
		hwt_e_long |
		hwt_3_let & hwt_mem & ir[3] |
		hwt_3_let & ~ir[7] & ~ir[3] |
		hwt_o & ir[3];


	/* JFFO */
wire jffo_swap = 0;
wire jffo_f1 = 0;


	/* BYTE */
	reg byf4, byf5, byf6;
	wire byte_ptr_inc = (ir_ildb | ir_idpb | ir_ibp) & ~byf5 & ~byf6;
	wire byte_ptr_not_inc = (ir_ldb | ir_dpb | byf6) & ir_134_7 & ~byf5;
	wire lb_byte_load = (ir_ildb | ir_ldb) & byf5;
	wire db_byte_dep = (ir_idpb | ir_dpb) & byf5;

	always @(posedge clk) begin
		if(mr_start | arlt_fm_flagsJ)
			byf6 <= 0;
		if(mr_clr) begin
			byf4 <= 0;
			byf5 <= 0;
		end
	end


	/* IOT */
	reg iot_f1;
	reg iot_go;
	wire iot_blki = ir_iot & ir[10:12] == 0;
	wire iot_datai = ir_iot & ir[10:12] == 1;
	wire iot_blko = ir_iot & ir[10:12] == 2;
	wire iot_datao = ir_iot & ir[10:12] == 3;
	wire iot_cono = ir_iot & ir[10:12] == 4;
	wire iot_coni = ir_iot & ir[10:12] == 5;
	wire iot_consz = ir_iot & ir[10:12] == 6;
	wire iot_conso = ir_iot & ir[10:12] == 7;
	wire iot_consx = iot_conso | iot_consz;
	wire iot_blk = iot_blki | iot_blko;
	wire iot_out_going = iot_cono | iot_datao;
	wire iot_t0;
	wire iot_t1;
	wire iot_t2;
	wire iot_t3;
	wire iot_t4;
	wire iot_t5;
	wire iot_rdi_pulse;
	wire iot_initial_setup_dly;
	wire iot_restart_dly;
	wire iot_data_dly;
	wire iot_reset_dly;
	wire iot_data_xfer = iot_restart_dly | iot_data_dly;
	// TODO: figure out what this does exactly
	wire iob_bus_reset = iot_reset_dly & ~iot_data_dly;

	wire iot_datao_clr;
	wire iot_datao_set;
	wire iot_cono_clr;
	wire iot_cono_set;
	wire iot_reset;

	dcd iot_dcd1(.clk(clk), .reset(reset),
		.p(iot_go & ~iot_reset_dly), .l(1'b1),
		.q(iot_t0));
	dcd iot_dcd2(.clk(clk), .reset(reset),
		.p(~iot_initial_setup_dly), .l(1'b1),
		.q(iot_t2));
	dcd iot_dcd3(.clk(clk), .reset(reset),
		.p(~iot_restart_dly), .l(1'b1),
		.q(iot_t3));
	dcd iot_dcd4(.clk(clk), .reset(reset),
		.p(~iot_data_dly), .l(1'b1),
		.q(iot_t4));
	dcd iot_dcd5(.clk(clk), .reset(reset),
		.p(~key_rdi_dly), .l(1'b1),
		.q(iot_rdi_pulse));
	pa iot_pa1(.clk(clk), .reset(reset),
		.in(iot_t4_D & iot_consx),
		.p(iot_t5));
	pa iot_pa2(.clk(clk), .reset(reset),
		.in(mc_rst1 & iot_f1),
		.p(iot_t1));

	pa iot_pa3(.clk(clk), .reset(reset),
		.in(iot_t2 & iot_datao),
		.p(iot_datao_clr));
	pa iot_pa4(.clk(clk), .reset(reset),
		.in(iot_t2 & iot_cono),
		.p(iot_cono_clr));
	pa iot_pa5(.clk(clk), .reset(reset),
		.in(iot_t3 & iot_datao),
		.p(iot_datao_set));
	pa iot_pa6(.clk(clk), .reset(reset),
		.in(iot_t3 & iot_cono),
		.p(iot_cono_set));
	pa iot_pa7(.clk(clk), .reset(reset),
		.in(mr_start |
		    cpa_cono_set & iob[19]),
		.p(iot_reset));

	wire iot_t4_D;
	ldly1us iot_dly1(.clk(clk), .reset(reset),
		.p(iot_t0), .l(1'b1),
		.q(iot_initial_setup_dly));
	ldly2us iot_dly2(.clk(clk), .reset(reset),
		.p(iot_t0), .l(1'b1),
		.q(iot_restart_dly));
	ldly1_5us iot_dly3(.clk(clk), .reset(reset),
		.p(iot_t2), .l(1'b1),
		.q(iot_data_dly));
	ldly2_5us iot_dly4(.clk(clk), .reset(reset),
		.p(iot_t3), .l(1'b1),
		.q(iot_reset_dly));
	dly190ns iot_dly5(.clk(clk), .reset(reset),
		.in(iot_t4),
		.p(iot_t4_D));

	always @(posedge clk) begin
		if(mr_clr | iot_t1)
			iot_f1 <= 0;
		if(et0 & iot_blk)
			iot_f1 <= 1;
		if(mr_start | iot_t2)
			iot_go <= 0;
		if(et0 & ir_iot & ~iot_blk)
			iot_go <= 1;
	end


	wire fdt9 = 0;

	/* SC */
	reg sc_stop;

	always @(posedge clk) begin
		if(mr_clr)
			sc_stop <= 0;
	end


	/* MA */
	reg [18:35] ma;
	wire ma18_31_eq_0 = ma[18:31] == 0;
	wire ma_fm_arJ =
		ft7 |
		et1 & (ir_blt | ir_jra | ir_push | ir_popj | ir_jrst) |
		et2 & br_fm_arJ_et1 |
		knt2 |
		kt1 & key_next |
		at4 |
		at6 & ~ir_uuo;
	wire ma_fm_asJ = kt2 & key_as_strobe_en;
	wire ma_fm_pcJ = it0 & ~pi_cyc & ~e_xctf;
	wire ma_fm_pich1 = it0 & pi_cyc;
	wire ma_clr = it1 | pi_t0 & pi_ov;

	always @(posedge clk) begin
		if(ma_clr)
			ma <= 0;
		if(ma_fm_arJ)
			ma <= ar[18:35];
		if(ma_fm_asJ)
			ma <= as;
		if(ma_fm_pcJ)
			ma <= pc;
		if(ma_fm_pich1) begin
			ma[30] <= 1;
			ma[32:34] <= ma[32:34] | pi_enc;
		end
		if(ma_fm_pich1 & ma_trap_offset |
		   et0 & ma_trap_offset & ex_non_rel_uuo)
			ma[29] <= 1;
		if(it0 & (pi_ov | e_uuof))
			ma[35] <= 1;
		if(et0) begin
			if(ir_uuo)
				ma[30] <= 1;
			if(ir_uuo & ir_1xx)
				ma[31] <= 1;
		end
	end


	/* MAI */
	reg mai_fma_sel;
	wire [18:35] mai;
	assign mai[32:35] = mai_fma_sel ? fma : ma[32:35];
	assign mai[26:31] = mai_fma_sel ? 0 : ma[26:31];
	assign mai[18:25] =
		{8{ex_rel & ~pr1_ill_adr}} & rla |
		{8{ex_rel & pr1_ill_adr}} & rlc |
		{8{~ex_rel & ~mai_fma_sel}} & ma[18:25];
	wire mai_cmc_adr_ack = membus_addr_ack;
	wire mai_cmc_rd_rs = membus_rd_rs;

	always @(posedge clk) begin
		if(mr_start | mc_rst0)
			mai_fma_sel <= 0;
		if(mc_fm_rd_rq | mc_fm_wr_rq)
			mai_fma_sel <= 1;
	end


	/* MC */
	reg mc_rd;
	reg mc_wr;
	reg mc_rq;
	reg mc_stop;
	reg mc_split_cyc_sync;
	reg mc_par_stop;
	reg mc_ignore_parity;
	wire mc_req_cyc = (mc_rd | mc_wr) & mc_rq &
		(~ma18_31_eq_0 | ~mc_fm_en);
	wire mc_stop_en = key_sing_cycle |
		0;	// TODO
	wire mc_split_cyc_en = key_adr_stop | key_sing_cycle |
		~mc_fm_en | iob_dr_split;
	wire mc_fm_en = fm_enable_sw;
	wire mc_fm_rd_rq;
	wire mc_fm_wr_rq;
	wire mc_rdwr_rs;
	wire mc_rd_rq_pulse;
	wire mc_wr_rq_pulse;
	wire mc_rdwr_rq_pulse;
	wire mc_rq_pulse;
	wire mc_rq_set;
	wire mc_illeg_adr;
	wire mc_adr_ack;
	wire mc_rd_rs;
	wire mc_wr_rs;
	wire mc_membus_fm_ar1;
	wire mc_bus_wr_rs;
	wire mc_rst0;
	wire mc_rst1;
	wire mc_non_ex_mem;
	wire mc_nxm_rst;
	wire mc_nxm_rd;
	wire mc_stop_set;

	pa mc_pa1(.clk(clk), .reset(reset),
		.in(mc_fm_rd_rq |
		    kt3 & key_ex_OR_ex_nxt |
		    it0 |
		    at4 |
		    ft0 |
		    ft1 & (mc_split_cyc_sync | ma18_31_eq_0) |
		    ft7),
		.p(mc_rd_rq_pulse));
	pa mc_pa2(.clk(clk), .reset(reset),
		.in(mc_fm_wr_rq |
		    mc_rdwr_rs & mc_split_cyc_sync |
		    kt3 & key_dep_OR_dep_nxt |
		    et2 & ir_blt |
		    st6),
		.p(mc_wr_rq_pulse));
	pa mc_pa3(.clk(clk), .reset(reset),
		.in(ft1 & ~mc_split_cyc_sync & ~ma18_31_eq_0),
		.p(mc_rdwr_rq_pulse));
	pa mc_pa4(.clk(clk), .reset(reset),
		// TODO
		.in(et0 & iot_blk |
		    st5),
		.p(mc_rdwr_rs));
	pa mc_pa5(.clk(clk), .reset(reset),
		.in((at1 | ft2 | ft4 | fdt9) & ~mc_fm_en),
		.p(mc_fm_rd_rq));
	pa mc_pa6(.clk(clk), .reset(reset),
		.in(st1 & ~sac_inh_OR_fm_en |
		    st8 & ~mc_fm_en),
		.p(mc_fm_wr_rq));
	pa mc_pa7(.clk(clk), .reset(reset),
		.in(mc_rd_rq_pulse | mc_wr_rq_pulse | mc_rdwr_rq_pulse),
		.p(mc_rq_pulse));
	pa mc_pa8(.clk(clk), .reset(reset),
		.in(mc_rq_pulse_D2 & ex_user & pra_ill_adr),
		.p(mc_illeg_adr));
	pa mc_pa9(.clk(clk), .reset(reset),
		.in(mc_rq_pulse_D2 & ex_user & ~pra_ill_adr & ~ma18_31_eq_0 |
		    mc_rq_pulse_D1 & (~ex_user | ma18_31_eq_0)),
		.p(mc_rq_set));
	pa mc_pa10(.clk(clk), .reset(reset),
		.in(fmat2 | mai_cmc_adr_ack | mc_nxm_rst),
		.p(mc_adr_ack));
	pa mc_pa11(.clk(clk), .reset(reset),
		.in(mai_cmc_rd_rs),
		.p(mc_rd_rs));
	pa mc_pa12(.clk(clk), .reset(reset),
		// TODO
		.in(kt3 & key_execute |
		    mc_rdwr_rs_D & ~mc_split_cyc_sync |
		    mc_adr_ack & (fma_ma_en | mc_wr & ~mc_rd)),
		.p(mc_wr_rs));
	pa mc_pa13(.clk(clk), .reset(reset),
		.in(mc_wr_rs),
		.p(mc_membus_fm_ar1));
	pa mc_pa14(.clk(clk), .reset(reset),
		.in(mc_wr_rs_D),
		.p(mc_bus_wr_rs));
	pa mc_pa15(.clk(clk), .reset(reset),
		.in(mc_rd_rs_D & (~pn_par_even | mc_ignore_parity) & ~mc_stop & mc_par_stop |
		    mai_cmc_rd_rs & ~mc_stop & ~mc_par_stop |
		    mc_wr_rs & ~mc_stop |
		    mc_nxm_rd & ~mc_stop |
		    kt0a & mc_stop & key_cont
		),
		.p(mc_rst0));
	pa mc_pa16(.clk(clk), .reset(reset),
		.in(mc_rst0_D),
		.p(mc_rst1));
	pa_dcd mc_pa17(.clk(clk), .reset(reset),
		.p(~mc_rq_pulse_D3), .l(mc_rq & ~mc_stop),
		.q(mc_non_ex_mem));
	pa mc_pa18(.clk(clk), .reset(reset),
		.in(mc_non_ex_mem & ~key_nxm_stop),
		.p(mc_nxm_rst));
	pa mc_pa19(.clk(clk), .reset(reset),
		.in(mc_nxm_rst & mc_rd),
		.p(mc_nxm_rd));

	wire mc_rq_pulse_D1, mc_rq_pulse_D2, mc_rq_pulse_D3;
	wire mc_wr_rs_D, mc_rd_rs_D, mc_rdwr_rs_D;
	wire mc_rst0_D;
	dly45ns mc_dly1(.clk(clk), .reset(reset),
		.in(mc_rq_pulse),
		.p(mc_rq_pulse_D1));
	dly140ns mc_dly2(.clk(clk), .reset(reset),
		.in(mc_rq_pulse),
		.p(mc_rq_pulse_D2));
	dly215ns mc_dly3(.clk(clk), .reset(reset),
		.in(mc_rq_pulse),
		.p(mc_stop_set));
	dly190ns mc_dly4(.clk(clk), .reset(reset),
		.in(mc_wr_rs),
		.p(mc_wr_rs_D));
	dly140ns mc_dly5(.clk(clk), .reset(reset),
		.in(mc_rd_rs),
		.p(mc_rd_rs_D));
	dly65ns mc_dly6(.clk(clk), .reset(reset),
		.in(mc_rdwr_rs),
		.p(mc_rdwr_rs_D));
	dly65ns mc_dly7(.clk(clk), .reset(reset),
		.in(mc_rst0),
		.p(mc_rst0_D));
	ldly100us mc_dly8(.clk(clk), .reset(reset),
		.p(mc_rq_pulse), .l(1'b1),
		.q(mc_rq_pulse_D3));

	always @(posedge clk) begin
		if(mr_start) begin
			mc_rd <= 0;
			mc_wr <= 0;
			mc_rq <= 0;
			mc_stop <= 0;
			mc_ignore_parity <= 0;
		end
		if(mr_clr) begin
			mc_split_cyc_sync <= 0;
			mc_par_stop <= 0;
		end
		if(mc_stop_set) begin
			if(key_par_stop)
				mc_par_stop <= 1;
			if(mc_stop_en |
			   mc_non_ex_mem & key_nxm_stop)
				mc_stop <= 1;
		end
		if(mc_wr_rq_pulse | mc_rst1)
			mc_rd <= 0;
		if(mc_rd_rq_pulse | mc_rdwr_rq_pulse)
			mc_rd <= 1;
		if(mc_rd_rq_pulse)
			mc_wr <= 0;
		if(mc_wr_rq_pulse | mc_rdwr_rq_pulse)
			mc_wr <= 1;
		if(mc_rq_pulse) begin
			mc_stop <= 0;
			mc_par_stop <= 0;
			mc_ignore_parity <= 0;
		end
		if(mc_rq_set)
			mc_rq <= 1;
		if(mc_adr_ack)
			mc_rq <= 0;
		if(kt0a & ~key_cont | mc_rst1)
			mc_stop <= 0;
		if(it1 & mc_split_cyc_en |
		   ft1 & ma18_31_eq_0)
			mc_split_cyc_sync <= 1;
	end

	/* FM */
	reg [0:35] fmem[0:16];
	reg fma_xr;
	reg fma_ac;
	reg fma_ac2;
	wire fma_ma_en = mc_rq & ma18_31_eq_0 & mc_fm_en;
	wire fma_xr_en = fma_xr & ~fma_ma_en;
	wire fma_ac_en = fma_ac & ~fma_ma_en;
	wire fma_ac2_en = fma_ac2 & ~fma_ma_en;
	wire [32:35] fma =
		{4{fma_ma_en}} & ma[32:35] |
		{4{fma_xr_en}} & ir[14:17] |
		{4{fma_ac_en}} & ir[9:12] |
		{4{fma_ac2_en}} & (ir[9:12]+1);
	wire [0:35] fm = fmem[fma];
	wire fmat1;
	wire fmat2;
	wire fma_fm_arJ =
		fmat1 & mc_wr |
		st1 & mc_fm_en & ~sac_inh |
		st8 & mc_fm_en;

	pa fma_pa1(.clk(clk), .reset(reset),
		.in(mc_rq_set_D & fma_ma_en),
		.p(fmat1));
	pa fma_pa2(.clk(clk), .reset(reset),
		.in(fmat1_D),
		.p(fmat2));

	wire mc_rq_set_D, fmat1_D;
	dly115ns fma_dly1(.clk(clk), .reset(reset), .in(mc_rq_set), .p(mc_rq_set_D));
	dly65ns fma_dly2(.clk(clk), .reset(reset), .in(fmat1), .p(fmat1_D));

	always @(posedge clk) begin
		if(mr_clr | at4) begin
			fma_xr <= 1;
			fma_ac <= 0;
			fma_ac2 <= 0;
		end
		if(at3) begin
			fma_xr <= 0;
			fma_ac <= 1;
		end
		if(ft3 & fac2) begin
			fma_ac <= 0;
			fma_ac2 <= 1;
		end
		if(ft4a) begin
			fma_ac <= 1;
			fma_ac2 <= 0;
		end
		if(fma_fm_arJ)
			fmem[fma] <= ar;
		if(et0 & (ir_ufa | ir_jffo) |
		   st2) begin
			fma_ac <= 0;
			fma_ac2 <= 1;
		end
	end


endmodule
