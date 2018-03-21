#!/usr/bin/python
from math import *

# This assumes a 10ns clock, delays are rounded down

nsdly="""module dly%dns(input clk, input reset, input in, output p);
	reg [%d:0] r;
	always @(posedge clk or posedge reset) begin
		if(reset)
			r <= 0;
		else begin
			if(r)
				r <= r + %d'b1;
			if(in)
				r <= -%d;
		end
	end
	assign p = r == -%d'b1;
endmodule
"""

def gendlyns(ns):
	n = ns//10
	nb = ceil(log(n+1,2))
	print(nsdly % (ns, nb-1, nb, n, nb))

gendlyns(30)
gendlyns(45)
gendlyns(65)
gendlyns(75)
gendlyns(90)
gendlyns(100)	# system module
gendlyns(115)
gendlyns(140)
gendlyns(150)
gendlyns(165)
gendlyns(190)
gendlyns(200)	# system module
gendlyns(215)
gendlyns(240)
gendlyns(250)	# system module
gendlyns(265)
gendlyns(280)
gendlyns(335)
gendlyns(400)	# system module
gendlyns(800)	# system module


usldly="""
module ldly%sus(input clk, input reset, input p, input l, output q, output ql);
	reg [%d:0] r;
	wire t;
	dcd dcd(.clk(clk), .reset(reset), .p(p), .l(l), .q(t));
	always @(posedge clk or posedge reset) begin
		if(reset)
			r <= 0;
		else begin
			if(ql)
				r <= r + 1;
			if(t)
				r <= -%d;
		end
	end
	assign ql = r != 0 | t;
	assign q = (r != -%d'b1) & (r != 0) | t;
endmodule
"""

def genldlyus(us):
	s = str(us).replace('.', '_')
	n = us*100 - 2
	nb = ceil(log(n+1,2))
	print(usldly % (s, nb-1, n, nb))

genldlyus(0.2)	# only for testing
genldlyus(1)
genldlyus(1.5)
genldlyus(2)
genldlyus(2.5)
genldlyus(100)
