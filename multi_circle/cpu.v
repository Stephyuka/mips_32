module mem(
	input [5:0] a,
	input [5:0] dpra,
	input [127:0] wd,
	input clk, WE,
	output [127:0] readdata,
	output [127:0] showdata);

data_mem data_mem(.a(a),.d(wd),.dpra(dpra),.clk(clk),.we(WE),.spo(readdata),.dpo(showdata));
endmodule

/**********************************************************/
 module ctrigger (
 	input clk,
 	input clk_en,
 	input reset,
 	output clkn,
 	output [31:0] count);
reg nclk;
reg [31:0] clkc;
reg [31:0] count_c;
initial 
begin 
  clkc <= 1; 
  nclk <= 0;
  count_c <= 0;
end

always @(posedge clk or posedge reset)
begin
    if(reset) 
    begin clkc = 1; count_c = 0; end
    else if(clk_en)
    begin
    nclk <= nclk + 1;
    clkc <= clkc + 1;
    if(nclk == 1) count_c <= count_c + 1;
    end
end

assign  count = count_c ;
assign  clkn = nclk;

endmodule

/**********************************************************/
 

module mips_top(
	input clk, reset,
	input clk_en,
	input [7:0] mems,
	input [4:0] regs,
	input [1:0] ctag,
	input [1:0] cselect,
	output [31:0] instr, clkinfo, memdata, regdata, pcinfo, cachedata, stateinfo, cause,
	output cache_dirty,
	output [15:0] sign_one,
	output [15:0] sign_two);

wire [31:0] readdata;
wire [31:0] writedata, writedest;
wire [127:0] wbdata;
wire [5:0] wbaddress, memaddress;
wire [127:0] memdata_s, update_data;
wire memwrite;
wire update, writeback;
wire clkn;
wire miss;
wire dirty;

ctrigger clock(clk, clk_en, reset, clkn, clkinfo);
mips mips(clkn, reset, miss, dirty, readdata, regs, pcinfo, stateinfo, memwrite, update,
          writeback, writedata, writedest, regdata, sign_one, sign_two, cause, instr);
mux2_6 memadd_mux(writedest[7:2], wbaddress, writeback, memaddress);
mem mem(memaddress, mems[7:2], wbdata, clkn, writeback, update_data, memdata_s);
//update is the signal to write mem: when cache miss and dirty
cache cache(clkn,reset,update, writedest, writedata, update_data, memwrite, ctag, cselect, cachedata, cache_dirty, readdata, miss, dirty, wbdata, wbaddress);

mux4_32 mem_show_mux(memdata_s[31:0], memdata_s[63:32], memdata_s[95:64], memdata_s[127:96], mems[1:0], memdata);
endmodule
/**********************************************************/

module mux2_6(
	input [5:0] d1,
	input [5:0] d2,
	input s,
	output [5:0] r
	 );

assign  r = s == 0 ? d1 : d2;
endmodule

/**********************************************************/

module mips(
	input clk, reset,
	input miss, dirty, 
	input [31:0] readdata,
	input [4:0] reg_s,
	output [31:0] pc, stateinfo,
	output memwrite, update, writeback,
	output [31:0] writedata, writedest,
	output [31:0] reg_show,
	output [15:0] sign_one,
	output [15:0] sign_two,
	output [31:0] cause, instr
	);

wire zero, overflow, negative;
wire PCEn, IRWrite,Extop, RegWrite, IorD, EPCwrite, IntCause, Causewrite;
wire [2:0] PCSrc;
wire [1:0] ALUSrcA, Regdst, MemtoReg, ALUSrcB;
wire [3:0] ALUcontrol;
wire [31:0] C0;


control_fsm fsm(clk, reset, instr[31:26], instr[5:0], zero, negative, overflow,
	            miss, dirty, memwrite, IRWrite, RegWrite, IorD, writeback, Extop, PCEn,
	            update, EPCwrite, Causewrite, IntCause, ALUSrcB, ALUSrcA, Regdst,
	            MemtoReg, PCSrc, ALUcontrol, stateinfo);

datapath dp(clk, reset, readdata, PCEn, IorD, IRWrite, Extop, RegWrite,
	        C0, Regdst, MemtoReg, ALUSrcA, ALUSrcB, ALUcontrol, PCSrc, reg_s,
	        zero, negative, overflow, writedata, writedest, instr, pc, reg_show);

CP0 cp0(clk, reset, pc, EPCwrite, IntCause, Causewrite, instr[15:11], C0, cause);

assign sign_one = {zero, negative, overflow, miss, dirty, memwrite, IRWrite, RegWrite, IorD, writeback, PCEn, update, EPCwrite, Causewrite, IntCause, Extop};
assign sign_two = {ALUSrcB, ALUSrcA, RegWrite, MemtoReg, PCSrc, ALUcontrol, 1'b0};

endmodule

/******************************************************************/
module CP0(
	input clk,
	input reset,
	input [31:0] pc,
	input EPCwrite, IntCause, Causewrite,
	input [4:0] add,
	output [31:0] C0,
	output [31:0] cause);

wire[31:0] cp0_13, cp0_14;
reg [31:0] cp0 [0:31];
wire [31:0] cause_i;

reg32_en EPC_reg(pc, clk, reset, EPCwrite, cp0_13);
mux2_32 cause_mux(32'h30, 32'h28, IntCause, cause_i);
reg32_en cause_reg(cause_i,clk, reset, Causewrite, cp0_14);
integer i;
initial begin
	for(i = 0; i < 32; i = i + 1)
	  cp0[i] = 0;	
	end
  
always @(posedge clk or posedge reset) 
begin
	if (reset) 
	begin
	for(i = 0; i < 32; i = i + 1)
	  cp0[i] <= 0;	
	end
	else
	begin
	 cp0[13] <= cp0_13;
	 cp0[14] <= cp0_14;
	end
end

assign C0 = cp0[add];
assign cause = cp0[14];


endmodule


/******************************************************************/
module datapath(
    input clk, reset,
    input [31:0] Memrd,
    input PCEn, IorD,
    input IRWrite, Extop, REgWrite,
    input [31:0] C0,
    input [1:0] Regdst, MemtoReg, ALUSrcA,ALUSrcB,
    input [3:0] ALUcontrol,
    input [2:0] PCSrc,
    input [4:0] reg_s,
    output zero, negative, overflow,
    output [31:0] Memwb,
    output [31:0] Memadr,
    output [31:0] instr,
    output [31:0] PCinfo, reg_show
	);

wire [31:0] pc_next, longd, shamt_data;
wire [31:0] alu_out, alu_r, data, wdata3;
wire [31:0] data1, data2, dataa, datab; 
wire [31:0] SrcA, SrcB, pc_j;
wire [4:0] add3;
wire [31:0] PC_s;

flopr PC(clk, reset, PCEn, PC_s, pc_next); //pc -> pc 
mux2_32 iord_mux(pc_next >> 2, alu_out, IorD, Memadr);
reg32_en instr_reg(Memrd, clk, reset, IRWrite, instr);
reg32 data_reg(Memrd, clk, reset, data);
 
mux3_5 regdst_mux(instr[20:16], instr[15:11], 5'b11111, Regdst, add3);
mux4_32 regwb_mux(alu_out, data, C0, pc_next, MemtoReg, wdata3);
regfile register(clk, REgWrite, reset, instr[25:21], instr[20:16], add3, wdata3, reg_s, data1, data2, reg_show); //6
reg32 dataa_reg(data1, clk, reset, dataa);
reg32 datab_reg(data2, clk, reset, datab);

extender shanmtex(instr[10:6], shamt_data);
signext extend(instr[15:0], Extop, longd);//8

mux3_32 srcA_mux(pc_next, shamt_data, dataa, ALUSrcA, SrcA);
mux4_32 srcB_mux(datab, 4, longd, longd << 2, ALUSrcB, SrcB);
ALU alu(SrcA, SrcB, ALUcontrol, alu_r, zero, negative, overflow);

reg32 alur_reg(alu_r, clk, reset, alu_out);
jumpadd jump(instr[25:0], pc_next[31:28], pc_j);
mux5_32 wdata_mux(alu_r, alu_out, pc_j, 32'h80000180, dataa, PCSrc, PC_s);

assign  PCinfo = pc_next;
assign Memwb = SrcB;

endmodule

