DEP=test.inc test_arith.inc test_fp.inc
V=asm.v pdp10.v ka10.v core161c.v modules.v dly.v

pdp10: $(V) $(DEP)
	iverilog -o $@ $(V)

run: pdp10
	vvp pdp10
