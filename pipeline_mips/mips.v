module hazard(
	input [4:0] rsD, rtD, rsE, rtE,
	input [4:0] writeregE, writeregM, writeregW,
	input regwriteE, regwriteM, regwriteW, branchD, jrD,
	input [1:0] memtoregE, memtoregM, 
	input stallcF, stallcM, 
	output forwardaD, forwardbD,
	output reg [1:0] forwardaE, forwardbE,
	output stallF, stallFc, stallD, stallE, stallM, stallW,
	output flushE
);

wire lwstallD, branchstallD;
wire stallall;

assign forwardaD = (rsD != 0 & rsD == writeregM & regwriteM);
assign forwardbD = (rtD != 0 & rtD == writeregM & regwriteM);

always @(*)
  begin
  	forwardaE = 2'b00;
  	forwardbE = 2'b00;
  	if(rsE != 0)
  	   if(rsE == writeregM && regwriteM) forwardaE = 2'b10;
  	   else if(rsE == writeregW && regwriteW) forwardaE = 2'b01;
  	   else forwardaE = 2'b00;
  	else forwardaE = 2'b00;
  	if(rtE != 0)
  	   if(rtE == writeregM && regwriteM) forwardbE = 2'b10;
  	   else if(rtE == writeregW && regwriteW) forwardbE = 2'b01;
  	   else forwardbE = 2'b00;
  	else forwardbE = 2'b00;
  end

 assign  lwstallD = (memtoregE == 2'b01) & (rsE == rsD | rtE == rtD);
 assign  branchstallD = branchD & (regwriteE & (writeregE == rsD | writeregE == rtD) |
                        (memtoregM == 2'b01) & (writeregM == rsD | writeregM == rtD));

 assign jrstallD = jrD & (regwriteE & (writeregE == rsD | writeregE == rtD) |
                        (memtoregM == 2'b01) & (writeregM == rsD | writeregM == rtD));

 assign stallall = stallcF | stallcM;
 assign stallD = lwstallD | branchstallD | jrstallD | stallall;
 assign stallF = stallD;
 assign stallFc = lwstallD | branchstallD | jrstallD | stallcM;
 assign stallE = stallall;
 assign stallM = stallall;
 assign stallW = stallall;
 assign flushE = (lwstallD | branchstallD | jrstallD) & ~stallall;

endmodule


/******************************************************************/

module clkdiv(
	input mclk,
	output clk1,
	output clk18, //190HZ
	output clk190
	);
// reg [27:0] q;
 reg [5:0] q;
  initial begin q <= 0; end

    always @(posedge mclk) 
    begin
    	q <= q + 1;
    end
    assign clk1 = q[5];
    assign clk18 = q[3];
    assign clk190 = q[0];
//    assign clk1 = q[26];
//    assign clk18 = q[25];
//    assign clk190 = q[17];
endmodule



/******************************************************************/
module cpushow(
	input clock,
	//input run_en,
	//input pcshow,
	//input regormem,
	//input showors,
	//input [7:0] s,
	input [11:0] s,
	input reset,
	output [7:0] en,
	output [6:0] c,
	output [15:0] l 
	);

wire clk_cpu, clk_refresh, clk_c;
wire [31:0] clkinfo, reginfo, meminfo, fetchd, decoded, executed, memoryd, writebackd;
wire [6:0] adds;
wire [2:0] select;
wire [15:0] signF, signD, signE, signM, signW;

clkdiv clk(clock, clk_cpu, clk_c, clk_refresh);
show show(clk_refresh, clk_c, clkinfo, reginfo, meminfo, fetchd, decoded, executed, 
	      memoryd, writebackd, signF, signD, signE, signM, signW, s, adds, select, l, en, c);
mips mips(clk_cpu, reset, s[0], adds, select, clkinfo, reginfo, meminfo, fetchd, decoded, executed, 
	      memoryd, writebackd, signF, signD, signE, signM, signW);

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
module branchpredict(
	input clk, rst,
	input en, branchD,
	output branchF
	);

reg branch;
initial begin branch <= 1'b0; end
always @(posedge clk or posedge rst) 
begin
	if (rst) begin
	    branch <= 1'b0;		
	end
	else if (en) begin
		branch <= branchD;
	end
end

assign branchF = branch;
endmodule

/**********************************************************/
//module branchdecoder(
//	input [5:0] op,
//	output r);

//parameter BEQ   =  6'b000100,
//          BNE   =  6'b000101,
//          BLEZ  =  6'b000110,
//          BGTZ  =  6'b000111;

//assign r = (op == BEQ | op == BNE | op == BLEZ | op == BGTZ);
//endmodule


