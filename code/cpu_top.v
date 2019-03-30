module cputop(
	input CLK100MHZ,
	input [11:0] SW,
	input BTNC,
	output [7:0] AN,
	output [6:0] CA,
	output [15:0] LED
	);

//cpushow show(.clock(CLK100MHZ), .run_en(SW[0]), .pcshow(SW[1]), .regormem(SW[2]), .showors(SW[3]), .s(SW[11:4]), .reset(BTNC),.en(AN),.c(CA),.l(LED));
cpushow show(.clock(CLK100MHZ), .s(SW[11:0]), .reset(BTNC),.en(AN),.c(CA),.l(LED));

endmodule

/******************************************************************/

module clkdiv(
	input mclk,
	output clk1,
	output clk18, //190HZ
	output clk190
	);
 reg [27:0] q;
// reg [5:0] q;
  initial begin q <= 0; end

    always @(posedge mclk) 
    begin
    	q <= q + 1;
    end
 //   assign clk1 = q[5];
 //   assign clk18 = q[3];
 //   assign clk190 = q[0];
    assign clk1 = q[26];
    assign clk18 = q[25];
    assign clk190 = q[17];
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
wire [31:0] instr, clkinfo, memdata, regdata, pcinfo;
wire [6:0] mem_s;
wire [4:0] reg_s;
wire [15:0] sinfo;

clkdiv clk(clock, clk_cpu, clk_c, clk_refresh);

show show_mode(clk_refresh, clk_c, instr, clkinfo, memdata, regdata, pcinfo,
	           sinfo, s, mem_s, reg_s, l, en, c);
	           
top mips_top(clk_cpu, reset, s[0], mem_s, reg_s, instr, clkinfo, memdata, regdata, pcinfo, sinfo);

//assign l[1] = clk_c;

endmodule


