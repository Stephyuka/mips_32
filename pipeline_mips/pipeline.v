module Fetch(
	input clk, rst, stallFc, stallF, ifbranchD, branchnD,
	input pcrefresh,
	input ifjrD,
	input [1:0] select, //show
	input [31:0] pcD, dataaD, pcBranchD,
	output [31:0] show,
	output [31:0] pcF, instrF, SignImmF, pcBranchF,
	output [3:0] alucontrolF,
	output [1:0] memtoregF, regdstF,
	output alusrcaF, alusrcbF, ifjrF,
	output branchF, ifbranchF, regwriteF, memwriteF,
	output stallcF,
	output [15:0] sign);

wire [31:0] pcJump, pc, pc_next, pcra, pcrb;
wire [31:0] pcBranch, pc_Branch, pcnBranch;
wire extop;
wire [63:0] readinstr, ndata;
wire [5:0] nadd;
wire nen;
wire [1:0] pcsrc;

mux3_32 pc_selecta(pcF, pcBranch, pcJump, pcsrc, pcra);
mux2_32 pc_selectb(pcD, pcBranchD, branchnD, pcnBranch);
mux2_32 pc_selectc(pcra, pcnBranch, pcrefresh, pcrb);
mux2_32 pc_selectd(pcrb, dataaD, ifjrD, pc);

Fetchreg fetch(clk, rst, ~stallF, pc, pc_next);
instrmem instrmem(pc_next[8:3], readinstr);
CacheF cacheF(clk, rst, 1'b1, 1'b0, stallFc, {25'b0,pc_next[8:2]}, 32'b0, readinstr, instrF, ndata, nadd, nen, stallcF);
controlunit control(instrF[31:26], instrF[5:0], memtoregF, memwriteF, ifbranchF, ifjrF, pcsrc,
                    alucontrolF, regdstF, alusrcbF, alusrcaF, regwriteF, extop);

mux3_32 showmuxF(pcF, instrF, SignImmF, select, show);
pcplus4 pcplus4(pc_next, pcF);
branchpredict predict(clk, rst, ifbranchD, branchnD, branchF);
signext extender(instrF[15:0], extop, SignImmF);
PCBranch branch(SignImmF, pcF, pcBranchF);
mux2_32 branchmux(pcF, pcBranchF, branchF, pcBranch);
jumpadd jump(instrF[25:0], pcF[31:28], pcJump);

assign sign = {1'b0, stallF, alucontrolF, memtoregF, regdstF, alusrcaF, alusrcbF, branchF, ifbranchF, regwriteF, memwriteF};

endmodule 

/**********************************************************/

module Decode(
	input clk, rst, stallD, ForwardaD, ForwardbD,
	input [31:0] instrF, pcF, SignImmF, pcBranchF,
	input [3:0] alucontrolF,
	input [4:0] writeregW,
	input [31:0] writedataW, aluoutM,
	input [1:0] memtoregF, regdstF,
	input alusrcaF, alusrcbF, branchF, memwriteF,
	input ifbranchF, ifjrF, regwriteF, regwriteW,
	input [4:0] shows, //select show
	input [2:0] select, //show
	output pcrefresh, ifjrD, ifjr,
	output branchnew, ifbranchD, 
	output [31:0] datashow,
	output [31:0] show,
	output [31:0] dataA, dataAD, dataBD, pcD, shamtdD, SignImmD, pcBranchD,
	output [4:0] rsD, rtD, rdD,
	output [1:0] MemtoRegD, RegdstD,
	output [3:0] alucontrolD,
	output AlusrcaD, AlusrcbD, regwriteD, memwriteD,
	output [15:0] sign);

wire [31:0] dataB;
wire equal, neg;
wire branchD;
wire [31:0] instrD;

Decodereg decode(clk, ~stallD, rst, pcrefresh, instrF, pcF, SignImmF, pcBranchF ,alucontrolF,
	             memtoregF, regdstF, alusrcaF, alusrcbF, branchF, ifbranchF, ifjrF, regwriteF, 
	             memwriteF, instrD, pcD, SignImmD, pcBranchD, alucontrolD, MemtoRegD, RegdstD, 
	             AlusrcaD, AlusrcbD, branchD, ifbranchD, ifjr, regwriteD, memwriteD);

assign rsD = instrD[25:21];
assign rtD = instrD[20:16];
assign rdD = instrD[15:11];

regfile regfile(clk, regwriteW, rst, rsD, rtD, writeregW, writedataW, shows, dataAD, dataBD, datashow);
mux2_32 dataAmux(dataAD, aluoutM, ForwardaD, dataA);
mux2_32 dataBmux(dataBD, aluoutM, ForwardbD, dataB);
mux8_32 showmuxD(dataAD, dataBD, pcD, shamtdD, SignImmD, {27'b0, rsD}, {27'b0, rtD}, {27'b0, rdD}, select, show);
Fastcac cac(dataA, dataB, equal, neg);
branchjudge judgea(instrD[31:26], equal, neg, branchnew);
extender extend(instrD[10:6], shamtdD);
assign pcrefresh = ((branchD ^ branchnew) & ifbranchD & ~stallD) | ifjrD; 
assign ifjrD = ifjr & ~stallD;
assign sign = {pcrefresh, branchD, ifbranchD, stallD, ForwardaD, ForwardbD, RegdstD, alucontrolD, AlusrcaD, AlusrcbD, regwriteD, memwriteD};

endmodule


/**********************************************************/

module Execute(
	input clk, rst, stallE, FlushE, 
	input [1:0] ForwardaE, ForwardbE,
	input [31:0] resultW, aluoutM, pcD,
	input [31:0] shamtdD, dataAD, dataBD, SignImmD,
	input [4:0] rsD, rtD, rdD,
	input [3:0] alucontrolD,
	input [1:0] MemtoRegD, RegdstD,
	input AlusrcaD, AlusrcbD, regwriteD, memwriteD,
	input [2:0] select, //show
	output [4:0] rsE, rtE, writeregE,
	output [31:0] writedataE, aluoutE, pcE,
	output [31:0] show,
	output regwriteE, memwriteE,
	output [1:0] MemtoRegE,
	output [15:0] sign
	);
wire [4:0] rdE;
wire [3:0] alucontrolE;
wire [31:0] dataAE, dataBE, dataa, datab, SignImmE, shamtdataE;
wire [31:0] srcA, srcB;
wire [1:0] RegdstE;
wire AlusrcaE, AlusrcbE;
Excuetereg execute(clk, ~stallE, rst, FlushE, rsD, rtD, rdD, SignImmD, shamtdD, dataAD, dataBD, pcD,
	               regwriteD, memwriteD, AlusrcaD, AlusrcbD, MemtoRegD, alucontrolD, RegdstD, 
	               rsE, rtE, rdE, SignImmE, shamtdataE, dataAE, dataBE, pcE, regwriteE, 
	               memwriteE, AlusrcaE, AlusrcbE, MemtoRegE, alucontrolE, RegdstE);

mux3_32 Amux(dataAE, resultW, aluoutM, ForwardaE, dataa);
mux2_32 srcAmux(dataa, shamtdataE, AlusrcaE, srcA);
mux3_32 Bmux(dataBE, resultW, aluoutM, ForwardbE, datab);
mux2_32 srcBmux(datab, SignImmE, AlusrcbE, srcB);
ALU alu(srcA, srcB, alucontrolE, aluoutE);
mux3_5 regdstmux(rtE, rdE, 5'b11111, RegdstE, writeregE);
mux6_32 showmuxE(writedataE, aluoutE, pcE, {27'b0, rsE}, {27'b0, rtE}, {27'b0, writeregE}, select, show);
assign writedataE = datab;
assign sign = {7'b0, FlushE, ForwardaE, ForwardbE, regwriteE, memwriteE, MemtoRegE};
endmodule

/**********************************************************/

module Memory(
	input clk, rst, stallcF, stallM,
	input [31:0] aluoutE, writedataE, pcE,
	input [4:0] writeregE,
	input regwriteE, memwriteE,
	input [1:0] MemtoRegE,
	input [6:0] shows, //show select
	input [1:0] select, //show
	output [31:0] readdataM, aluoutM, showdata, pcM,
	output [31:0] show,
	output [4:0] writeregM,
	output regwriteM,
	output [1:0] MemtoRegM,
	output stallcM,
	output [15:0] sign);

wire [31:0] writedataM;
wire memwriteM;
wire needmemE, needmemM;
wire [63:0] updatedata;
wire [63:0] wbkdataM;
wire [5:0] wbkadd;
wire wbk;
assign needmemE = memwriteE | (MemtoRegE == 2'b01);
assign needmemM = memwriteM | (MemtoRegM == 2'b01);
//only when the instruction is lw or sw, datamem is used;
//memtoreg = 2'b01;
//

Memoryreg memory(clk, ~stallM, rst, aluoutE, writedataE, pcE, writeregE, regwriteE, MemtoRegE, memwriteE,
	             aluoutM, writedataM, pcM, writeregM, regwriteM, MemtoRegM, memwriteM);

datamemory mem(wbkadd, wbkdataM, clk, wbk, shows, showdata, updatedata);

CacheM cache(clk, rst, stallcF, needmemE,needmemM, memwriteM, aluoutM, writedataM, updatedata, readdataM, wbkdataM, wbkadd, wbk,stallcM);

mux4_32 showmuxM(readdataM, aluoutM, pcM, writedataM, select, show);

assign sign = {7'b0,memwriteM, writeregM, regwriteM, MemtoRegM};
endmodule


/**********************************************************/

module Writeback(
	input clk, rst, stallW,
	input [1:0] MemtoRegM,
	input [31:0] readdataM, aluoutM, pcM,
	input [4:0] writeregM,
	input regwriteM,
	input [1:0] select,
	output regwriteW, 
	output [4:0] writeregW,
	output [31:0] writedataW,
	output [31:0] show,
	output [15:0] sign
	);
wire [31:0] readdataW, aluoutW;
wire [31:0] pcW;
wire [1:0] MemtoRegW;
Writebackreg writeback(clk, ~stallW, rst, regwriteM, readdataM, aluoutM, pcM, writeregM,
	                   MemtoRegM, regwriteW, readdataW, aluoutW, pcW, writeregW, MemtoRegW);
mux3_32 datamux(aluoutW, readdataW, pcW, MemtoRegW, writedataW);
mux4_32 showmuxW(writedataW, readdataW, aluoutW, pcW, select, show);
assign sign = {8'b0,regwriteW, MemtoRegW, writeregW};
endmodule


module mips(
	input clk, reset,
	input clk_en,
	input [6:0] adds,
	input [2:0] regs,
	output [31:0] clkinfo, reginfo, meminfo, fetchd, decoded, executed, memoryd, writebackd,
	output [15:0] signF, signD, signE, signM, signW);

wire clkn;
wire [3:0] alucontrolF, alucontrolD, alucontrolE;
wire [1:0] memtoregF, regdstF;
wire [31:0] pcF, instrF, SignImmF, pcBranchF;
wire stallF, alusrcaF, alusrcbF, branchF, ifbranchF, ifjrF,regwriteF, memwriteF;
wire ifbranchD, branchnD, pcrefresh, stallD, ForwardaD, ForwardbD;
wire [31:0] pcD, dataaD, databD, shamtdD, SignImmD, pcBranchD, dataD;
wire [4:0] rsD, rtD, rdD, rsE, rtE, rdE;
wire [1:0] MemtoRegD, regdstD;
wire alusrcaD, alusrcbD, regwriteD, memwriteD, ifjrD;
wire ifjr;
wire flushE;
wire [1:0] forwardaE, forwardbE;
wire [4:0] writeregE;
wire [31:0] writedataE, aluoutE, pcE;
wire regwriteE, memwriteE; 
wire [1:0] MemtoRegE;
wire [31:0] aluoutM, readdataM, pcM;
wire [4:0] writeregM;
wire [1:0] MemtoRegM;
wire regwriteM;
wire [4:0] writeregW;
wire [31:0] writedataW;
wire regwriteW;
wire stallcF, stallcM, stall, stallFc;

ctrigger clock(clk, clk_en, reset, clkn, clkinfo);
Fetch fetch(clkn, reset, stallFc, stallF, ifbranchD, branchnD, pcrefresh, ifjrD, regs[1:0], pcD, dataD,pcBranchD, fetchd,
             pcF, instrF, SignImmF, pcBranchF,alucontrolF, memtoregF, regdstF, alusrcaF, alusrcbF, ifjrF,
             branchF, ifbranchF, regwriteF, memwriteF, stallcF,signF);

Decode decode(clkn, reset, stallD, ForwardaD, ForwardbD, instrF, pcF, SignImmF, pcBranchF, alucontrolF,
	          writeregW, writedataW, aluoutM, memtoregF, regdstF, alusrcaF, alusrcbF, branchF,
	          memwriteF, ifbranchF, ifjrF, regwriteF, regwriteW, adds[4:0], regs, pcrefresh, ifjrD, ifjr, branchnD, ifbranchD, reginfo,
	          decoded, dataD, dataaD, databD, pcD, shamtdD, SignImmD, pcBranchD, rsD, rtD, rdD, MemtoRegD, regdstD,
	          alucontrolD, alusrcaD, alusrcbD, regwriteD, memwriteD, signD);

Execute execute(clkn, reset, stallE, flushE, forwardaE, forwardbE, writedataW, aluoutM, pcD, shamtdD,
	            dataaD, databD, SignImmD, rsD, rtD, rdD, alucontrolD, MemtoRegD, regdstD, alusrcaD,
	            alusrcbD, regwriteD, memwriteD, regs, rsE, rtE, writeregE, writedataE, aluoutE, pcE,
	            executed, regwriteE, memwriteE, MemtoRegE, signE);

Memory memory(clkn, reset, stallcF, stallM, aluoutE, writedataE, pcE, writeregE, regwriteE, memwriteE, MemtoRegE, adds,
	          regs[1:0], readdataM, aluoutM, meminfo, pcM, memoryd, writeregM, regwriteM, MemtoRegM, stallcM,signM);

Writeback writeback(clkn, reset, stallW, MemtoRegM, readdataM, aluoutM, pcM, writeregM, regwriteM, regs[1:0],
	                regwriteW, writeregW, writedataW, writebackd, signW);

hazard hazard(rsD, rtD, rsE, rtE, writeregE, writeregM, writeregW, regwriteE, regwriteM, regwriteW, ifbranchD, ifjr,
	          MemtoRegE, MemtoRegM,stallcF,stallcM, ForwardaD, ForwardbD, forwardaE, forwardbE, stallF, stallFc, stallD, stallE, stallM, stallW, flushE);
endmodule
