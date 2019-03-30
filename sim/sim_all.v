`timescale 1ns / 1ps
module sim_all();
reg clk;
reg [11:0] S;
reg rst;

wire [7:0] AN;
wire [6:0] CA;
wire [15:0] l;

cputop cpu(clk, S, rst, AN, CA, l);

initial
begin
    clk <= 0;
	forever # 1 clk = ~clk;
end

initial
  begin
  	S[0] = 1;
  	rst = 0;
  	S[7:1] = 7'b0001000;
  	//S[7:1] = 7'b0011111;
  	S[8] = 0;
  	S[11:9] = 3'b100;
  	//S[11:9] = 3'b110;
  	//S[7:1] = 7'b0000010;
  	#600
  	S[0] = 0;
  	#600 
  	S[0] = 1;
  	rst = 1;
  	#600
  	rst = 0;
  	
  /*	S[7:1] = 7'b0011111;
  	S[8] = 1;
  	#2000
  	S[11:9] = 3'b110;
  	#1000
  	S[11:9] = 3'b001;
  	#600
  	S[11:9] = 3'b000;
  	#800
  	S[11:9] = 3'b010;
  	#500*/
  	$stop;
  end


endmodule

