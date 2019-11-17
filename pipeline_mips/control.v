/******************************************************************/

module controlunit(
  input [5:0] Op,
  input [5:0] Fun,
  output [1:0] M2REG, // [1:0]
  output MWRITE,
  output BRANCH,
  output JREG,
  output [1:0] PCSrc,
  output reg [3:0] alucont,
  output [1:0] REGDEST,
  output ALUSRCB,
  output ALUSRCA,
  output REGWRITE,
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

wire JALL, JUMP;

 //control unit
/*controlunit control(instrF[31:26], instrF[5:0], memtoregF, memwriteF, ifbranchF, pcsrc,
                    alucontrolF, regdstF, alusrcaF, alusrcbF, regwriteF, extop);*/
assign M2REG = (Op == LW) ? 2'b01 : ((Op == JAL | (Op == REGOP & Fun == JALR)) ? 2'b10 : 2'b00);
//only when lw, we should write from mem to reg
assign MWRITE = Op == SW ;
//when sw, we shoulf write data into mem
assign BRANCH = (Op == BEQ) || (Op == BNE) || (Op == BLEZ) || (Op == BGTZ);
//BEQ\BNE\BGTZ\BLEZ
assign ALUSRCB = (Op == SW) || (Op == LW) || (Op == ADDI) || (Op == ORI) || (Op == ANDI) || (Op == XORI) || (Op == SLTI) || (Op == LUI);

assign ALUSRCA = (Op == REGOP) && (Fun == SRL || Fun == SLL || Fun == SRA);

assign REGDEST = ((Op == REGOP) && (Fun != JALR)) ? 2'b01 : ((Op == JAL) | ((Op == REGOP) && (Fun == JALR)) ? 2'b10: 2'b00) ; //when choose instr[21:16], the flag is 1;

assign REGWRITE = ~(((Op == REGOP) && (Fun == JR)) || (Op == SW) || (Op == BNE) || (Op == BEQ) || (Op == J) || (Op == BGTZ) || (Op == BLEZ)) ;

assign JALL = (Op == JAL) || (Op == REGOP && Fun == JALR);
//if writereg, the written reg is $31
assign JUMP = (Op == J) || (Op == JAL) ;

assign JREG = (Op == REGOP) && ((Fun == JR) || (Fun == JALR));

assign PCSrc = JUMP ? 2'b10 : (BRANCH ? 2'b01: 2'b00);

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
