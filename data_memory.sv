
`include "Sysbus.defs"

module data_memory(
	input [63:0] address,
	input [63:0] writeData,
	input memRead,
	input memWrite,
	
	output [63:0] readData
);

reg [63:0] data_mem[2^64:0]; 

reg [63:0] outReadData;

always @ (posedge clk) begin
	if(memRead) begin
		outReadData <= data_mem[address];
	end else if(memWrite) begin
		data_mem[address] <= writeData;
	end
end

assign readData = outReadData;

endmodule


