`include "Sysbus.defs"

module writeback
# (
	BUS_DATA_WIDTH = 64
)
(
	input clk,
	input end_of_cycle,
	input fetch_en,
	input [BUS_DATA_WIDTH - 1 : 0] dataOut,
	input _aluOps,
	
	output [BUS_DATA_WIDTH - 1 : 0] y,
	output out_write_en,
	output call_for_print
);

logic write_en, send_call_for_print;

reg [BUS_DATA_WIDTH-1 : 0] regY;

always @ (posedge clk)
  if(!end_of_cycle) begin
	if(fetch_en) begin
		if(_aluOps) begin
			write_en <= 1;
			regY <= dataOut;
		end
		else begin
			write_en <= 0;
		end
	end
  end
  else begin
	send_call_for_print <= 1;
  end

assign out_write_en = write_en;
assign y = regY;
assign call_for_print = send_call_for_print;


endmodule
	

