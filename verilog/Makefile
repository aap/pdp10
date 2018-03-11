V=pdp10.v ka10.v core161c.v modules.v dly.v

pdp10: $(V)
	iverilog -o $@ $(V)

run: pdp10
	vvp pdp10
