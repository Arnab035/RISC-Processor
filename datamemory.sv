// 4th stage of pipeline

`include "Sysbus.defs"

module datamemory
# (
	BUS_DATA_WIDTH = 64,
	BUS_TAG_WIDTH = 13
)
(
	input clk,
	input [4:0] inDestRegister,
	input inBranch,
	input inMemRead,
	input inMemWrite,
	input inMemOrReg,
	input inPCSrc,
	input inRegWrite,
	input inZero,
	input [BUS_DATA_WIDTH-1 : 0] inAddrJump,
	input [BUS_DATA_WIDTH-1 : 0] inResult,
	input [BUS_DATA_WIDTH-1 : 0] inDataReg2,

	input [1:0] inStoreType,
	input [2:0] inLoadType,

  	input  bus_respcyc,
  	input  [BUS_DATA_WIDTH-1:0] bus_resp,
  	input  [BUS_TAG_WIDTH-1:0] bus_resptag,
  	output bus_reqcyc,
  	output [BUS_DATA_WIDTH-1:0] bus_req,
  	output [BUS_TAG_WIDTH-1:0] bus_reqtag,
  	output bus_respack,

  	// other outputs
  	output outPCSrc,
  	output [BUS_DATA_WIDTH-1 : 0] outAddrJump,
  	output [BUS_DATA_WIDTH-1 : 0] outReadData,
  	output [BUS_DATA_WIDTH-1 : 0] outResult,
  	output [4 : 0] outDestRegister,
  	output outMemOrReg,
  	output outRegWrite,
  	output outMemWrite,
  	output [BUS_DATA_WIDTH-1 : 0] outDataReg2
);


logic [BUS_DATA_WIDTH-1:0] result;
logic [BUS_DATA_WIDTH-1:0] addrJump, readData, dataReg2;
logic [4:0] destRegister;
logic memWrite;

logic memOrReg, regWrite;

// TODO : handle forwarding logic for stores

always_ff @ (posedge clk) begin
	if(inMemRead) begin
		bus_req <= inResult;
		bus_reqtag[12] <= 1;   // READ
		bus_reqtag[11:8] <= 4'b0011;  // MMIO
		bus_reqcyc <= 1;
	end else if(inMemWrite) begin
		// TODO : send signal to writeback to perform a write in each clock pulse-- for each store
		memWrite <= inMemWrite;
		// TODO : send the value based on store type
		case(inStoreType)
			2'b00:  // sd
				dataReg2 <= inDataReg2; 
			2'b01:  // sw
				dataReg2 <= inDataReg2[31:0];
			2'b10:  // sh
				dataReg2 <= inDataReg2[15:0];
			2'b11:  // sb
				dataReg2 <= inDataReg2[7:0];
		endcase
		result <= inResult;  // result is the address for store
	end else begin
		bus_req <= 0;
		bus_reqtag <= 0;
		bus_reqcyc <= 0;
		result <= inResult;
		destRegister <= inDestRegister;
		memOrReg <= inMemOrReg;
		regWrite <= inRegWrite;
	end
end


always_ff @ (posedge clk) begin
	if(bus_respcyc) begin
		readData <= bus_resp;
		result <= inResult;
		destRegister <= inDestRegister;
		memOrReg <= inMemOrReg;
		regWrite <= inRegWrite;
	end
end

assign outMemOrReg = memOrReg;
assign outRegWrite = regWrite;
assign outAddrJump = addrJump;
assign outPCSrc = ((inZero & inBranch) == 0) ? 1 : 0 ;
assign outResult = result;
assign outDataReg2 = dataReg2;
assign outMemWrite = memWrite;

always_comb begin
	if(inLoadType == 3'b000) begin
		outReadData = readData;                                     // ld
	end else if(inLoadType == 3'b001) begin
		outReadData = {{56{readData[7]}} ,readData[7:0]};           // lb
	end else if(inLoadType == 3'b010) begin
		outReadData = {{48{readData[15]}} ,readData[15:0]};         // lh
	end else if(inLoadType == 3'b011) begin
		outReadData = {{32{readData[31]}} ,readData[31:0]};         // lw
	end else if(inLoadType == 3'b100) begin
		outReadData = readData[7:0];                       // lbu
	end else if(inLoadType == 3'b101) begin
		outReadData = readData[15:0];                      // lhu
	end else if(inLoadType == 3'b110) begin
		outReadData = readData[31:0];                      // lwu
	end
end

endmodule
