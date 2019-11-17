
/**********************************************************/
 module ctrigger (
 	input clk,
 	input clk_en,
 	input reset,
 	output clkn,
 	output [31:0] count);
reg nclk;
reg [31:0] clkc;
initial 
begin 
  clkc <= 1; 
  nclk <= 0;
end

always @(posedge clk or posedge reset)
begin
    if(reset) 
    clkc = 1;
    else if(clk_en)
    begin
    nclk = nclk + 1;
    clkc = clkc + 1;
    end
end

assign  count = clkc ;
assign  clkn = nclk;

endmodule


/**********************************************************/


module top(
	input clk, reset,
	input clk_en,
	input [6:0] mems,
	input [4:0] reg_s,
	output [31:0] instr, clkinfo, memdata, regdata, pc,
	output [15:0] sign);

wire [31:0] readdata;
wire [31:0] writedata, writedst;
wire memwrite;
wire clkn;
ctrigger clock(clk, clk_en, reset, clkn, clkinfo);
mips mips(clkn, reset, instr, readdata, reg_s, pc, memwrite, writedata, writedst, regdata, sign);
instrmem mem(pc[7:2],instr);//4
datamem data_m(writedata, writedst, clkn, memwrite, mems, memdata, readdata);//13

endmodule

module mips(
  input clk, reset,
  input [31:0] instr,
  input [31:0] readdata,
  input [4:0] reg_s,
  output [31:0] pc,
  output memwrite,
  output [31:0] writedata, writedst,
  output [31:0] reg_show,
  output [15:0] sign 
  );
wire memtoreg, branch, jump, jreg, zero, neg, regdst, asrca, asrcb;
wire rwrite, jal, extop;
wire [3:0] alucont;

controlunit ctrl(instr[31:26], instr[5:0], zero, neg, memtoreg, memwrite, branch, jump, jreg, alucont, regdst, asrcb, asrca, rwrite, jal, extop); 
//5

datapath dp(clk, reset, instr, readdata, memtoreg, branch,
            jump, jreg, jal, alucont, regdst, asrcb, asrca,rwrite,
            extop, reg_s, pc, zero, neg, writedata, writedst, reg_show);

assign sign = {zero, neg, memwrite, branch, jump, jreg, jal, regdst, asrca, asrcb, extop, rwrite, alucont} ;
// 
endmodule

