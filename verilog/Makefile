DEP=diag.inc test.inc test_arith.inc test_fp.inc test_dpy.inc
V=asm.v pdp10.v ka10.v testcore161c.v modules.v dly.v

pdp10: $(V) $(DEP)
	iverilog -o $@ $(V)
