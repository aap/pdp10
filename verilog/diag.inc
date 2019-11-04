initial begin: meminit
	integer i;

	for(i = 0; i < 'o40000; i = i + 1)
		pdp10.mem0.core[i] = 0;
	for(i = 0; i < 'o20; i = i + 1) begin
		pdp10.mem0.core[i] = 0;
		pdp10.ka10.fmem[i] = 0;
	end

	pdp10.ka10.fmem[0] = 36'o777777_777777;
	pdp10.ka10.fmem[1] = 36'o777777_000000;
	pdp10.ka10.fmem[2] = 36'o456000_000654;
	pdp10.ka10.fmem[3] = 36'o056000_000654;
	pdp10.ka10.fmem[4] = 36'o000003_000111;
	pdp10.ka10.fmem[5] = 36'o777776_000111;
	pdp10.ka10.fmem['o7] = 36'o777777_777777;
	pdp10.ka10.fmem['o10] = 36'o000000_000000;
	pdp10.ka10.fmem['o11] = 36'o000000_000001;
	pdp10.ka10.fmem['o12] = 36'o000000_000002;
	pdp10.ka10.fmem['o13] = 36'o400000_000000;
	pdp10.ka10.fmem['o14] = 36'o010700_000300;
	pdp10.ka10.fmem['o15] = 36'o300600_000300;
	pdp10.ka10.fmem['o16] = 36'o000001_000400;
	pdp10.ka10.fmem['o17] = 36'o000000_000300;
	for(i = 0; i < 'o20; i = i + 1) begin
		pdp10.mem0.core[i] = pdp10.ka10.fmem[i];
	end

	pdp10.mem0.core['o141] = 36'o000000000001;
	pdp10.mem0.core['o142] = 36'o000000000002;
	pdp10.mem0.core['o200] = 36'o777740000100;
	pdp10.mem0.core['o201] = 36'o777776_000277;
	pdp10.mem0.core['o300] = 36'o123456111222;
	pdp10.mem0.core['o002000] = 36'o006000001001;


	pdp10.mem0.core['o20] = Inst(`IDIV, 'o13, 0, 0, 'o12);



	pdp10.mem0.core['o21] = Inst(`JRST, 4, 0, 0, 'o21);
	pdp10.mem0.core['o22] = Inst(`JRST, 4, 0, 0, 'o22);
	pdp10.mem0.core['o200] = Inst(`JRST, 4, 0, 0, 'o200);
end
