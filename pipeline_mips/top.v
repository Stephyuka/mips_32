module cputop(
	input CLK100MHZ,
	input [11:0] SW,
	input BTNC,
	output [7:0] AN,
	output [6:0] CA,
	output [15:0] LED
	);

//cpushow show(.clock(CLK100MHZ), .run_en(SW[0]), .pcshow(SW[1]), .regormem(SW[2]), .showors(SW[3]), .s(SW[11:4]), .reset(BTNC),.en(AN),.c(CA),.l(LED));
cpushow show(.clock(CLK100MHZ), .s(SW), .reset(BTNC),.en(AN),.c(CA),.l(LED));

endmodule