// simple adder module -- this computes the branch target address

module adder
# (
	BUS_DATA_WIDTH = 64
)
(
	input clk,
	input [BUS_DATA_WIDTH-1 : 0] inPc, // this program counter value comes from the id module
	input [BUS_DATA_WIDTH-1 : 0] inImm,  // sign-extended immediate
	
	output [BUS_DATA_WIDTH-1 : 0] outBta;
)

reg [BUS_DATA_WIDTH-1 : 0] bta;

always @ (posedge clk) begin
	bta <= inPc + inImm;
end

assign outBta = bta;

endmodule
	

