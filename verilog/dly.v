module dly30ns(input clk, input reset, input in, output p);
	reg [1:0] r;
	always @(posedge clk or posedge reset) begin
		if(reset)
			r <= 0;
		else begin
			if(r)
				r <= r + 2'b1;
			if(in)
				r <= -3;
		end
	end
	assign p = r == -2'b1;
endmodule

module dly45ns(input clk, input reset, input in, output p);
	reg [2:0] r;
	always @(posedge clk or posedge reset) begin
		if(reset)
			r <= 0;
		else begin
			if(r)
				r <= r + 3'b1;
			if(in)
				r <= -4;
		end
	end
	assign p = r == -3'b1;
endmodule

module dly65ns(input clk, input reset, input in, output p);
	reg [2:0] r;
	always @(posedge clk or posedge reset) begin
		if(reset)
			r <= 0;
		else begin
			if(r)
				r <= r + 3'b1;
			if(in)
				r <= -6;
		end
	end
	assign p = r == -3'b1;
endmodule

module dly75ns(input clk, input reset, input in, output p);
	reg [2:0] r;
	always @(posedge clk or posedge reset) begin
		if(reset)
			r <= 0;
		else begin
			if(r)
				r <= r + 3'b1;
			if(in)
				r <= -7;
		end
	end
	assign p = r == -3'b1;
endmodule

module dly90ns(input clk, input reset, input in, output p);
	reg [3:0] r;
	always @(posedge clk or posedge reset) begin
		if(reset)
			r <= 0;
		else begin
			if(r)
				r <= r + 4'b1;
			if(in)
				r <= -9;
		end
	end
	assign p = r == -4'b1;
endmodule

module dly100ns(input clk, input reset, input in, output p);
	reg [3:0] r;
	always @(posedge clk or posedge reset) begin
		if(reset)
			r <= 0;
		else begin
			if(r)
				r <= r + 4'b1;
			if(in)
				r <= -10;
		end
	end
	assign p = r == -4'b1;
endmodule

module dly115ns(input clk, input reset, input in, output p);
	reg [3:0] r;
	always @(posedge clk or posedge reset) begin
		if(reset)
			r <= 0;
		else begin
			if(r)
				r <= r + 4'b1;
			if(in)
				r <= -11;
		end
	end
	assign p = r == -4'b1;
endmodule

module dly140ns(input clk, input reset, input in, output p);
	reg [3:0] r;
	always @(posedge clk or posedge reset) begin
		if(reset)
			r <= 0;
		else begin
			if(r)
				r <= r + 4'b1;
			if(in)
				r <= -14;
		end
	end
	assign p = r == -4'b1;
endmodule

module dly150ns(input clk, input reset, input in, output p);
	reg [3:0] r;
	always @(posedge clk or posedge reset) begin
		if(reset)
			r <= 0;
		else begin
			if(r)
				r <= r + 4'b1;
			if(in)
				r <= -15;
		end
	end
	assign p = r == -4'b1;
endmodule

module dly165ns(input clk, input reset, input in, output p);
	reg [4:0] r;
	always @(posedge clk or posedge reset) begin
		if(reset)
			r <= 0;
		else begin
			if(r)
				r <= r + 5'b1;
			if(in)
				r <= -16;
		end
	end
	assign p = r == -5'b1;
endmodule

module dly190ns(input clk, input reset, input in, output p);
	reg [4:0] r;
	always @(posedge clk or posedge reset) begin
		if(reset)
			r <= 0;
		else begin
			if(r)
				r <= r + 5'b1;
			if(in)
				r <= -19;
		end
	end
	assign p = r == -5'b1;
endmodule

module dly200ns(input clk, input reset, input in, output p);
	reg [4:0] r;
	always @(posedge clk or posedge reset) begin
		if(reset)
			r <= 0;
		else begin
			if(r)
				r <= r + 5'b1;
			if(in)
				r <= -20;
		end
	end
	assign p = r == -5'b1;
endmodule

module dly215ns(input clk, input reset, input in, output p);
	reg [4:0] r;
	always @(posedge clk or posedge reset) begin
		if(reset)
			r <= 0;
		else begin
			if(r)
				r <= r + 5'b1;
			if(in)
				r <= -21;
		end
	end
	assign p = r == -5'b1;
endmodule

module dly240ns(input clk, input reset, input in, output p);
	reg [4:0] r;
	always @(posedge clk or posedge reset) begin
		if(reset)
			r <= 0;
		else begin
			if(r)
				r <= r + 5'b1;
			if(in)
				r <= -24;
		end
	end
	assign p = r == -5'b1;
endmodule

module dly250ns(input clk, input reset, input in, output p);
	reg [4:0] r;
	always @(posedge clk or posedge reset) begin
		if(reset)
			r <= 0;
		else begin
			if(r)
				r <= r + 5'b1;
			if(in)
				r <= -25;
		end
	end
	assign p = r == -5'b1;
endmodule

module dly265ns(input clk, input reset, input in, output p);
	reg [4:0] r;
	always @(posedge clk or posedge reset) begin
		if(reset)
			r <= 0;
		else begin
			if(r)
				r <= r + 5'b1;
			if(in)
				r <= -26;
		end
	end
	assign p = r == -5'b1;
endmodule

module dly280ns(input clk, input reset, input in, output p);
	reg [4:0] r;
	always @(posedge clk or posedge reset) begin
		if(reset)
			r <= 0;
		else begin
			if(r)
				r <= r + 5'b1;
			if(in)
				r <= -28;
		end
	end
	assign p = r == -5'b1;
endmodule

module dly335ns(input clk, input reset, input in, output p);
	reg [5:0] r;
	always @(posedge clk or posedge reset) begin
		if(reset)
			r <= 0;
		else begin
			if(r)
				r <= r + 6'b1;
			if(in)
				r <= -33;
		end
	end
	assign p = r == -6'b1;
endmodule

module dly400ns(input clk, input reset, input in, output p);
	reg [5:0] r;
	always @(posedge clk or posedge reset) begin
		if(reset)
			r <= 0;
		else begin
			if(r)
				r <= r + 6'b1;
			if(in)
				r <= -40;
		end
	end
	assign p = r == -6'b1;
endmodule

module dly800ns(input clk, input reset, input in, output p);
	reg [6:0] r;
	always @(posedge clk or posedge reset) begin
		if(reset)
			r <= 0;
		else begin
			if(r)
				r <= r + 7'b1;
			if(in)
				r <= -80;
		end
	end
	assign p = r == -7'b1;
endmodule


module ldly0_2us(input clk, input reset, input p, input l, output q, output ql);
	reg [4:0] r;
	wire t;
	dcd dcd(.clk(clk), .reset(reset), .p(p), .l(l), .q(t));
	always @(posedge clk or posedge reset) begin
		if(reset)
			r <= 0;
		else begin
			if(ql)
				r <= r + 1;
			if(t)
				r <= -18;
		end
	end
	assign ql = r != 0 | t;
	assign q = (r != -5'b1) & (r != 0) | t;
endmodule


module ldly1us(input clk, input reset, input p, input l, output q, output ql);
	reg [6:0] r;
	wire t;
	dcd dcd(.clk(clk), .reset(reset), .p(p), .l(l), .q(t));
	always @(posedge clk or posedge reset) begin
		if(reset)
			r <= 0;
		else begin
			if(ql)
				r <= r + 1;
			if(t)
				r <= -98;
		end
	end
	assign ql = r != 0 | t;
	assign q = (r != -7'b1) & (r != 0) | t;
endmodule


module ldly1_5us(input clk, input reset, input p, input l, output q, output ql);
	reg [7:0] r;
	wire t;
	dcd dcd(.clk(clk), .reset(reset), .p(p), .l(l), .q(t));
	always @(posedge clk or posedge reset) begin
		if(reset)
			r <= 0;
		else begin
			if(ql)
				r <= r + 1;
			if(t)
				r <= -148;
		end
	end
	assign ql = r != 0 | t;
	assign q = (r != -8'b1) & (r != 0) | t;
endmodule


module ldly2us(input clk, input reset, input p, input l, output q, output ql);
	reg [7:0] r;
	wire t;
	dcd dcd(.clk(clk), .reset(reset), .p(p), .l(l), .q(t));
	always @(posedge clk or posedge reset) begin
		if(reset)
			r <= 0;
		else begin
			if(ql)
				r <= r + 1;
			if(t)
				r <= -198;
		end
	end
	assign ql = r != 0 | t;
	assign q = (r != -8'b1) & (r != 0) | t;
endmodule


module ldly100us(input clk, input reset, input p, input l, output q, output ql);
	reg [13:0] r;
	wire t;
	dcd dcd(.clk(clk), .reset(reset), .p(p), .l(l), .q(t));
	always @(posedge clk or posedge reset) begin
		if(reset)
			r <= 0;
		else begin
			if(ql)
				r <= r + 1;
			if(t)
				r <= -9998;
		end
	end
	assign ql = r != 0 | t;
	assign q = (r != -14'b1) & (r != 0) | t;
endmodule

