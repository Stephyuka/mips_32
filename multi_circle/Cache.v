module cache(
	input clk, //clock
	input reset,
	input update, //if to update
	input [31:0] add, // the address u want to link to
	input [31:0] wdata, //the data you want to write
	input [127:0] d, // the update data
	input WE, //write enable
	input [1:0] show_tag,
	input [1:0] show_s,
	output [31:0] show_data,
	output show_dirty,
	output [31:0] data, // data reas
	output miss_i, // if hit
	output dirty_i, // if dirty
	output [127:0] writeback, // the data to writeback
	output [5:0] wadd); // the adress to write back

//the memory can be designed artifically into a 128-byte memory
//

wire [7:0] addr;
reg [31:0] temp;

reg [3:0] tag[0:3];

reg [31:0] list1[0:3],
           list2[0:3],
           list3[0:3],
           list4[0:3];
reg load_flag [0:3];
reg dirty_flag[0:3]; 
reg [5:0] index;
reg miss;
reg dirty;
reg [127:0] outdata;
wire [3:0] t;
wire [1:0] s;

assign t = add[7:4];
assign s = add[3:2];
assign addr = add[7:0];

initial 
  begin
    miss = 1;
    dirty = 0;
    tag[0] = 4'b0;
    tag[1] = 4'b0;
    tag[2] = 4'b0;
    tag[3] = 4'b0;
    load_flag[0] = 0;
    load_flag[1] = 0;
    load_flag[2] = 0;
    load_flag[3] = 0;
    dirty_flag[0] = 0;
    dirty_flag[1] = 0;
    dirty_flag[2] = 0;
    dirty_flag[3] = 0;
    outdata = 128'b0;
    index = 5'b0;
    list1[0] = 32'b0;
    list1[1] = 32'b0;
    list1[2] = 32'b0;
    list1[3] = 32'b0;
    list2[0] = 32'b0;
    list2[1] = 32'b0;
    list2[2] = 32'b0;
    list2[3] = 32'b0;
    list3[0] = 32'b0;
    list3[1] = 32'b0;
    list3[2] = 32'b0;
    list3[3] = 32'b0;
    list4[0] = 32'b0;
    list4[1] = 32'b0;
    list4[2] = 32'b0;
    list4[3] = 32'b0;   
  end
  
always @(posedge clk or posedge reset) 
begin
   if(reset)
      begin
      miss = 1;
      miss = 1;
      dirty = 0;
      tag[0] = 4'b0;
      tag[1] = 4'b0;
      tag[2] = 4'b0;
      tag[3] = 4'b0;
      load_flag[0] = 0;
      load_flag[1] = 0;
      load_flag[2] = 0;
      load_flag[3] = 0;
      dirty_flag[0] = 0;
      dirty_flag[1] = 0;
      dirty_flag[2] = 0;
      dirty_flag[3] = 0;
      outdata = 128'b0;
      index = 5'b0;
      list1[0] = 32'b0;
      list1[1] = 32'b0;
      list1[2] = 32'b0;
      list1[3] = 32'b0;
      list2[0] = 32'b0;
      list2[1] = 32'b0;
      list2[2] = 32'b0;
      list2[3] = 32'b0;
      list3[0] = 32'b0;
      list3[1] = 32'b0;
      list3[2] = 32'b0;
      list3[3] = 32'b0;
      list4[0] = 32'b0;
      list4[1] = 32'b0;
      list4[2] = 32'b0;
      list4[3] = 32'b0;
      end
   else if(update)
     begin
        miss = 0;
        dirty = 0;
     	case(s)
     	2'b00: begin
     	       tag[0] = t;
     	       list1[0] = d[127: 96];
     	       list1[1] = d[95 : 64];
     	       list1[2] = d[63 : 32];
     	       list1[3] = d[31 : 0];
     	       dirty_flag[0] = 0;
     	       load_flag[0] = 1;
     	       end
     	2'b01: begin
     	       tag[1] = t;
     	       list2[0] = d[127: 96];
     	       list2[1] = d[95 : 64];
     	       list2[2] = d[63 : 32];
     	       list2[3] = d[31 : 0];
     	       dirty_flag[1] = 0;
               load_flag[1] = 1;
     	       end
     	2'b10: begin
     	       tag[2] = t;
     	       list3[0] = d[127: 96];
     	       list3[1] = d[95 : 64];
     	       list3[2] = d[63 : 32];
     	       list3[3] = d[31 : 0];
     	       dirty_flag[2] = 0;
               load_flag[2] = 1;
     	       end
     	2'b11: begin
     	       tag[3] = t;
     	       list4[0] = d[127: 96];
     	       list4[1] = d[95 : 64];
     	       list4[2] = d[63 : 32];
     	       list4[3] = d[31 : 0];
     	       dirty_flag[3] = 0;
               load_flag[3] = 1;
     	       end
     	endcase
   case(addr[3:2])
        2'b00: begin
          if(WE)
            begin
             list1[addr[1:0]] = wdata;
     	     dirty_flag[0] = 1;
           	end
          else 
             begin
              case(addr[1:0])
              2'b00: temp = d[127 : 96];
           	  2'b01: temp = d[95 : 64];
           	  2'b10: temp = d[63 : 32];
           	  2'b11: temp = d[31 : 0];
           	 endcase   
           	 end
          end
        2'b01: begin 
          if(WE)
            begin
           	 list2[addr[1:0]] = wdata;
     	     dirty_flag[1] = 1;
           	end
          else 
             begin
              case(addr[1:0])
              2'b00: temp = d[127: 96];
              2'b01: temp = d[95 : 64];
              2'b10: temp = d[63 : 32];
              2'b11: temp = d[31 : 0];
             endcase   
             end
          end
        2'b10: begin 
          if(WE)
           	begin
           	 list3[addr[1:0]] = wdata;
     	     dirty_flag[2] = 1;
           	end
           	else 
             begin
               case(addr[1:0])
                  2'b00: temp = d[127: 96];
                  2'b01: temp = d[95 : 64];
                  2'b10: temp = d[63 : 32];
                  2'b11: temp = d[31 : 0];
                endcase   
              end
          end

        2'b11: begin 
          if(WE)
           	begin
           	 list4[addr[1:0]] = wdata;
     	     dirty_flag[3] = 1;
           	end
           	else 
             begin
               case(addr[1:0])
                  2'b00: temp = d[127: 96];
                  2'b01: temp = d[95 : 64];
                  2'b10: temp = d[63 : 32];
                  2'b11: temp = d[31 : 0];
               endcase   
             end
          end
       endcase
     end

/********************** the state of fetch **************************/

   else 
     begin
   	   case(addr[3:2])
   2'b00: begin 
           if(load_flag[0] == 0)
              begin 
                miss = 1; 
                dirty = 0;
              end
           else if(addr[7:4] == tag[0]) 
             begin
           	  miss = 0; 
           	  if(WE)
           	    begin
           	  	  list1[addr[1:0]] = wdata;
           	  	  dirty_flag[0] = 1;
           	    end
           	  else 
           	    begin
           	  	  temp = list1[addr[1:0]];
           	    end
             end
           else 
             begin
           	  miss = 1; 
           	  dirty = dirty_flag[0];
           	  outdata = {list1[0],list1[1],list1[2],list1[3]};
              index = {tag[0],2'b00};
             end
          end

   2'b01: begin 
           if(load_flag[1] == 0)
             begin 
               miss = 1; 
               dirty = 0;
             end
           else if(addr[7:4] == tag[1]) 
             begin
           	  miss = 0; 
           	  if(WE)
           	    begin
           	  	  list2[addr[1:0]] = wdata;
           	  	  dirty_flag[1] = 1;
           	    end
           	  else 
           	    begin
           	  	  temp = list2[addr[1:0]];
           	    end
             end
           else 
             begin
           	  miss = 1; 
           	  dirty = dirty_flag[1];
           	  outdata = {list2[0],list2[1],list2[2],list2[3]};
              index = {tag[1],2'b01};
             end
          end

   2'b10: begin 
           if(load_flag[2] == 0)
             begin 
               miss = 1; 
               dirty = 0; 
               end
           else if(addr[7:4] == tag[2]) 
             begin
           	  miss = 0; 
           	  if(WE)
           	    begin
           	  	  list3[addr[1:0]] = wdata;
           	  	  dirty_flag[2] = 1;
           	    end
           	  else 
           	    begin
           	  	  temp = list3[addr[1:0]];
           	    end
             end
           else 
             begin
           	  miss = 1; 
           	  dirty = dirty_flag[2];
           	  outdata = {list3[0],list3[1],list3[2],list3[3]};
              index = {tag[2],2'b10};
             end
          end

   2'b11: begin 
           if(load_flag[3] == 0)
             begin 
               miss = 1; 
               dirty = 0; 
             end
           if(addr[7:4] == tag[3]) 
             begin
           	  miss = 0; 
           	  if(WE)
           	    begin
           	  	  list4[addr[1:0]] = wdata;
           	  	  dirty_flag[3] = 1;
           	    end
           	  else 
           	    begin
           	  	  temp = list4[addr[1:0]];
           	    end
             end
           else 
             begin
           	  miss = 1; 
           	  dirty = dirty_flag[3];
           	  outdata = {list4[0],list4[1],list4[2],list4[3]};
              index = {tag[3],2'b11};
             end
          end
    endcase
    end
end

assign data = (s == 2'b00) ? list1[addr[1:0]] : ((s == 2'b01) ? list2[addr[1:0]] :((s == 2'b10) ? list3[addr[1:0]] : list4[addr[1:0]]));
assign miss_i = miss;
assign dirty_i = dirty;
assign wadd = index ;
assign writeback = outdata;
assign show_data = (show_tag == 2'b00) ? list1[show_s] :((show_tag == 2'b01) ? list2[show_s] : ((show_tag == 2'b10) ? list3[show_s] : list4[show_s])) ;
assign show_dirty = (show_tag == 2'b00) ? dirty_flag[0] : ((show_tag == 2'b01) ? dirty_flag[1] : ((show_tag == 2'b10) ? dirty_flag[2] : dirty_flag[3]));

endmodule