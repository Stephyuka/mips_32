`timescale 1ns / 1ps
module sim_c();

reg clock;
reg en;
reg rst;
wire clk;
wire[31:0] c;

ctrigger clck(clock, en, rst, clk, c);

initial 
begin
 clock <= 0;
 forever #10 clock = ~clock;
 end


initial 
begin
	en = 0;
	rst = 0;
	#60 
	en = 1;
	#50
	rst = 1;
	#30
	rst = 0;
	#50
	en = 0;
	#60
	en = 1;
    #30
    $stop;
end

endmodule
