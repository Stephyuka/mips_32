module CacheF(
  input clk,
  input reset,
  input en,
  input wen,
  input stall,
  input [31:0] add,
  input [31:0] data,
  input [63:0] updatedata,
  output [31:0] rdata,
  output [63:0] wdata,
  output [5:0] wadd,
  output wbk,
  output stallC);

reg [1:0] state;
reg [1:0] next_state;

parameter  read      = 2'b00,
           writeback  = 2'b01,
           updatew    = 2'b10,
           stop       = 2'b11;

wire miss, dirty;
reg update, writebk;
wire upd;


initial begin state <= read; end

always @(posedge clk or posedge reset) 
begin
  if(reset) 
      state <= stop;
  else if(~stall)
      state <= next_state;    
end


// always @(*) 
// begin
//  case(state)
//  read:      begin
//               if(miss & !dirty) next_state = updatew;
//              else if(miss & dirty) next_state = writeback;
//               else if(!miss & en) next_state = read;
//               else next_state = stop;
//                end 
//    writeback: next_state = updatew;
//    updatew:   begin
//                if(en) next_state = read;
//                else next_state = stop;
//              end
//    stop:    begin
//             if(en) next_state = read;
//             else next_state = stop;
//            end
//   endcase
// end


always @(*) 
begin
  case(state)
  read:      begin
             if(en & miss & !dirty) next_state = updatew;
             else if(en & miss & dirty) next_state = writeback;
             else next_state = read;
               end 
   writeback: next_state = updatew;
   updatew:   next_state = read;
   default:   next_state = read; // never happen
  endcase
end


always @(*) 
begin
  case(state)
  read:      begin update = 0; writebk = 0; end
  writeback: begin update = 0; writebk = 1; end
  updatew:    begin update = 1; writebk = 0; end
  default:      begin update = 0; writebk = 0; end
  endcase
end

assign stallC = ((next_state == writeback) | (next_state == updatew))& ~stall;
assign upd = update;
assign wbk = writebk;

cache cache(clk, reset, add, data, updatedata, wen, 1, upd,
            rdata, miss, dirty, wdata, wadd);



//no matter is dirty or miss 
//the circle dumped limits to one
// miss : 

endmodule


module CacheM(
  input clk,
  input reset,
  input stall,
  input en,
  input cen,
  input wen,
  input [31:0] add,
  input [31:0] data,
  input [63:0] updatedata,
  output [31:0] rdata,
  output [63:0] wdata,
  output [5:0] wadd,
  output wbk,
  output stallc);

reg [1:0] state;
reg [1:0] next_state;

parameter  read      = 2'b00,
           writeback  = 2'b01,
           updatew    = 2'b10,
           stop       = 2'b11;

wire miss, dirty;
reg update, writebk;
wire upd;


initial begin state <= read; end
always @(posedge clk or posedge reset) 
begin
  if(reset) 
      state <= stop;
  else if(~stall)
      state <= next_state;    
end


always @(*) 
begin
  case(state)
  read:      begin
             if(en & miss & !dirty) next_state = updatew;
             else if(en & miss & dirty) next_state = writeback;
             else next_state = read;
               end 
   writeback: next_state = updatew;
   updatew:   next_state = read;
   default:   next_state = read; // never happen
  endcase
end


always @(*) 
begin
  case(state)
  read:      begin update = 0; writebk = 0; end
  writeback: begin update = 0; writebk = 1; end
  updatew:   begin update = 1; writebk = 0; end
  default:   begin update = 0; writebk = 0; end // never happen
  endcase
end

assign stallc = (next_state == writeback) | (next_state == updatew) ;
assign wbk = writebk;


assign upd = update;

cache cache(clk, reset, add, data, updatedata, wen, cen, upd,
            rdata, miss, dirty, wdata, wadd);


//no matter is dirty or miss 
//the circle dumped limits to one
// miss : 

endmodule






module cache(
  input clk, //clock
  input reset,
  input [31:0] add, // the address u want to link to
  input [31:0] wdata, //the data you want to write
  input [63:0] updated, // the update data
  input WE, //write enable
  input en,
  input update,
  output [31:0] rdata, // data read
  output ifmiss, // if hit
  output ifdirty, // if dirty
  output [63:0] writeback, // the data to writeback
  output [5:0] wadd); // the adress to write back


  wire [6:0] addr;
  reg [7:0] tag[0:3];

  reg [63:0] listA[0:3];
  reg [63:0] listB[0:3];

  reg [1:0]v [0:3];
  reg [1:0]d [0:3]; 
  reg [1:0]s [0:3];

  reg [5:0] wbadd;
  reg [63:0] wbdata;
  reg [31:0] data;

  reg miss;
  reg dirty;
 

  initial 
  begin
     tag[0] <= 8'b0; tag[1] <= 8'b0; tag[2] <= 8'b0; tag[3] <= 8'b0;
     listA[0] <= 64'b0; listA[1] <= 64'b0; listA[2] <= 64'b0; listA[3] <= 64'b0;
     listB[0] <= 64'b0; listB[1] <= 64'b0; listB[2] <= 64'b0; listB[3] <= 64'b0;
     v[0] <= 2'b0; v[1] <= 2'b0; v[2] <= 2'b0; v[3] <= 2'b0;
     d[0] <= 2'b0; d[1] <= 2'b0; d[2] <= 2'b0; d[3] <= 2'b0;
     s[0] <= 2'b0; s[1] <= 2'b01; s[2] <= 2'b0; s[3] <= 2'b0;
     wbadd <= 6'b0; wbdata <= 64'b0; data <= 32'b0;
     miss <= 1'b0; dirty <= 1'b0;
  end
  
  always @(*) 
  begin
    miss = 1'b0; dirty = 1'b0;
    wbadd = 6'b0; wbdata = 64'b0;
    case(add[2:1])
    2'b00:
      begin
        if(update | ((add[6:3] == tag[0][3:0]) & v[0][0]) | ((add[6:3] == tag[0][7:4]) & v[0][1])) 
          begin 
            miss = 0; 
            dirty = 0; 
          end
        else
          begin
            miss = 1'b1;
            if(~s[0][0]) begin dirty = d[0][0]; wbadd = {tag[0][3:0], 2'b00}; wbdata = listA[0]; end
            else         begin dirty = d[0][1]; wbadd = {tag[0][7:4], 2'b00}; wbdata = listB[0]; end
          end
      end
    2'b01:
      begin
        if(update | ((add[6:3] == tag[1][3:0]) & v[1][0]) | ((add[6:3] == tag[1][7:4]) & v[1][1])) 
          begin 
            miss = 0; 
            dirty = 0; 
          end
        else
          begin
            miss = 1;
            if(~s[1][0]) begin dirty = d[1][0]; wbadd = {tag[1][3:0], 2'b01}; wbdata = listA[1]; end
            else         begin dirty = d[1][1]; wbadd = {tag[1][7:4], 2'b01}; wbdata = listB[1]; end
          end
      end    
    2'b10:
      begin
        if(update | ((add[6:3] == tag[2][3:0]) & v[2][0]) | ((add[6:3] == tag[2][7:4]) & v[2][1]))
          begin 
            miss = 0; 
            dirty = 0; 
          end
        else
          begin
            miss = 1;
            if(~s[2][0]) begin dirty = d[2][0]; wbadd = {tag[2][3:0], 2'b10}; wbdata = listA[2]; end
            else         begin dirty = d[2][1]; wbadd = {tag[2][7:4], 2'b10}; wbdata = listB[2]; end
             end
          end 
    2'b11:
      begin
        if(update | ((add[6:3] == tag[3][3:0]) & v[3][0]) | ((add[6:3] == tag[3][7:4]) & v[3][1]))
          begin 
            miss = 0; 
            dirty = 0; 
          end
        else
          begin
            miss = 1;
            if(~s[3][0]) begin dirty = d[3][0]; wbadd = {tag[3][3:0], 2'b11}; wbdata = listA[3]; end
            else         begin dirty = d[3][1]; wbadd = {tag[3][7:4], 2'b11}; wbdata = listB[3]; end
          end
      end
    endcase
  end


  always @(posedge clk or posedge reset) 
    begin
     if(reset)
       begin
         tag[0] <= 8'b0; tag[1] <= 8'b0; tag[2] <= 8'b0; tag[3] <= 8'b0;
         listA[0] <= 64'b0; listA[1] <= 64'b0; listA[2] <= 64'b0; listA[3] <= 64'b0;
         listB[0] <= 64'b0; listB[1] <= 64'b0; listB[2] <= 64'b0; listB[3] <= 64'b0;
         v[0] <= 2'b0; v[1] <= 2'b0; v[2] <= 2'b0; v[3] <= 2'b0;
         d[0] <= 2'b0; d[1] <= 2'b0; d[2] <= 2'b0; d[3] <= 2'b0;
         s[0] <= 2'b0; s[1] <= 2'b0; s[2] <= 2'b0; s[3] <= 2'b0;
       end

     else if(update)
        case(add[2:1])
        2'b00:
          begin
            if(~s[0][0]) begin tag[0][3:0] <= add[6:3];  v[0][0] <= 1; s[0][0] <= 1; s[0][1] <= 0;
                         if(WE) begin if(~add[0]) begin listA[0][31:0]  <= wdata; listA[0][63:32] <= updated[63:32]; d[0][0] <= 1; end
                                      else        begin listA[0][63:32] <= wdata; listA[0][31:0]  <= updated[31:0];  d[0][0] <= 1; end end  
                         else   begin listA[0] <= updated; d[0][0] <= 0; end end
            else         begin tag[0][7:4] <= add[6:3];  v[0][1] <= 1; s[0][1] <= 1; s[0][0] <= 0;
                         if(WE) begin if(~add[0]) begin listB[0][31:0]  <= wdata; listB[0][63:32] <= updated[63:32]; d[0][1] <= 1; end
                                      else        begin listB[0][63:32] <= wdata; listB[0][31:0]  <= updated[31:0];  d[0][1] <= 1; end end  
                         else   begin listB[0] <= updated; d[0][1] <= 0; end end
          end
        2'b01:
          begin
            if(~s[1][0]) begin tag[1][3:0] <= add[6:3];  v[1][0] <= 1; s[1][0] <= 1; s[1][1] <= 0;
                         if(WE) begin if(~add[0]) begin listA[1][31:0]  <= wdata; listA[1][63:32] <= updated[63:32]; d[1][0] <= 1; end
                                      else        begin listA[1][63:32] <= wdata; listA[1][31:0]  <= updated[31:0];  d[1][0] <= 1; end end  
                         else   begin listA[1] <= updated; d[1][0] <= 0; end end
            else         begin tag[1][7:4] <= add[6:3];  v[1][1] <= 1; s[1][1] <= 1; s[1][0] <= 0;
                         if(WE) begin if(~add[0]) begin listB[1][31:0]  <= wdata; listB[1][63:32] <= updated[63:32]; d[1][1] <= 1; end
                                      else        begin listB[1][63:32] <= wdata; listB[1][31:0]  <= updated[31:0];  d[1][1] <= 1; end end  
                         else   begin listB[1] <= updated; d[1][1] <= 0; end end
          end
        2'b10:
          begin
            if(~s[2][0]) begin tag[2][3:0] <= add[6:3];  v[2][0] <= 1; s[2][0] <= 1; s[2][1] <= 0;
                         if(WE) begin if(~add[0]) begin listA[2][31:0]  <= wdata; listA[2][63:32] <= updated[63:32]; d[2][0] <= 1; end
                                      else        begin listA[2][63:32] <= wdata; listA[2][31:0]  <= updated[31:0];  d[2][0] <= 1; end end  
                         else   begin listA[2] <= updated; d[2][0] <= 0; end end
            else         begin tag[2][7:4] <= add[6:3];  v[2][1] <= 1; s[2][1] <= 1; s[2][0] <= 0;
                         if(WE) begin if(~add[0]) begin listB[2][31:0]  <= wdata; listB[2][63:32] <= updated[63:32]; d[2][1] <= 1; end
                                      else        begin listB[2][63:32] <= wdata; listB[2][31:0]  <= updated[31:0];  d[2][1] <= 1; end end  
                         else   begin listB[2] <= updated; d[2][1] <= 0; end end
          end
        2'b11:
          begin
            if(~s[3][0]) begin tag[3][3:0] <= add[6:3];  v[3][0] <= 1; s[3][0] <= 1; s[3][1] <= 0;
                         if(WE) begin if(~add[0]) begin listA[3][31:0]  <= wdata; listA[3][63:32] <= updated[63:32]; d[3][0] <= 1; end
                                      else        begin listA[3][63:32] <= wdata; listA[3][31:0]  <= updated[31:0];  d[3][0] <= 1; end end  
                         else   begin listA[3] <= updated; d[3][0] <= 0; end end
            else         begin tag[3][7:4] <= add[6:3];  v[3][1] <= 1; s[3][1] <= 1; s[3][0] <= 0;
                         if(WE) begin if(~add[0]) begin listB[3][31:0]  <= wdata; listB[3][63:32] <= updated[63:32]; d[3][1] <= 1; end
                                      else        begin listB[3][63:32] <= wdata; listB[3][31:0]  <= updated[31:0];  d[3][1] <= 1; end end  
                         else   begin listB[3] <= updated; d[3][1] <= 0; end end
          end
        endcase

    else if(WE)
      case(add[2:1])
      2'b00:
        begin 
          if((add[6:3] == tag[0][3:0]) & v[0][0])
            begin
              if(~add[0]) listA[0][31:0]  <= wdata; 
              else        listA[0][63:32] <= wdata;
              d[0][0] <= 1; s[0][0] <= 1; s[0][1] <= 0;  
            end
          else if((add[6:3] == tag[0][7:4]) & v[0][1]) 
             begin 
               if(~add[0]) listB[0][31:0]  <= wdata; 
               else        listB[0][63:32] <= wdata;
               d[0][1] <= 1; s[0][0] <= 0; s[0][1] <= 1; 
             end
        end
      2'b01:
        begin 
          if(add[6:3] == tag[1][3:0] & v[1][0])      
            begin 
              if(add[0]) listA[1][31:0]  <= wdata; 
              else        listA[1][63:32] <= wdata;
              d[1][0] <= 1; s[1][0] <= 1; s[1][1] <= 0;
            end
          else if((add[6:3] == tag[1][7:4]) & v[1][1]) 
            begin 
               if(~add[0]) listB[1][31:0]  <= wdata; 
               else        listB[1][63:32] <= wdata;
               d[1][1] <= 1; s[1][0] <= 0; s[1][1] <= 1;
            end
        end
      2'b10:
        begin 
          if((add[6:3] == tag[2][3:0]) & v[2][0])      
            begin 
              if(add[0]) listA[2][31:0]  <= wdata; 
              else        listA[2][63:32] <= wdata;
              d[2][0] <= 1; s[2][0] <= 1; s[2][1] <= 0; 
            end
          else if((add[6:3] == tag[2][7:4]) & v[2][1]) 
            begin 
               if(~add[0]) listB[2][31:0]  <= wdata; 
               else        listB[2][63:32] <= wdata;
               d[2][1] <= 1; s[2][0] <= 0; s[2][1] <= 1; 
            end
        end
      2'b11:
        begin 
          if((add[6:3] == tag[3][3:0]) & v[3][0])      
            begin 
              if(add[0]) listA[3][31:0]  <= wdata; 
              else        listA[3][63:32] <= wdata;
              d[3][0] <= 1; s[3][0] <= 1; s[3][1] <= 0; 
            end
          else if((add[6:3] == tag[3][7:4]) & v[3][1]) 
            begin
              if(add[0]) listB[3][31:0]  <= wdata; 
              else        listB[3][63:32] <= wdata;
              d[3][1] <= 1; s[3][0] <= 0; s[3][1] <= 1;
            end
        end 
      endcase

    else if (en)
      case(add[2:1])
      2'b00:
        begin 
          if(add[6:3] == tag[0][3:0] & v[0][0])      begin s[0][0] <= 1; s[0][1] <= 0;  end
          else if(add[6:3] == tag[0][7:4] & v[0][1]) begin s[0][0] <= 0; s[0][1] <= 1;  end
        end
      2'b01:
        begin 
          if(add[6:3] == tag[1][3:0] & v[1][0])      begin s[1][0] <= 1; s[1][1] <= 0; end
          else if(add[6:3] == tag[1][7:4] & v[1][1]) begin s[1][0] <= 0; s[1][1] <= 1; end
        end
      2'b10:
        begin 
          if(add[6:3] == tag[2][3:0] & v[2][0])      begin s[2][0] <= 1; s[2][1] <= 0; end
          else if(add[6:3] == tag[2][7:4] & v[2][1]) begin s[2][0] <= 0; s[2][1] <= 1; end
        end
      2'b11:
        begin 
          if(add[6:3] == tag[3][3:0] & v[3][0])      begin s[3][0] <= 1; s[3][1] <= 0; end
          else if(add[6:3] == tag[3][7:4] & v[3][1]) begin s[3][0] <= 0; s[3][1] <= 1; end
        end
      endcase
    end


always @(*) 
begin
  if (update) 
    case(add[0])
    1'b0: data = updated[31:0];
    1'b1: data = updated[63:32];
    endcase
  else
    case(add[2:1])
    2'b00:
      begin
        if(add[6:3] == tag[0][3:0] & v[0][0]) begin data = add[0] == 0 ? listA[0][31:0] : listA[0][63:32]; end
        else                        begin data = add[0] == 0 ? listB[0][31:0] : listB[0][63:32]; end
      end
    2'b01:
      begin
        if(add[6:3] == tag[1][3:0] & v[1][0]) begin data = add[0] == 0 ? listA[1][31:0] : listA[1][63:32]; end
        else                        begin data = add[0] == 0 ? listB[1][31:0] : listB[1][63:32]; end
      end
    2'b10:
      begin
        if(add[6:3] == tag[2][3:0] & v[2][0]) begin data = add[0] == 0 ? listA[2][31:0] : listA[2][63:32]; end
        else                        begin data = add[0] == 0 ? listB[2][31:0] : listB[2][63:32]; end
      end   
    2'b11:
      begin
        if(add[6:3] == tag[3][3:0] & v[3][0]) begin data = add[0] == 0 ? listA[3][31:0] : listA[3][63:32]; end
        else                        begin data = add[0] == 0 ? listB[3][31:0] : listB[3][63:32]; end
      end
    endcase
end

  assign wadd = wbadd;
  assign writeback = wbdata;
  assign rdata = data;
  assign ifmiss = miss;
  assign ifdirty = dirty;

  endmodule
