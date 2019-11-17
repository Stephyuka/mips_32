/**********************/
module flopr(input clk,
            input rest,
            input en,
           	input [31:0] pc,
           	output [31: 0] next_pc);

reg [31:0] pc_n;

initial begin pc_n <= 0; end

always @(posedge clk or posedge rest)
begin  //reset is triggered when volt is high
      if(rest) 
         pc_n <= 0;
      else if(en)
         pc_n <= pc;
end

assign next_pc = pc_n ;

endmodule

/******************************************************************/

module reg32_en (input [31:0] A,
	           input clk,
	           input rst,
	           input en,
	           output [31:0] S);
reg [31:0] temp;
initial begin temp <= 0; end

always @(posedge clk) 
begin
    if (rst)
      temp <= 0;
	else if (en) 
	  temp <= A;
end

assign S = temp;

endmodule

//the 32 - bit data should be stored in reg for next circlr
//e.g. instr \ ALUsrcA \ ALUsrcB \ ALUres \ Memdata
/******************************************************************/

module reg32 (input [31:0] A,
	          input clk,
	          input rst,
	          output [31:0] S);
reg [31:0] temp;
initial temp <= 0;
always @(posedge clk or posedge rst ) 
begin
	if (rst) 
		temp <= 0;
	else 
	    temp <= A;
end

assign  S = temp;

endmodule

/******************************************************************/
//it is the same as the one of single - cycled so far 
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

/*****************************************************************/
//it is the same as the one of single - cycled so far 

module ALU(input [31:0] A,
	       input [31:0] B,
	       input [3:0] alucont,
	       output [31:0] result,
	       output zero,
	       output neg,
	       output reg overflow
	       );

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
    ADDU: begin temp = A + B; overflow = 0; end// addu
    SUBU: begin temp = A - B; overflow = 0; end// subu
    ADD : begin temp = SrcA + SrcB; overflow = temp[31] ^ temp[32]; end   // r = a + b (signed) add
    SUB : begin temp = SrcA - SrcB; overflow = temp[31] ^ temp[32]; end  // r = a - b (signed) sub
    AND : begin temp = A & B;overflow = 0; end  // r = a & b and
    OR  : begin temp = A | B;overflow = 0; end  // r = a | b or
    XOR : begin temp = A ^ B;overflow = 0; end  // r = a ^ b xor
    NOR : begin temp = ~(A | B);overflow = 0; end // r = ~(a | b) nor
    SLT : begin temp = (SrcA < SrcB) ? 1 : 0;overflow = 0; end// slt
    SLTU: begin temp = (A < B) ? 1 : 0; overflow = 0; end
    SLL : begin temp = B << A; overflow = 0; end //sll
    SRL : begin
            if(A == 0)
            {temp[31:0], temp[32]} = {B, 1'b0};
            else 
            {temp[31:0],temp[32]} = B >> (A - 1); // srl
            overflow = 0;
          end
    SRA : begin
    	      if(A == 0)
    	      {temp[31:0], temp[32]} = {B, 1'b0};
    	      else {temp[31:0], temp[32]} = SrcB >>> (A - 1); // sra
    	      overflow = 0;
    	    end
    LUI : begin
          {temp[31:0], temp[32]} = {B[15:0], 17'b0};
          overflow = 0;
          end
    default:begin temp = A + B; overflow = 0; end

endcase
assign  result = temp[31:0] ;
assign  zero = (result == 32'b0) ? 1 : 0;
assign  neg = result[31];
endmodule


/*****************************************************************/
module mux4_32 (input [31:0] d1,
	            input [31:0] d2,
	            input [31:0] d3,
	            input [31:0] d4,
	            input [1:0] s,
	            output reg [31:0] r);

always @(*)
begin
case(s)
    2'b00: r = d1;
    2'b01: r = d2;
    2'b10: r = d3;
    2'b11: r = d4;
endcase
end
endmodule

/*******************************************************/

module mux2_32(input [31:0] d1,
	          input [31:0] d2,
	          input s,
	          output reg [31:0] r);
always @(*) 
begin
case(s)
   1'b0: r = d1;
   1'b1: r = d2;
endcase
end
endmodule
/*******************************************************/

module mux3_5(input [4:0] d1,
	          input [4:0] d2,
	          input [4:0] d3,
	          input [1:0] s,
	          output reg [4:0] r);
always @(*) 
begin
case(s)
   2'b00: r = d1;
   2'b01: r = d2;
   2'b10: r = d3;
   default: r = d1; // impossible
endcase
end
endmodule

/*******************************************************/

module mux3_32(input [31:0] d1,
	          input [31:0] d2,
	          input [31:0] d3,
	          input [1:0] s,
	          output reg [31:0] r);
always @(*) 
begin
case(s)
   2'b00: r = d1;
   2'b01: r = d2;
   2'b10: r = d3;
   default: r = d1; // impossible
endcase
end
endmodule

/*******************************************************/

module mux5_32(input [31:0] d1,
	           input [31:0] d2,
	           input [31:0] d3,
	           input [31:0] d4,
	           input [31:0] d5,
	           input [2:0] s,
	           output reg [31:0] r);
always @(*) 
begin
case(s)
   3'b000: r = d1;
   3'b001: r = d2;
   3'b010: r = d3;
   3'b011: r = d4;
   3'b100: r = d5;
   default: r = d1; // impossible
endcase
end
endmodule

/*******************************************************/

module jumpadd(input [25:0] a,
	           input [3:0] p,
	           output [31:0] ja);
assign ja = {p, a, 2'b00} ;
endmodule

/*******************************************************/

module signext(input [15:0] a,
             input s,
	           output [31:0] y);


assign y = (s == 1) ? {{16{a[15]}},a} : {16'b0, a};

endmodule

/***************************************************/
module extender(input [4:0] shamt,
                output [31:0] s);
assign s = {27'b0, shamt} ;

endmodule
