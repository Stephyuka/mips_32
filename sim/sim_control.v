`timescale 1ns / 1ps
module sim();
reg [31:0] instr;
reg zero;
reg neg;
wire [14:0] signal;


controlunit ctrl(instr[31:26], instr[5:0], zero, neg, signal[14], signal[13],
                 signal[12], signal[11], signal[10], signal[9:6], signal[5],
                 signal[4], signal[3], signal[2], signal[1], signal[0]);

initial
begin
	instr = 32'h00221820;
	zero = 0;
	neg = 0;
	#30
	instr = 32'h1a040010;
	#30
	neg = 1;
	#30
	zero = 1;
	#30
	neg = 0;
	#30
	instr = 32'h2088a004;
	#30
	instr = 32'h0c001401;
	#30
	zero = 1;
	#30
	neg = 1;
	#30
	$stop;
end

endmodule
