
// define this to be a forwarding unit module -- instantiate in fetcher module, make sure wires are connected properly

`include "sysbus.defs"

module forwarding_unit_exe
# (
	BUS_DATA_WIDTH = 64
)
(
	input inRegisterRsIdEx,  // from id/ex pipeline stage
	input inRegsiterRtIdEx,	 // from id/ex pipeline stage
	
	input inRegisterRdExMem,
	input inRegisterRdMemWb,
	
	input inRegWriteExMem, // from ex/mem pipeline stage
	input inRegWriteMemWb,	// from mem/wb pipeline stage
	
	output [1:0] outforwardA, 	// these are outputs to two multiplexers that decide whether A/B is to be fwded 
	output [1:0] outforwardB
);

always_comb begin
	// ex/mem hazard
	if(inRegWriteExMem && (inRegisterRdExMem != 0) && (inRegisterRdExMem == inRegisterRsIdEx)) begin
		outForwardA = 10;
	end
	else if(inRegWriteExMem && (inRegisterRdExMem != 0) && (inRegisterRdExMem == inRegisterRtIdEx)) begin
		outForwardB = 10;
	end
	// mem/wb hazard
	else if(inRegWriteRdMemWb && (inRegisterRdMemWb != 0) && (inRegisterRdMemWb == inRegisterRsIdEx) ) begin
		outForwardA = 01;
	end
	else if(inRegWriteRdMemWb && (inRegisterRdMemWb != 0) && (inRegisterRdMemWb == inRegisterRtIdEx) ) begin
		outForwardB = 01;
	end
	// multiple hazards (multiple adds writing to same operand)
	else if(inRegWriteRdMemWb && (inRegisterRdMemWb != 0) && (inRegisterRdExMem != inRegisterRsIdEx) && (inRegisterRdMemWb == inRegisterRsIdEx)) begin
		outForwardA = 01;
	end
	else if(inRegWriteRdMemWb && (inRegisterRdMemWb != 0) && (inRegisterRdExMem != inRegisterRtIdEx) && (inRegisterRdMemWb == inRegisterRtIdEx)) begin
		outForwardB = 01;
	end
	else begin
		outForwardA = 00;
		outForwardB = 00;
	end
end

endmodule


