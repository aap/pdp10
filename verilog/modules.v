/* A B138 full adder with carry insert and carry kill */
module adr(input a, input b, input cin, input cins, input ckill, output s, output cout);
	wire c = cin | cins;
	assign s = a ^ b ^ c;
	assign cout = (a & b | (a^b)&c) & ~ckill;
endmodule


module dly1us(input clk, input reset, input in, output p);
	reg [6:0] r;
	always @(posedge clk or posedge reset) begin
		if(reset)
			r <= 0;
		else begin
			if(r)
				r <= r + 7'b1;
			if(in)
				r <= 1;
		end
	end
	assign p = r == 102;
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

module pg36(input clk, input reset, input [0:35] in, output [0:35] p);
	reg [0:35] a, b;
	always @(posedge clk or posedge reset)
		if(reset) begin
			a <= 0;
			b <= 0;
		end else begin
			a <= in;
			b <= a;
		end
	assign p = a & ~b;
endmodule


/* Pulse Amplifier
 * Essentially an edge detector */
module pa(input clk, input reset, input in, output p);
	reg [1:0] x;
	always @(posedge clk or posedge reset)
		if(reset)
			x <= 0;
		else
			x <= { x[0], in };
	assign p = x[0] & !x[1];
endmodule

/* Diode Capacitor Diode gate.
 * This shouldn't delay the output ideally, but it does */
module dcd(input clk, input reset, input p, input l, output q);
	reg [1:0] x;
	always @(posedge clk or posedge reset)
		if(reset)
			// make sure we first have to go down once before detect rising edges
			x <= 2'b11;
		else
			x <= { x[0], p };
	assign q = l & x[0] & !x[1];
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
