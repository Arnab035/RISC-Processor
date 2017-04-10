
// 5th stage of pipeline -- no clock needed

`include "Sysbus.defs"

module writeback 
# (
	BUS_DATA_WIDTH = 64
)
(
	input inMemOrReg,
	input [BUS_DATA_WIDTH-1 : 0] inReadData,     // read data from memory line
	input [BUS_DATA_WIDTH-1 : 0] inALUData,     // data from ALU computation
	input [4:0] inDestReg,
	input inRegWrite,
	
	output [BUS_DATA_WIDTH-1:0] outMemOrRegData,
	output [4:0] outDestReg,
	output outRegWrite                              // these 2 signals (the one above) must connect to the decoder module
)

always_comb begin
	if(inMemOrReg) begin
		outMemOrRegData = inALUData;
	end else begin
		outMemOrRegData = inReadData;
	end
	outDestReg = inDestReg;         
	outRegWrite = regWrite;
end

