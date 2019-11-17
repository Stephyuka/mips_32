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
//output the address of the data which demem and regfile will give out

module decoder(
	input clk, 
	input showors,
	input [6:0] sel,
	output [6:0] add_mem,
	output [4:0] add_r
	);
reg [6:0] addm;
reg [4:0] addr;
reg [6:0] count;

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
//the 7-digit light 

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


module show(
	input clkf,
	input clks,
	input [31:0] instr, clkinfo, memdata, regdata, pcinfo,
	input [15:0] sign, //the signal led output
	input [11:0] sw,
	output [6:0] mem_sl,
	output [4:0] reg_sl,
	output [15:0] led,
	output [7:0] En,
	output [6:0] CA
	);
wire [31:0] d;
mux5_32 datashow_mux(pcinfo, clkinfo, instr, regdata, memdata, sw[11:9], d);
decoder add_decoder(clks, sw[8], sw[7:1], mem_sl, reg_sl);
digit_show show_(clkf, d, En, CA);

assign led = sign;

endmodule

/******************************************************************/