`include "Sysbus.defs"

module writeback 
# (
	BUS_DATA_WIDTH = 64
)
(
	input inMemOrReg,
	input [BUS_DATA_WIDTH-1 : 0] inReadData,     
	input [BUS_DATA_WIDTH-1 : 0] inResult, 
	input [BUS_DATA_WIDTH-1 : 0] inDataReg2,    
	input [4:0] inDestRegister,
	input inRegWrite,
	input inMemWrite,
	input  [BUS_DATA_WIDTH-1:0] inDataReg2,
	output [BUS_DATA_WIDTH-1:0] outRegData,
	output [4:0] outDestRegister,
	output outRegWrite                              
);

always_comb begin
	if(inMemOrReg) begin
		outRegData = inResult;
	end else begin
		outRegData = inReadData;
	end
end

always_ff @ (posedge clk) begin
	if(inMemWrite) begin
		// do_pending_write(address, value, size); - store no interaction with bus
		do_pending_write(inResult, inDataReg2, 8);
	end	
end

assign outDestRegister = inDestRegister;         
assign outRegWrite = inRegWrite;

endmodule