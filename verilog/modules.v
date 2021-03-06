// input 50mhz, output ~60hz
module clk60hz(
	input wire clk,
	output wire outclk
);
	reg [19:0] cnt = 0;
	assign outclk = cnt == 833333;
	always @(posedge clk)
		if(outclk)
			cnt <= 0;
		else
			cnt <= cnt + 20'b1;
endmodule

// input 50mhz, output 63.3hz
module clk63_3hz(
	input wire clk,
	output wire outclk
);
	reg [19:0] cnt = 0;
	assign outclk = cnt == 789900;
	always @(posedge clk)
		if(outclk)
			cnt <= 0;
		else
			cnt <= cnt + 20'b1;
endmodule

// input 50mhz, output 50khz
module clk50khz(
	input wire clk,
	output wire outclk
);
	reg [9:0] cnt = 0;
	assign outclk = cnt == 1000;
	always @(posedge clk)
		if(outclk)
			cnt <= 0;
		else
			cnt <= cnt + 10'b1;
endmodule

/* A B138 full adder with carry insert and carry kill */
module adr(input a, input b, input cin, input cins, input ckill, output s, output cout);
	wire c = cin | cins;
	assign s = a ^ b ^ c;
	assign cout = (a & b | (a^b)&c) & ~ckill;
endmodule


/* Note: pa and pg are exactly the same! */

/* Pulse Generator,
 * to synchronize "external" pulses. */
module pg(input clk, input reset, input in, output p);
	reg [1:0] x;
	always @(posedge clk or posedge reset)
		if(reset)
			x <= 0;
		else
			x <= { x[0], in };
	assign p = x[0] & !x[1];
endmodule

/* Pulse Amplifier
 * Essentially an edge detector */
module pa(input wire clk, input wire reset, input wire in, output wire p);
	reg [1:0] x;
	reg [1:0] init = 0;
	always @(posedge clk or posedge reset)
		if(reset)
			init <= 0;
		else begin
			x <= { x[0], in };
			init <= { init[0], 1'b1 };
		end
	assign p = (&init) & x[0] & !x[1];
endmodule

/* Diode Capacitor Diode gate.
 * This shouldn't delay the output ideally, but it does */
module dcd(input clk, input reset, input p, input l, output q);
	reg [1:0] x;
	reg [1:0] init = 0;
	always @(posedge clk or posedge reset)
		if(reset)
			init <= 0;
		else begin
			x <= { x[0], p };
			init <= { init[0], 1'b1 };
		end
	assign q = l & (&init) & x[0] & !x[1];
endmodule

/* Pulse Amplifier behind a DCD
 * Really a DCD only because we don't actually have pulses. */
module pa_dcd(input clk, input reset, input p, input l, output q);
	dcd dcd(clk, reset, p, l, q);
endmodule

module pa_dcd2(input clk, input reset,
		input p1, input l1,
		input p2, input l2,
		output q);
	wire q1, q2;
	dcd dcd1(clk, reset, p1, l1, q1);
	dcd dcd2(clk, reset, p2, l2, q2);
	assign q = q1 | q2;
endmodule

module pa_dcd4(input clk, input reset,
		input p1, input l1,
		input p2, input l2,
		input p3, input l3,
		input p4, input l4,
		output q);
	wire q1, q2, q3, q4;
	dcd dcd1(clk, reset, p1, l1, q1);
	dcd dcd2(clk, reset, p2, l2, q2);
	dcd dcd3(clk, reset, p3, l3, q3);
	dcd dcd4(clk, reset, p4, l4, q4);
	assign q = q1 | q2 | q3 | q4;
endmodule

// TODO: check the purpose of this

/* "bus driver", 40ns delayed pulse */
module bd(input clk, input reset, input in, output p);
	reg [2:0] r;
	always @(posedge clk or posedge reset) begin
		if(reset)
			r <= 0;
		else begin
			if(r)
				r <= r + 3'b1;
			if(in)
				r <= 1;
		end
	end
	assign p = r == 2;
endmodule
