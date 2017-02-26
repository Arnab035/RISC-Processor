`include "Sysbus.defs"

module fetcher
#(
  BUS_DATA_WIDTH = 64
)
(
  input  clk,
  input  fetch_en,
  input  [BUS_DATA_WIDTH-1:0] data,
  input count 
);
 
reg [63:0] memdata[15:0] ;  // 16 * 32 memory stores instructions

logic access = 1;
reg [31:0] ins, outIns;
 
always_comb begin
	if(count) begin
		memdata[2*count - 2] = data[31:0];
		memdata[2*count - 1] = data[63:32];
	end
end
	
always @ (posedge clk)
	if(fetch_en) begin
		if(access) begin
			ins <= memdata[2* count - 2];
			access <= 0;
		end else begin
			ins <= memdata[2 * count - 1]; 
			access <= 1;
		end
	end
	
assign outIns = ins;

decode d (
	.clk(clk)
	.outIns(outIns)
);

endmodule

