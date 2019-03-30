`timescale 1ns / 1ps
module sim();
reg clock;
reg en;
reg [31:0] add;
reg [31:0] write_data;
wire [31:0] read_data;

datamem memory(add, write_data, clock, en, read_data);

initial
begin
	clock = 0;
	forever #20 clock = ~clock;
end

initial
begin
	add = 32'b0;
	en = 1'b0;
	write_data = 32'hf443243d;
	#50
	en = 1'b1;
	#50
	$stop
end

endmodule