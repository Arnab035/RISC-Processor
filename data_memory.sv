// 4th stage of pipeline

`include "Sysbus.defs"

module data_memory
# (
	BUS_DATA_WIDTH = 64
)
(
	input clk,
	input inRegWrite,				// control to write data into reg file
	input [4:0] inDestReg,   		// which register number to be written
	
	input [BUS_DATA_WIDTH-1:0] inResult,    // this is from the ALU
	input [BUS_DATA_WIDTH-1:0] writeData,    // this is for store instructions-not handled yet
	input inMemOrReg,        				// if memorreg is 0, read data from memory
	input inMemRead,            			// depends on the instruction
	input inMemWrite,
	
	// other control signals to be defined for branch
	input inBranch,
	input inZero,  							// this comes from the ALU, it is set when the alu subtract operation is 0.
	input [BUS_DATA_WIDTH-1 : 0] inBta,   	// this comes from the adder for bta
	
	output [BUS_DATA_WIDTH-1:0] readData,
	output [4:0] outDestReg,
	output [BUS_DATA_WIDTH-1:0] outResult,
	output outMemOrReg,
	output outRegWrite,
	output outPcSrc,   // indicates the source of the next program counter
	output [BUS_DATA_WIDTH-1 : 0] outBta
);

reg [BUS_DATA_WIDTH-1:0] data_mem[1023:0]; 	// default data memory 
reg [BUS_DATA_WIDTH-1:0] aluData;
reg [BUS_DATA_WIDTH-1:0] outReadData;
reg [4:0] destReg;

logic memOrReg, regWrite;

always @ (posedge clk) begin
	if(memRead && !inMemOrReg) begin
		readData <= data_mem[inResult];
	end else if(memWrite && !inMemOrReg) begin
		data_mem[inResult] <= writeData;
	end else if(inMemOrReg) begin
		aluData <= inResult;
	end
	writeRegister <= inWriteRegister;
	memOrReg <= inMemOrReg;
	regWrite <= inRegWrite;
end

assign outPcSrc = inBranch & inZero;

always_comb 
	if(inBranch && inZero) begin
		outPCSrc = 1;
	end
	
assign outBta = inBta;   // this along with outPCSrc will connect to IF stage pc..

assign outReadData = readData;
assign outAluData = aluData;
assign outDestReg = destReg;
assign outMemOrReg = memOrReg;
assign outRegWrite = regWrite;

endmodule
