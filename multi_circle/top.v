module cputop(
	input CLK100MHZ,
	input [15:0] SW,
	input BTNC,
	output [7:0] AN,
	output [6:0] CA,
	output [15:0] LED
	);

//cpushow show(.clock(CLK100MHZ), .run_en(SW[0]), .pcshow(SW[1]), .regormem(SW[2]), .showors(SW[3]), .s(SW[11:4]), .reset(BTNC),.en(AN),.c(CA),.l(LED));
cpushow show(.clock(CLK100MHZ), .s(SW[15:0]), .reset(BTNC),.en(AN),.c(CA),.l(LED));

endmodule

/******************************************************************/
module clkdiv(
	input mclk,
	output clk1,
	output clk18, //190HZ
	output clk190
	);
//reg [27:0] q;
reg [5:0] q;
  initial begin q <= 0; end

    always @(posedge mclk) 
    begin
    	q <= q + 1;
    end
 assign clk1 = q[5];
 assign clk18 = q[3];
 assign clk190 = q[0];
//   assign clk1 = q[26];
//   assign clk18 = q[25];
//   assign clk190 = q[17];
endmodule

/******************************************************************/
module cpushow(
	input clock,
	input [15:0] s,
	input reset,
	output [7:0] en,
	output [6:0] c,
	output [15:0] l 
	);

wire clk_cpu, clk_refresh, clk_c;
wire [31:0] instr, clkinfo, memdata, regdata, pcinfo, stateinfo, cachedata,cause;
wire c_dirty;
wire [7:0] mem_s;
wire [4:0] reg_s;
wire [15:0] sign_one, sign_two;
wire [1:0] c_shows, c_showt;


clkdiv clk(clock, clk_cpu, clk_c, clk_refresh);
show show(clk_refresh, clk_c, sign_one, sign_two, instr, clkinfo, memdata, regdata,
	      pcinfo, stateinfo, cachedata, cause,c_dirty, s, mem_s, c_showt, c_shows, reg_s, l, en, c);

mips_top mips_top(clk_cpu, reset, s[0], mem_s, reg_s, c_showt, c_shows,
                  instr, clkinfo, memdata, regdata, pcinfo, cachedata,
                  stateinfo, cause, c_dirty, sign_one, sign_two);
//assign l[1] = clk_c;

endmodule
