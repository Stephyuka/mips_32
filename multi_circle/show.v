/******************************************************************/
module mux8_32(
	input [31:0] data1,
	input [31:0] data2,
	input [31:0] data3,
	input [31:0] data4,
	input [31:0] data5,
	input [31:0] data6,
	input [31:0] data7,
	input [31:0] data8,
	input [2:0] s,
	output reg [31:0] data
	);

always @(*) 
begin
	case(s)
	3'b000: data <= data1;
	3'b001: data <= data2;
	3'b010: data <= data3;
	3'b011: data <= data4;
	3'b100: data <= data5;
	3'b101: data <= data6;
	3'b110: data <= data7;
	3'b111: data <= data8;
	endcase
end

endmodule

/******************************************************************/

 module sevencoder(
	input [3:0] N,
	output reg [6:0] C
	); 

always @(*) 
	case(N)
	 4'b0000 : begin C = 7'b1000000; end //0
	 4'b0001 : begin C = 7'b1111001; end //1
	 4'b0010 : begin C = 7'b0100100; end //2
	 4'b0011 : begin C = 7'b0110000; end //3
	 4'b0100 : begin C = 7'b0011001; end //4
	 4'b0101 : begin C = 7'b0010010; end //5
	 4'b0110 : begin C = 7'b0000010; end //6
	 4'b0111 : begin C = 7'b1111000; end //7
	 4'b1000 : begin C = 7'b0000000; end //8
	 4'b1001 : begin C = 7'b0011000; end //9
	 4'b1010 : begin C = 7'b0001000; end //a
	 4'b1011 : begin C = 7'b0000011; end //b
	 4'b1100 : begin C = 7'b1000110; end //c
	 4'b1101 : begin C = 7'b0100001; end //d
	 4'b1110 : begin C = 7'b0000110; end //e
	 4'b1111 : begin C = 7'b0001110; end //f
	 default : begin C = 7'b0111111; end //- 

	endcase
		
endmodule


/******************************************************************/

module digit_show(
	input clk,
	input [31:0] data,
	output [7:0] A,
	output [6:0] CA
	);

//wire clkn;
//wire clkm;
reg [3:0] number_show;

parameter EN1 = 8'b11111110,
          EN2 = 8'b11111101,
          EN3 = 8'b11111011,
          EN4 = 8'b11110111,
          EN5 = 8'b11101111,
          EN6 = 8'b11011111,
          EN7 = 8'b10111111,
          EN8 = 8'b01111111;

reg [2:0] Count;
wire [3:0] number_out;
reg [7:0] en;

initial
begin
Count = 0;
end


always @(posedge clk) 
begin
	Count <= Count + 1;
end

always @(*) 
begin
    case(Count)
    3'b000:
    begin
    	number_show <= data[3:0];
    	en <= EN1;
    end
    3'b001:
    begin
    	number_show <= data[7:4];
    	en <= EN2;
    end
    3'b010:
    begin
    	number_show <= data[11:8];
    	en <= EN3;
    end
    3'b011:
    begin
    	number_show <= data[15:12];
    	en <= EN4;
    end
    3'b100:
    begin
    	number_show <= data[19:16];
    	en <= EN5;
    end
    3'b101:
    begin
    	number_show <= data[23:20];
    	en <= EN6;
    end
    3'b110:
    begin
    	number_show <= data[27:24];
    	en <= EN7;
    end
    3'b111:
    begin
    	number_show <= data[31:28];
    	en <= EN8;
    end
    endcase
end


assign number_out = number_show ;
assign A = en;

sevencoder showcode(number_out, CA);


endmodule


/******************************************************************/

module cache_show(
	input clock,
	output [1:0] s
	);

reg [1:0] count;

initial
begin
	count = 0;
end

always @(posedge clock) 
begin
	count <= count + 1;
end

assign s = count;

endmodule

/******************************************************************/
module decoder(
	input clk, 
	input showors,
	input [7:0] sel,
	output [7:0] add_mem,
	output [4:0] add_r
	);

reg [7:0] addm;
reg [4:0] addr;
reg [7:0] count;

initial count = 0;

always @(posedge clk) 
begin
	if (showors) 
	count = count + 1;
	else 
	count = 0;
end

always @(*)
begin
	if(showors)
	begin addm = count; addr = count[4:0]; end
	else  
	begin addm = sel; addr = sel[4:0]; end
end

assign add_mem = addm;
assign add_r = addr;

endmodule


/******************************************************************/

//module memory select 
//put add_mem[6:2] into the read address of  memory 

module led_s(
	input [2:0] s,
	input [15:0] sign,
	input [4:0] regadd,
	input [7:0] memadd,
	input [1:0] a,
	input flag,
	output [15:0] led );

reg [15:0] temp;

parameter cache = 3'b100,
          register = 3'b101,
          memory = 3'b110;

always @(*) 
begin
	if (s == cache)  temp = {13'b0,flag, a};
	else if (s == register)  temp = {11'b0, regadd};
	else if (s == memory)  temp = {8'b0, memadd};
	else temp = sign;
end

assign led = temp;

endmodule


/******************************************************************/


module show(
	input clk_r,
	input clk_s,
	input [15:0] sign_one, //two different sign
	input [15:0] sign_two,
	input [31:0] instr, clkinfo, memdata, regdata, pcinfo, stateinfo, cachedata,cause,
	input cache_dirty,
	input [15:0] sw,
	output [7:0] mem_add,
	output [1:0] cache_rtg, //the tag of the cache 
	output [1:0] cache_rs,
	output [4:0] reg_add,
	output [15:0] led,
	output [7:0] En,
	output [6:0] CA
	);

wire [31:0] data;
wire [15:0] sign;

mux8_32 datashow_mux(pcinfo, instr, clkinfo, stateinfo, cachedata, regdata, memdata,cause,sw[15:13], data);
decoder add_decoder(clk_s, sw[4], sw[12:5], mem_add, reg_add);
digit_show seven_show(clk_r, data, En, CA);
cache_show c_show(clk_s,cache_rs);
mux2_16 sign_mux(sign_one, sign_two, sw[1], sign);
led_s led_show(sw[15:13], sign, reg_add, mem_add, sw[3:2], cache_dirty, led);
assign cache_rtg = sw[3:2];

endmodule

/******************************************************************/
module mux2_16(
   input [15:0] d1,
   input [15:0] d2,
   input s,
   output [15:0] d
);
assign d = s == 0 ? d1 : d2;
endmodule