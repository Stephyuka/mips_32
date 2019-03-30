`timescale 1ns / 1ps
/**********************/
module flopr(input clk,
            input rest,
           	input [31:0] pc,
           	output [31: 0] next_pc);

reg [31:0] pc_n;
initial begin pc_n <= 0; end
always @(posedge clk or posedge rest)
begin  //reset is triggered when volt is high
      if(rest) 
         pc_n <= 0;
      else 
         pc_n <= pc;
end

assign next_pc = pc_n ;

endmodule


/******************************************************************/

module pcplus4(input [31:0] pc,
	           output [31:0]pc_n);
assign pc_n = pc + 4;
endmodule


/******************************************************************/
//read rs from register file
//regfile
`timescale 1ns / 1ps
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
  
always @(posedge clk or posedge rst) 
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
	else
	    rf[wadd] = rf[wadd];
end
     //register 0 cannot be changed
assign rd1 = (ra1 != 0) ? rf[ra1] : 0;
assign rd2 = (ra2 != 0) ? rf[ra2] : 0;
assign data_s = (sl != 0) ? rf[sl] : 0;

/*always@(*)
begin
case(ra1)
   5'b0:rd1 = 32'b0;
   default:rd1 = rf[ra1];
   endcase
case(ra2)
    5'b0:rd2 = 32'b0;
    default:rd2 = rf[ra2];
    endcase
end*/

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
	       output [31:0] result,
	       output zero,
	       output neg);

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
assign  zero = (result == 32'b0) ? 1 : 0;
assign  neg = result[31];

endmodule

/*******************************************************/
module mux2_32(input [31:0] a, b,
	           input s,
	           output [31:0] r);
assign r = s? b: a;
endmodule
/*******************************************************/

module mux2_5(input [4:0] a, b,
	        input s,
	        output [4:0] r);
assign r = s? b : a;
endmodule

/*******************************************************/

module jumpadd(input [25:0] a,
	           input [3:0] p,
	           output [31:0] ja);
assign ja = {p, a, 2'b00} ;
endmodule
