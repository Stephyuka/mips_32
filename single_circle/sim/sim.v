`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/03/16 14:59:45
// Design Name: 
// Module Name: sim
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module sim();
reg clock;
reg rst;
reg en;
reg [4:0] add1, add2, add3;
reg [31:0] inputdata;
wire [31:0] read1, read2;
parameter clk_c = 20;

regfile rega(.clk(xlock),.wen(en),.rst(rst),.ra1(add1),.ra2(add2),.wadd(add3),.wdata(inputdata),.rd1(read1),.rd2(read2));
//denote the regfile module 

//set the clock
initial 
begin
clock = 0;
forever #   clock = ~clock;	
end

//provide signal
initial
begin
	rst = 1'b0;
	en = 1'b1;
	add2 = 5'b10;
	add1 = 5'b0;
	add3 = 5'b1;
	inputdata = 32'b100;
	//test if rst functions
	#50
	rst = 1'b1;
	add1 = 5'b1;
	//to input and test whether the data can be refreshed on time
	#50
	rst = 1'b0;
	#50
    add3 = 5'b0;
    inputdata = 32'b1;
    add1 = 5'b1;
    add2 = 5'b0;
    //if register $0 will be changed
    #50
    add3 = 5'b11111;
    inputdata = 32'b111;
    add1 = 5'b11111;
    add2 = 5'b1;
    #50
    en = 1'b0;
    add3 = 5'b1;
    inputdata = 32'b11;
    add1 = 5'b1;
    add2 = 5'b0;
    //if en works
    #50
    add3 = 5'b1;
    inputdata = 32'b0;
    add1 = 5'b1;
    add2 = 5'b10;
    #50
    $stop;
end
    
initial
   begin
   $timeformat(-9, 1, "ns", 12);
   $display("Time clock reset write_en registerA registerB writer_register write_data readA readB");
   $monitor("%t %b %b %b %d %d %d %d %d %d",$realtime, clock, rst, en, add1, add2, add3, inputdata, read1, read2);
   end
   	
endmodule
