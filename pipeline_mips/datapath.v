`timescale 1ns / 1ps
/**********************/
module Fetchreg(input clk,
                 input reset,
                 input en,
                 input [31:0] pc,
                 output [31:0] next_pc);
reg [31:0] pc_n;
initial begin pc_n <= 0; end
always @(posedge clk or posedge reset)
begin  //reset is triggered when volt is high
      if(reset) 
         pc_n <= 0;
      else if(en)
         pc_n <= pc;
end

assign next_pc = pc_n ;

endmodule


/******************************************************************/
module Decodereg( input clk,
                  input en,
                  input reset,
                  input clr,
                  input [31:0] instrF, pcplus4F, SignImmF, pcBranchF,
                  input [3:0] AlucontrolF,
                  input [1:0] MemtoRegF, RegdstF,
                  input AlusrcaF, AlusrcbF,
                  input branchF, ifbranchF, ifjrF, regwriteF, memwriteF,
                  output [31:0] instrD, pcplus4D, SignImmD, pcBranchD,
                  output [3:0] AlucontrolD,
                  output [1:0] MemtoRegD, RegdstD,
                  output AlusrcaD, AlusrcbD,
                  output branchD, ifbranchD, ifjrD, regwriteD, memwriteD
                  );

reg [31:0] instr, pcplus4, SignImm, pcBranch;
reg [3:0] Alucontrol;
reg [1:0] MemtoReg, Regdst;
reg Alusrca, Alusrcb, branch, ifbranch, regwrite, memwrite, ifjr;

initial 
begin 
    instr      <=  32'b0; 
    pcplus4    <=  32'b0;
    SignImm    <=  32'b0;
    pcBranch   <=  32'b0;
    Alucontrol <=  4'b0;
    MemtoReg   <=  2'b0;
    Regdst     <=  2'b0;
    Alusrca    <=  1'b0;
    Alusrcb    <=  1'b0;
    branch     <=  1'b0;
    ifbranch   <=  1'b0;
    ifjr       <=  1'b0;
    regwrite   <=  1'b0;
    memwrite   <=  1'b0;
end

always @(posedge clk or posedge reset) 
begin
  if (reset | clr) 
  begin
    instr      <=  32'b0; 
    pcplus4    <=  32'b0;
    SignImm    <=  32'b0;
    pcBranch   <=  32'b0;
    Alucontrol <=  4'b0;
    MemtoReg   <=  2'b0;
    Regdst     <=  2'b0;
    Alusrca    <=  1'b0;
    Alusrcb    <=  1'b0;
    branch     <=  1'b0;
    ifbranch   <=  1'b0;
    ifjr       <=  1'b0;
    regwrite   <=  1'b0;
    memwrite   <=  1'b0;
  end
  else if (en) 
  begin
    instr      <=  instrF;
    pcplus4    <=  pcplus4F;
    SignImm    <=  SignImmF;
    pcBranch   <=  pcBranchF;
    Alucontrol <=  AlucontrolF;
    MemtoReg   <=  MemtoRegF;
    Regdst     <=  RegdstF;
    Alusrca    <=  AlusrcaF;
    Alusrcb    <=  AlusrcbF;
    branch     <=  branchF;
    ifbranch   <=  ifbranchF;
    ifjr       <=  ifjrF;
    regwrite   <=  regwriteF;
    memwrite   <=  memwriteF;
  end
end

assign  instrD       =   instr;
assign  pcplus4D     =   pcplus4;
assign  SignImmD     =   SignImm;
assign  pcBranchD    =   pcBranch;
assign  AlucontrolD  =   Alucontrol;
assign  MemtoRegD    =   MemtoReg; 
assign  RegdstD      =   Regdst;
assign  AlusrcaD     =   Alusrca;
assign  AlusrcbD     =   Alusrcb;
assign  branchD      =   branch;
assign  ifbranchD    =   ifbranch;
assign  ifjrD        =   ifjr;
assign  regwriteD    =   regwrite;
assign  memwriteD    =   memwrite;

endmodule

/******************************************************************/
module Excuetereg(input clk,
                   input en,
                   input reset,
                   input clr,
                   input [4:0] RsD,
                   input [4:0] RtD,
                   input [4:0] RdD,
                   input [31:0] SignImmD,
                   input [31:0] shamtdataD,
                   input [31:0] dataaD, databD,
                   input [31:0] pcD,
                   input RegWriteD, MemWriteD,
                   input AlusrcaD, AlusrcbD,
                   input [1:0] MemtoRegD,
                   input [3:0] AlucontrolD,
                   input [1:0] RegdstD,
                   output [4:0] RsE,
                   output [4:0] RtE,
                   output [4:0] RdE,
                   output [31:0] SignImmE,
                   output [31:0] shamtdataE,
                   output [31:0] dataaE, databE,
                   output [31:0] pcE,
                   output RegWriteE, MemWriteE,
                   output AlusrcaE, AlusrcbE,
                   output [1:0] MemtoRegE,
                   output [3:0] AlucontrolE,
                   output [1:0] RegdstE
                   );

reg [4:0] Rs, Rt, Rd;
reg [31:0] SignImm, shamtdata, dataa, datab, pc;
reg RegWrite, MemWrite, Alusrca, Alusrcb;
reg [1:0] Regdst, MemtoReg;
reg [3:0] Alucontrol;

initial 
begin
  Rs         <=  5'b0;
  Rd         <=  5'b0;
  Rt         <=  5'b0;
  SignImm    <=  32'b0;  
  shamtdata  <=  32'b0;
  dataa      <=  32'b0;
  datab      <=  32'b0;
  pc         <=  32'b0;
  RegWrite   <=  1'b0;
  MemtoReg   <=  2'b0;
  MemWrite   <=  1'b0;
  Alusrca    <=  1'b0;
  Alusrcb    <=  1'b0;
  Regdst     <=  2'b0;
  Alucontrol <=  4'b0;
end

always @(posedge clk or posedge reset) 
begin
  if (reset | clr) 
  begin
    Rs         <=  5'b0;
    Rd         <=  5'b0;
    Rt         <=  5'b0;
    SignImm    <=  32'b0;  
    shamtdata  <=  32'b0;
    dataa      <=  32'b0;
    datab      <=  32'b0;
    pc         <=  32'b0;
    RegWrite   <=  1'b0;
    MemtoReg   <=  2'b0;
    MemWrite   <=  1'b0;
    Alusrca    <=  1'b0;
    Alusrcb    <=  1'b0;
    Regdst     <=  2'b0;
    Alucontrol <=  4'b0;
  end
  else if(en)
  begin
    Rs <= RsD;
    Rd <= RdD;
    Rt <= RtD;
    SignImm   <= SignImmD;
    shamtdata <= shamtdataD;
    dataa     <= dataaD;
    datab     <= databD;
    pc        <= pcD;
    RegWrite  <= RegWriteD;
    MemtoReg  <= MemtoRegD;
    MemWrite  <= MemWriteD;
    Alusrca   <= AlusrcaD;
    Alusrcb   <= AlusrcbD;
    Regdst    <= RegdstD;
    Alucontrol <= AlucontrolD;
  end
end

assign  RsE = Rs;
assign  RdE = Rd;
assign  RtE = Rt;
assign  SignImmE   = SignImm;
assign  shamtdataE = shamtdata;
assign  dataaE     = dataa;
assign  databE     = datab;
assign  pcE        = pc;
assign  RegWriteE  = RegWrite;
assign  MemtoRegE  = MemtoReg;
assign  MemWriteE  = MemWrite;
assign  AlusrcaE   = Alusrca;
assign  AlusrcbE   = Alusrcb;
assign  RegdstE    = Regdst;
assign  AlucontrolE = Alucontrol;

endmodule

/******************************************************************/
module Memoryreg(input clk,
                  input en,
                  input rst,
                  input [31:0] AluOutE,
                  input [31:0] WriteDataE,
                  input [31:0] pcE,
                  input [4:0] WriteRegE,
                  input RegWriteE,
                  input [1:0] MemtoRegE,
                  input MemWriteE,
                  output [31:0] AluOutM,
                  output [31:0] WriteDataM,
                  output [31:0] pcM,
                  output [4:0] WriteRegM,
                  output RegWriteM,
                  output [1:0] MemtoRegM,
                  output MemWriteM
                  );

reg [31:0] AluOut, WriteData, pc;
reg [4:0] WriteReg;
reg RegWrite, MemWrite;
reg [1:0] MemtoReg;

initial
begin
  AluOut    <= 32'b0;
  WriteData <= 32'b0;
  pc        <= 32'b0;
  WriteReg  <= 5'b0;
  RegWrite  <= 1'b0;
  MemWrite  <= 1'b0;
  MemtoReg  <= 2'b0;
end

always @(posedge clk or posedge rst) 
begin
  if (rst) 
  begin
    AluOut    <= 32'b0;
    WriteData <= 32'b0;
    pc        <= 32'b0;
    WriteReg  <= 5'b0;
    RegWrite  <= 1'b0;
    MemWrite  <= 1'b0;
    MemtoReg  <= 2'b0;
  end
  else if(en)
  begin
    AluOut <= AluOutE;
    WriteData <= WriteDataE;
    pc        <= pcE;
    WriteReg  <= WriteRegE;
    RegWrite  <= RegWriteE;
    MemWrite  <= MemWriteE;
    MemtoReg  <= MemtoRegE;
  end
end

assign  AluOutM    = AluOut;
assign  WriteDataM = WriteData;
assign  pcM        = pc;
assign  WriteRegM  = WriteReg;
assign  RegWriteM  = RegWrite;
assign  MemWriteM  = MemWrite;
assign  MemtoRegM   = MemtoReg;

endmodule

/******************************************************************/

module Writebackreg(input clk,
                    input en,
                    input rst,
                    input RegWriteM,
                    input [31:0] ReaddataM, AluOutM, pcM,
                    input [4:0] WriteRegM,
                    input [1:0] MemtoRegM,
                    output RegWriteW,
                    output [31:0] ReaddataW, AluOutW, pcW,
                    output [4:0] WriteRegW,
                    output [1:0] MemtoRegW);

reg [31:0] Readdata, AluOut, pc;
reg [4:0] WriteReg;
reg [1:0] MemtoReg;
reg RegWrite;

initial
begin
  Readdata <= 32'b0;
  AluOut   <= 32'b0;
  pc       <= 32'b0;
  WriteReg <= 5'b0;
  MemtoReg <= 2'b0;
  RegWrite <= 1'b0;
end

always @(posedge clk or posedge rst) 
begin
  if (rst) begin
    Readdata <= 32'b0;
    AluOut   <= 32'b0;
    pc       <= 32'b0;
    WriteReg <= 5'b0;
    MemtoReg <= 2'b0;
    RegWrite <= 1'b0;
  end
  else if(en)
  begin
    Readdata <= ReaddataM;
    AluOut   <= AluOutM;
    pc       <= pcM;
    WriteReg <= WriteRegM;
    MemtoReg <= MemtoRegM;
    RegWrite <= RegWriteM;
  end
end

assign ReaddataW  =  Readdata;
assign AluOutW    =  AluOut;
assign pcW        =  pc;
assign WriteRegW  =  WriteReg;
assign MemtoRegW  =  MemtoReg;
assign RegWriteW  =  RegWrite;

endmodule

/******************************************************************/

module pcplus4(input [31:0] pc,
	           output [31:0]pc_n);
assign pc_n = pc + 4;
endmodule

/******************************************************************/

module regfile(
	input clk, wen, rst,
	input [4:0] ra1, ra2,
	input [4:0] wadd,
	input [31:0] wdata,
    input [4:0] sl,
	output [31:0] rd1, rd2,
  output [31:0] data_s);

reg [31:0] rf [31:0];  //32 32-bit registerfile
integer i;

initial
  begin
  for(i = 0; i < 32; i = i + 1)
  rf[i] = 32'b0;
  end
  
always @(negedge clk or posedge rst) 
begin
    if(rst)
    begin
       for(i = 0; i < 32; i = i + 1)
       begin
       	rf[i] = 32'b0;
       	end
    end
    //if rest, all the register will be cleared
	else if (wen && (wadd != 0))
	     rf[wadd] = wdata;
end
     //register 0 cannot be changed
assign rd1 = (ra1 != 0) ? rf[ra1] : 0;
assign rd2 = (ra2 != 0) ? rf[ra2] : 0;
assign data_s = (sl != 0) ? rf[sl] : 0;


endmodule


/******************************************************************/

module signext(input [15:0] a,
             input s,
	           output [31:0] y);


assign y = (s == 1) ? {{16{a[15]}},a} : {16'b0, a};

endmodule

/******************************************************************/
module extender(input [4:0] shamt,
                output [31:0] s);
assign s = {27'b0, shamt} ;

endmodule

/******************************************************************/

module PCBranch(input [31:0] a,
	            input [31:0]pc_4,
	            output [31:0] pc_b);
assign pc_b = pc_4 + {a[29:0],2'b00};

endmodule


/**********************/

module ALU(input [31:0] A,
	       input [31:0] B,
	       input [3:0] alucont,
	       output [31:0] result);

reg [32:0] temp;
wire signed [31:0] SrcA = A, SrcB = B;

parameter ADDU = 4'b0000,
          SUBU = 4'b0001,
          ADD  = 4'b0010,
          SUB  = 4'b0011,
          OR   = 4'b0100,
          AND  = 4'b0101,
          XOR  = 4'b0110,
          NOR  = 4'b0111,
          SLTU = 4'b1000,
          SLT  = 4'b1001,
          SLL  = 4'b1010,
          SRL  = 4'b1011,
          SRA  = 4'b1100,
          LUI  = 4'b1101;

always @(*)
case(alucont)
    ADDU: temp = A + B; // addu
    SUBU: temp = A - B; // subu
    ADD : temp = SrcA + SrcB;  // r = a + b (signed) add
    SUB : temp = SrcA - SrcB;  // r = a - b (signed) sub
    AND : temp = A & B;  // r = a & b and
    OR  : temp = A | B;  // r = a | b or
    XOR : temp = A ^ B;  // r = a ^ b xor
    NOR : temp = ~(A | B); // r = ~(a | b) nor
    SLT : temp = (SrcA < SrcB) ? 1 : 0; // slt
    SLTU: temp = (A < B) ? 1 : 0;
    SLL : temp = B << A; //sll
    SRL : begin
            if(A == 0)
            {temp[31:0], temp[32]} = {B, 1'b0};
            else 
            {temp[31:0],temp[32]} = B >> (A - 1); // srl
          end
    SRA : begin
    	      if(A == 0)
    	      {temp[31:0], temp[32]} = {B, 1'b0};
    	      else {temp[31:0], temp[32]} = SrcB >>> (A - 1); // sra
    	    end
    LUI : begin
          {temp[31:0], temp[32]} = {B[15:0], 17'b0};
          end
    default:temp = A + B;

endcase
assign  result = temp[31:0] ;
//assign  zero = (result == 32'b0) ? 1 : 0;
//assign  neg = result[31];

endmodule

/*******************************************************/

module mux2_32(input [31:0] a, b,
	           input s,
	           output [31:0] r);
assign r = s? b: a;
endmodule

/*******************************************************/

//module mux2_5(input [4:0] a, b,
//	        input s,
//	        output [4:0] r);
//assign r = s? b : a;
//endmodule

/*******************************************************/

module jumpadd(input [25:0] a,
	           input [3:0] p,
	           output [31:0] ja);

assign ja = {p, a, 2'b00} ;
endmodule

/*******************************************************/

module mux3_32(input [31:0] d1,
               input [31:0] d2,
               input [31:0] d3,
               input [1:0] s,
               output [31:0] r);

assign r = (s == 2'b00) ? d1 : ((s == 2'b01) ? d2 : d3);
endmodule

/*******************************************************/

module mux4_32(input [31:0] d1,
               input [31:0] d2,
               input [31:0] d3,
               input [31:0] d4,
               input [1:0] s,
               output [31:0] r);
assign r = (s == 2'b00) ? d1 : ((s == 2'b01) ? d2 : ((s == 2'b10) ? d3: d4));
endmodule

/*******************************************************/

module mux3_5(input [4:0] d1,
              input [4:0] d2,
              input [4:0] d3,
              input [1:0] s,
              output [4:0] r);
assign r = (s == 2'b00) ? d1 : ((s == 2'b01) ? d2 : d3);
endmodule

/******************************************************************/
//instruction memory

module instrmem(input [5:0] a,
            output [63:0] rd);

instr_mem imem (
  .a(a),      // input wire [5 : 0] a
  .spo(rd)  // output wire [31 : 0] spo
);
 endmodule

/******************************************************************/

module Fastcac(input[31:0] a,b,
               output zero, neg
               );
wire[31:0] result;
assign  result =  a - b;
assign  zero = result == 0;
assign  neg  =  result[31] == 1;

endmodule

/******************************************************************/

module mux5_32(
  input [31:0] data1, data2, data3, data4, data5,
  input [2:0] sel,
  output [31:0] data_out);
  
reg [31:0] data;
always @(*)
begin
  casez(sel)
  3'b??1:data <= data1; //pc
  3'b000:data <= data2; //clock
  3'b010:data <= data3; //instr
  3'b100:data <= data4; //reg
  3'b110:data <= data5; //demem
  endcase
end

assign data_out = data;

endmodule


/******************************************************************/

module branchjudge(
  input [5:0] op,
  input zero, neg,
  output branchnew
  );

parameter BEQ   =  6'b000100,
         BNE   =  6'b000101,
         BLEZ  =  6'b000110,
         BGTZ  =  6'b000111;
assign branchnew = (op == BEQ & zero) | ( op == BNE & ~zero) | (op == BLEZ &(zero | neg)) | (op == BGTZ & ~zero & ~neg);

endmodule

/******************************************************************/

module mux6_32(
  input [31:0] data1, data2, data3, data4, data5, data6,
  input [2:0] sel,
  output [31:0] data_out);
  
reg [31:0] data;
always @(*)
begin
  case(sel)
  3'b000:  data  <=  data1; 
  3'b001:  data  <=  data2; 
  3'b010:  data  <=  data3; 
  3'b011:  data  <=  data4; 
  3'b100:  data  <=  data5; 
  default: data  <=  data6;
  endcase
end

assign data_out = data;

endmodule

/******************************************************************/
module datamemory(input [5:0] a,
             input [63:0] WD,
             input clk,WE,
             input [6:0] sl,
             output [31:0] data_s,
             output [63:0] RD);
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
wire [63:0] show;
datamem memory (
  .a(a[5:0]),        // input wire [6 : 0] a
  .d(WD),        // input wire [31 : 0] d
  .dpra(sl[6:1]),  // input wire [6 : 0] dpra
  .clk(clk),    // input wire clk
  .we(WE),      // input wire we
  .spo(RD),    // output wire [31 : 0] spo
  .dpo(show)    // output wire [31 : 0] dpo
);
assign data_s = (sl[0] == 0) ? show[31:0] : show[63:32];
// a dual-ram

endmodule

