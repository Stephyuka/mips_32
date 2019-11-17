module control_fsm(input clk,
	               input rst,
	               input [5:0] op,
	               input [5:0] func,
	               input zero,
	               input negative,
	               input overflow,
	               input miss, dirty,
	               output memwrite, irwrite, regwrite, iord, writeback,extop,
	               output pcen, update, epcwrite, causewrite,intcause,
	               output [1:0] alusrcb, alusrca, regdest, memtoreg,
	               output [2:0] pcsrc, 
	               output [3:0] alucont,
	               output [31:0] state_info);


parameter FETCH   =   5'b00000,
          FCDIRTY   =   5'b00001,
          FCUPDATE  =   5'b00010,
          DECODE    =   5'b00011,
          BRANCHI    =   5'b00100,
          JUMPI     =   5'b00101,
          JALI      =   5'b00110,
          JRI       =   5'b00111,
          JRALI     =   5'b01000,
          IEX       =   5'b01001,
          IWB       =   5'b01010,
          MEMADR    =   5'b01011,
          MEMRD     =   5'b01100,
          MEMWB     =   5'b01101,
          MEMWR     =   5'b01110,
          REGEX     =   5'b01111,
          REGWB     =   5'b10000,
          MFC0      =   5'b10001,
          OVFLOW    =   5'b10010,
          UNDEFINED =   5'b10011,
          LCDIRTY   =   5'b10100,
          LCUPDATE  =   5'b10101,
          SCDIRTY   =   5'b10110,
          SCUPDATE  =   5'b10111;



/********************************************************************/

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
          MFC   =  6'b010000,

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

reg [4:0] state, next_state;
wire branch;
wire pcwrite;

initial begin state = FETCH; next_state = FETCH; end

always @(posedge clk or posedge rst) 
begin
	if (rst) 
	state = FETCH;
	else 
	state = next_state;
end

assign state_info = {27'b0, state};
reg [26:0] control;
always @(posedge clk) 
begin
    control <= 27'b0;
    control[11] <= 1'b1;
		case(state)
    FETCH:   begin
                 control[4] <= 1'b0;
                 control[13:12] <= 2'b00;
                 control[15:14] <= 2'b01;
                 control[26:23] <= A_addu;
                 control[22:20] <= 3'b000;
                 control[2] <= !miss;
                 control[0] <= !miss;
                 control[7] <= 1'b0;
                 control[3] <= 1'b0;
                 control[1] <= 1'b0;
                 control[8] <= 1'b0;
                 control[9] <= 1'b0;
                 control[5] <= 1'b0;
                 control[10] <= 1'b0;
                 control[17:16] <= 2'b00;
                 control[19:18] <= 2'b00;
                 control[6] <= 1'b0;
                 control[11] <= 1'b1;
             end
    FCDIRTY: begin
             control[2] <= 1'b0;
             control[5] <= 1'b1;
             control[0] <= 1'b0; 
           end
    FCUPDATE: begin
               control[0] <= 1'b0;
               control[2] <= 1'b0;
               control[5] <= 1'b0;
               control[7] <= 1'b1;
              end
    DECODE:  begin
                 control[7] <= 1'b0;
                 control[13:12] <= 2'b00;
                 control[15:14] <= 2'b11;
                 control[26:23] <= A_addu;
                 control[0] <= 1'b0;
                 control[2] <= 1'b0;
             end
    BRANCHI:  begin
                 control[13:12] <= 2'b10;
                 control[2] <= 1'b0;
                 control[15:14] <= 2'b00;
                 control[26:23] <= A_subu;
                 control[22:20] <= 3'b001;
                 case(op)
                   BEQ: control[6] <= zero;
                   BNE: control[6] <= !zero;
                   BLEZ: control[6] <= zero | negative;
                   BGTZ: control[6] <= !negative;
                   default: control[6] <= 1'b0;
                 endcase
                end
     JUMPI:   begin
               control[22:20] <= 3'b010;
               control[2] <= 1'b0;
               control[0] <= 1'b1;
           end
     JALI:    begin
               control[22:20] <= 3'b010;
               control[17:16] <= 2'b10;
               control[2] <= 1'b0;
               control[19:18] <= 2'b11;
               control[3] <= 1'b1;
               control[0] <= 1'b1;
           end
     JRALI:   begin
               control[22:20] <= 3'b100;
               control[2] <= 1'b0;
               control[0] <= 1'b1;
               control[19:18] <= 2'b11;
               control[17:16] <= 2'b10;
               control[3] <= 1'b1;
           end
     JRI:   begin
               control[22:20] <=  3'b100;
               control[0] <= 1'b1;
               control[2] <= 1'b0;
           end
     IEX:     begin
               control[13:12] <= 2'b10;
               control[15:14] <= 2'b10;
               control[0] <= 1'b0;
               control[2] <= 1'b0;
               case(op)
                 ADDI: control[26:23] <= A_add; //add
                 ANDI: control[26:23] <= A_and; //and
                 ORI : control[26:23] <= A_or; //or
                 XORI: control[26:23] <= A_xor; //xor
                 SLTI: control[26:23] <= A_slt;
                 LUI : control[26:23] <= A_lui;
                 default: control[26:23] <= A_addu;
               endcase
               case(op)
                 ANDI: control[11] <= 1'b0;
                 ORI:  control[11] <= 1'b0;
                 XORI: control[11] <= 1'b0;
                 default: control[11] <= 1'b1;
               endcase
             end
     IWB:   begin
               control[17:16] <= 2'b00;
               control[19:18] <= 2'b00;
               control[3] <= 1'b1;
               control[0] <= 1'b0;
           end
     MEMADR:  begin
               control[13:12] <= 2'b10;
               control[15:14] <= 2'b00;
               control[26:23] <= A_addu;
               control[2] <= 1'b0;        
             end
     MEMRD:   begin 
               control[4] <= 1'b1; 
               control[2] <= 1'b0; 
               control[0] <= 1'b0; 
               control[7] <= 1'b0; 
             end
     LCDIRTY: begin control[5] <= 1'b1; end
     LCUPDATE: begin control[5] <= 1'b0; control[7] <= 1'b1; end
     MEMWB:   begin
               control[17:16] <= 2'b01;
               control[19:18] <= 1'b1;
               control[3] <= 1'b1;
               control[0] <= 1'b0;
               control[2] <= 1'b0;
             end
     MEMWR:   begin
                 control[4] <= 1'b1;
                 control[1] <= 1'b1;
                 control[0] <= 1'b0;
                 control[2] <= 1'b0;
                 control[7] <= 1'b0;
             end
     SCUPDATE: begin control[5] <= 1'b0; control[7] <= 1'b1; end
     SCDIRTY:  begin control[5] <= 1'b1; end   
     REGEX:  begin
                case(func)
                 SRL: control[13:12] <= 2'b01;
                 SRA: control[13:12] <= 2'b01;
                 SLL: control[13:12] <= 2'b01;
                 default: control[13:12] <= 2'b10;
                endcase
                control[15:14] <= 2'b00;
                control[0] <= 1'b0;
              control[2] <= 1'b0;
                case(func)
                  ADD : control[26:23] <= A_add; //add
                  ADDU: control[26:23] <= A_addu;
                  SUBU: control[26:23] <= A_subu;
                  SUB : control[26:23] <= A_sub; //sub
                  AND : control[26:23] <= A_and; //and
                  OR  : control[26:23] <= A_or; //or
                  XOR : control[26:23] <= A_xor; //xor
                  NOR : control[26:23] <= A_nor; //nor
                  SLT : control[26:23] <= A_slt; //slt
                  SLTU: control[26:23] <= A_sltu;
                  SLL : control[26:23] <= A_sll; //sll
                  SLLV: control[26:23] <= A_sll; //sll
                  SRLV: control[26:23] <= A_srl;
                  SRAV: control[26:23] <= A_sra;
                  SRL : control[26:23] <= A_srl; //srl
                  SRA : control[26:23] <= A_sra; //sra
                  default: control[26:23] <= A_addu;
                endcase
            end
     REGWB:  begin
                control[17:16] <= 2'b01;
                control[3] <= 1'b1;
                control[19:18] <= 2'b00;
                control[0] <= 1'b0;
            end
     MFC0:   begin
                control[17:16] <= 2'b01;
                control[19:18] <= 2'b10;
                control[3] <= 1'b1;
                control[0] <= 1'b0;
            end
     UNDEFINED: begin
                   control[22:20] <= 2'b11;
                   control[0] <= 1;
                   control[10] <= 1;
                   control[9] <= 1;
                   control[0] <= 1'b0;                
                   control[8] <= 1;
               end
     OVFLOW: begin
                control[22:20] <= 2'b11;
                control[0] <= 1'b1;
                control[10] <= 1'b0;
                control[9] <= 1'b1;
                control[0] <= 1'b0;
                control[8] <= 1'b1;
           end
     default: begin control[26:23] <= A_addu; end
    endcase
end


assign pcwrite  =  control[0];
assign memwrite =  control[1];
assign irwrite  =  control[2];
assign regwrite =  control[3];
assign iord     =  control[4];
assign writeback  =  control[5];
assign branch     =  control[6];
assign update     =  control[7];
assign epcwrite   =  control[8];
assign causewrite =  control[9];
assign intcause   =  control[10];
assign extop      =  control[11];
assign alusrca    =  control[13:12];
assign alusrcb    =  control[15:14];
assign regdest    =  control[17:16];
assign memtoreg   =  control[19:18];
assign pcsrc      =  control[22:20];
assign alucont    =  control[26:23];
assign pcen = control[6] | control[0];


always @(*) 
begin
  case(state)
  FETCH :  begin 
             if(miss && dirty)
                  next_state = FCDIRTY;
             else if(miss)
                next_state = FCUPDATE;
             else 
                next_state = DECODE;
           end         
  FCDIRTY:  next_state = FCUPDATE;
  FCUPDATE: next_state = FETCH;
  LCDIRTY:  next_state = LCUPDATE;
  LCUPDATE: next_state = MEMRD;
  SCDIRTY:  next_state = SCUPDATE;
  SCUPDATE: next_state = MEMWR;
  DECODE:  case(op)
           LW:      next_state = MEMADR;
           SW:      next_state = MEMADR;
           REGOP:   case(func)
                    JALR: next_state = JRALI;
                    JR:  next_state = JRI;
                    ADD : next_state = REGEX; //add
                    ADDU: next_state = REGEX;
                    SUBU: next_state = REGEX;
                    SUB : next_state = REGEX; //sub
                    AND : next_state = REGEX; //and
                    OR  : next_state = REGEX; //or
                    XOR : next_state = REGEX; //xor
                    NOR : next_state = REGEX; //nor
                    SLT : next_state = REGEX; //slt
                    SLTU: next_state = REGEX;
                    SLL : next_state = REGEX; //sl
                    SLLV: next_state = REGEX; //sll
                    SRLV: next_state = REGEX;
                    SRAV: next_state = REGEX;
                    SRL : next_state = REGEX; //srl
                    SRA : next_state = REGEX; //sra
                    default:  next_state = UNDEFINED;
                    endcase
           BEQ:     next_state = BRANCHI;
           BNE:     next_state = BRANCHI;
           BLEZ:    next_state = BRANCHI;
           BGTZ:    next_state = BRANCHI;
           ADDI:    next_state = IEX;
           ORI:     next_state = IEX;
           ANDI:    next_state = IEX;
           XORI:    next_state = IEX;
           LUI:     next_state = IEX;
           SLTI:    next_state = IEX;
           J:       next_state = JUMPI;
           JAL:     next_state = JALI;
           MFC:     next_state = MFC0;
           default: next_state = UNDEFINED; //ERRO 
           endcase
  MEMADR:  case(op)
           LW:      next_state = MEMRD;
           SW:      next_state = MEMWR;
           default: next_state = FETCH; //NEVER HAPPEN
           endcase
  MEMRD:   begin
             if(miss & dirty)
               next_state = LCDIRTY;
             else if (miss)
               next_state = LCUPDATE;
             else 
               next_state = MEMWB;
           end
  MEMWB:   next_state = FETCH;
  MEMWR:   begin
             if(miss & dirty)
               next_state = SCDIRTY;
             else if (miss)
               next_state = SCUPDATE;
             else 
               next_state = FETCH;
           end
  REGEX:   begin
             if(overflow) next_state = OVFLOW;
             else next_state = REGWB;
           end
  REGWB:   next_state = FETCH;
  BRANCHI:  next_state = FETCH;
  IEX:     begin
              if(overflow) next_state = OVFLOW;
              else next_state = IWB;
           end
  IWB:     next_state = FETCH;
  JUMPI:   next_state = FETCH;
  JALI:    next_state = FETCH;
  JRI:     next_state = FETCH;
  JRALI:   next_state = FETCH;
  UNDEFINED: next_state = FETCH;
  MFC0:      next_state = FETCH;
  default:   next_state = FETCH; // nenver happen
  endcase
end
            


endmodule
