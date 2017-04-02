
// 4th stage of pipeline

`include "Sysbus.defs"

module data_memory
# (
	BUS_DATA_WIDTH = 64
)
(
	input [5:0] inWriteRegister,   // which register number to be written
	
	input [BUS_DATA_WIDTH-1:0] addressOrAluData,
	input [BUS_DATA_WIDTH-1:0] writeData,
	input inMemOrReg,        // if memorreg is 0, read data from memory
	input memRead,
	input memWrite,
	
	// other control signals to be defined for branch
	
	output [BUS_DATA_WIDTH-1:0] readData,
	output [5:0] outWriteRegister,
	output [BUS_DATA_WIDTH-1:0] outAluData,
	output outMemOrReg
);

reg [BUS_DATA_WIDTH-1:0] data_mem[2^(BUS_DATA_WIDTH) - 1 :0]; 
reg [BUS_DATA_WIDTH-1:0] aluData;
reg [BUS_DATA_WIDTH-1:0] outReadData;
reg [5:0] writeRegister;

logic _memOrReg;

always @ (posedge clk) begin
	if(memRead && !inMemOrReg) begin
		outReadData <= data_mem[addressOrAluData];
	end else if(memWrite && !inMemOrReg) begin
		data_mem[addressOrAluData] <= writeData;
	end else if(inMemOrReg) begin
		aluData <= addressOrAluData;
	end
	writeRegister <= inWriteRegister;
	_memOrReg <= inMemOrReg;
end


assign readData = outReadData;
assign outAluData = aluData;
assign outWriteRegister = writeRegister;
assign outMemOrReg = _memOrReg;

endmodule


