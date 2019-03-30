

/******************************************************************/
//instruction memory
module instrmem(input [5:0] a,
            output [31:0] rd);
//reg [31:0] ROM [:0]; //32 * 64 RAM

/*
initial 
   begin
    $readmemh("memfile.dat",RAM); //the instructions in viviado

   end*/
//initial 
  //begin
  //
  //end
//assign rd = ROM[a]; //a is next_pc in flopr
instr_mem imem (
  .a(a),      // input wire [5 : 0] a
  .spo(rd)  // output wire [31 : 0] spo
);
 endmodule


/******************************************************************/
//control unit

module controlunit(
  input [5:0] Op,
  input [5:0] Fun,
  input zero,
  input neg,
  output M2REG,
  output MWRITE,
  output BRANCH,
  output JUMP,
  output JREG, 
  output reg [3:0]alucont,
  output REGDEST,
  output ALUSRCB,
  output ALUSRCA,
  output REGWRITE,
  output JALL,
    output EXTOP
  );

parameter REGOP =  6'b000000;
//reg - code
parameter ADD   =  6'b100000,
          SUB   =  6'b100010,
          ADDU  =  6'b100001,
          SUBU  =  6'b100011,
          AND   =  6'b100100,
          OR    =  6'b100101,
          XOR   =  6'b100110,
          NOR   =  6'b100111,
          SLT   =  6'b101010,
          SLTU  =  6'b101011,
          SRL   =  6'b000010,
          SRA   =  6'b000011,
          SLL   =  6'b000000,
          SLLV  =  6'b000100,
          SRLV  =  6'b000110,
          SRAV  =  6'b000111,
          JR    =  6'b001000,
          JALR  =  6'b001001,
          NOP   =  6'b000000,

/********************************************************************/
//immediate - code

          ADDI  =  6'b001000,
          ANDI  =  6'b001100,
          ORI   =  6'b001101,
          XORI  =  6'b001110,
          LW    =  6'b100011,
          LUI   =  6'b001111,
          SW    =  6'b101011,
          BEQ   =  6'b000100,
          BNE   =  6'b000101,
          BLEZ  =  6'b000110,
          BGTZ  =  6'b000111,
          SLTI  =  6'b001010,

/************************************************************************/
//jump - code
          J     =  6'b000010,
          JAL   =  6'b000011;
//ALU cont
parameter A_addu = 4'b0000,
          A_subu = 4'b0001,
          A_add  = 4'b0010,
          A_sub  = 4'b0011,
          A_or   = 4'b0100,
          A_and  = 4'b0101,
          A_xor  = 4'b0110,
          A_nor  = 4'b0111,
          A_sltu = 4'b1000,
          A_slt  = 4'b1001,
          A_sll  = 4'b1010,
          A_srl  = 4'b1011,
          A_sra  = 4'b1100,
          A_lui  = 4'b1101;

assign M2REG = (Op == LW);
//only when lw, we should write from mem to reg
assign MWRITE = Op == SW ;
//when sw, we shoulf write data into mem
assign BRANCH = ((Op == BEQ) && zero) || ((Op == BNE) && !zero) || ((Op == BLEZ) && (zero || neg)) || ((Op == BGTZ) && !neg);
//BEQ\BNE\BGTZ\BLEZ
assign ALUSRCB = (Op == SW) || (Op == LW) || (Op == ADDI) || (Op == ORI) || (Op == ANDI) || (Op == XORI) || (Op == SLTI) || (Op == LUI);

assign ALUSRCA = (Op == REGOP) && (Fun == SRL || Fun == SLL || Fun == SRA);

assign REGDEST = Op == REGOP ; //when choose instr[21:16], the flag is 1;

assign REGWRITE = ~(((Op == REGOP) && (Fun == JR)) || (Op == SW) || (Op == BNE) || (Op == BEQ) || (Op == J) || (Op == BGTZ) || (Op == BLEZ)) ;

assign JALL = (Op == JAL) || (Op == REGOP && Fun == JALR);
//if writereg, the written reg is $31
assign JUMP = (Op == J) || (Op == JAL) ;

assign JREG = (Op == REGOP) && ((Fun == JR) || (Fun == JALR));

assign EXTOP = (Op == ADDI) || (Op == LW) || (Op == SW) || (Op == BEQ) || (Op == BNE) || (Op == BLEZ) || (Op == BGTZ) || (Op == SLTI);

//the ALU 
always @(*) 
begin
    if(Op == REGOP)
    begin
      case(Fun)
      ADD : alucont <= A_add; //add
      ADDU: alucont <= A_addu;
      SUBU: alucont <= A_subu;
      SUB : alucont <= A_sub; //sub
      AND : alucont <= A_and; //and
      OR  : alucont <= A_or; //or
      XOR : alucont <= A_xor; //xor
      NOR : alucont <= A_nor; //nor
      SLT : alucont <= A_slt; //slt
      SLTU: alucont <= A_sltu;
      SLL : alucont <= A_sll; //sll
      SLLV: alucont <= A_sll; //sll
      SRLV: alucont <= A_srl;
      SRAV: alucont <= A_sra;
      SRL : alucont <= A_srl; //srl
      SRA : alucont <= A_sra; //sra
      default: alucont <= A_addu;
      endcase
    end
    else 
    begin
      case(Op)
      ADDI: alucont <= A_add; //add
      ANDI: alucont <= A_and; //and
      ORI : alucont <= A_or; //or
      XORI: alucont <= A_xor; //xor
      SLTI: alucont <= A_slt;
      LW  : alucont <= A_addu; //
      SW  : alucont <= A_addu; //
      BNE : alucont <= A_subu; //
      BEQ : alucont <= A_subu; //
      BLEZ: alucont <= A_subu; //
      BGTZ: alucont <= A_subu; //
      LUI : alucont <= A_lui;
      default: alucont <= A_addu;
      endcase
    end
end
endmodule



/******************************************************************/
module datamem(input [31:0] a,
             input [31:0] WD,
             input clk,WE,
             input [6:0] sl,
             output [31:0] data_s,
             output [31:0] RD);
//parameter start = 8'h00000000;
/*
reg [31:0] RAM[127:0];

always @(posedge clk) 
begin
  if (WE) RAM[a[6:0]] <= WD;
end

assign RD = RAM[a[6:0]];
endmodule

*/
demem memory (
  .a(a[6:0]),        // input wire [6 : 0] a
  .d(WD),        // input wire [31 : 0] d
  .dpra(sl),  // input wire [6 : 0] dpra
  .clk(clk),    // input wire clk
  .we(WE),      // input wire we
  .spo(RD),    // output wire [31 : 0] spo
  .dpo(data_s)    // output wire [31 : 0] dpo
);
// a dual-ram

endmodule



/******************************************************************/

module datapath(
    input clk,reset,
    input [31:0] instr,
    input [31:0] readmem_data,
    input m2reg, ifbranch, ifj, ifjr, ifjal,
    input [3:0] alucont,
    input regdst, asrcb, asrca, rwrite, extop,
    input [4:0] reg_s,
    output [31:0] pc_next,
    output zero, negative,
    output [31:0] alu_r,
    output [31:0] datab,
    output [31:0] r_show
	);

wire [4:0] add3, wradd;
wire [31:0] pc, pc_j, pc_f, pc_b;
wire [31:0] pc_ar, pc_br; //pc_cr?
wire [31:0] alua, alub;
wire [31:0] w_result, longd, write_data;
wire [31:0] dataa;
wire [31:0] shamt_data;

mux2_32 pc_as(pc_f, pc_b, ifbranch, pc_ar); 
mux2_32 pc_bs(pc_ar,dataa, ifjr, pc_br); // pc_b:
mux2_32 pc_cs(pc_br, pc_j, ifj, pc); //pc_c:

flopr PC(clk, reset, pc, pc_next); //pc -> pc 2


pcplus4 plus(pc_next, pc_f); //3
mux2_5 regdsta(instr[20:16], instr[15:11], regdst, add3); //7
mux2_5 regdstb(add3, 5'b11111, ifjal, wradd); 
// to choose whether to put jump info into $31


regfile register(clk, rwrite, reset, instr[25:21], instr[20:16], wradd, w_result, reg_s, dataa, datab, r_show); //6

//
signext extend(instr[15:0], extop, longd);//8
PCBranch branch_s(longd, pc_f, pc_b); //9

mux2_32 srcb_mux(datab, longd, asrcb, alub); // 10
extender shanmtex(instr[10:6], shamt_data);
mux2_32 srca_mux(dataa, shamt_data, asrca, alua); //11 

ALU alu1(alua, alub, alucont, alu_r, zero, negative); //12\
mux2_32 write_muxa(alu_r, readmem_data, m2reg, write_data); //14
mux2_32 wirte_muxb(write_data, pc_f, ifjal, w_result);
jumpadd jump(instr[25:0], pc_f[31:28], pc_j);

endmodule

