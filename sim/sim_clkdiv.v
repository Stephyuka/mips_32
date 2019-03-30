`timescale 1ns / 1ps
module sim_clkdiv();
reg clk;
wire clk1;
wire clk2;
wire clk3;

clkdiv div(clk, clk1, clk2, clk3);

initial
begin
	clk <= 0;
	forever #5 clk <= ~clk;
end

initial
begin
	#200
	$stop;
end
endmodule
