`include "Sysbus.defs"

module fetcher
#(
  BUS_DATA_WIDTH = 64
)
(
  input  clk,
  input  fetch_en,
  input  [BUS_DATA_WIDTH-1:0] data,
  input  count    // must count the instruction number
);
 
logic memOrData = 0;
 
reg [31:0] memdata[1:0] ;  // 2 * 31 memory
 
always @ (posedge clk)
	// decide which bits you want to send
	if(fetch_en) begin
		if(!memOrData) begin
			ins <= data[31:0];
			memOrData <= 1;
		end else begin
			if(count % 2 == 0) begin
				ins <= memdata[0];  // plan to store it in memory , so next clock pulse not overwrites it
			end else begin
				ins <= memdata[1];
			end
			memOrData <= 0;
		end
	end

// have to use a 2-ary memory otherwise overwrites may happen again:-
// odd numbered data go to 1, even go to 0

always_comb
	if(count % 2 == 0) begin 
		assign memdata[0] = data[63:32];
	end else begin
		assign memdata[1] = data[63:32];
	end

assign outIns = ins;

decoder d(
	.clk(clk),
	.outIns(outIns)
);
    
endmodule