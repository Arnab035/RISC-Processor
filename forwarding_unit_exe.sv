
// define this to be a forwarding unit module -- instantiate in fetcher module, make sure wires are connected properly

`include "sysbus.defs"

module forwarding_unit_exe
# (
	BUS_DATA_WIDTH = 64
)
(
	input inRegisterRsId,  // from id/ex pipeline stage
	input inRegsiterRtId,	 // from id/ex pipeline stage
	
	input inRegisterRdEx,
	input inRegisterRdMem,
	
	input inRegWriteEx, // from ex/mem pipeline stage
	input inRegWriteMem,	// from mem/wb pipeline stage
	
	output [1:0] outforwardA, 	// these are outputs to two multiplexers that decide whether A/B is to be fwded 
	output [1:0] outforwardB
);

always_comb begin
	// ex/mem hazard
	if(inRegWriteEx && (inRegisterRdEx != 0) && (inRegisterRdEx == inRegisterRsId)) begin
		outForwardA = 10;
	end
	else if(inRegWriteEx && (inRegisterRdEx != 0) && (inRegisterRdEx == inRegisterRtId)) begin
		outForwardB = 10;
	end
	// mem/wb hazard
	else if(inRegWriteRdMem && (inRegisterRdMem != 0) && (inRegisterRdMem == inRegisterRsId) ) begin
		outForwardA = 01;
	end
	else if(inRegWriteRdMem && (inRegisterRdMem != 0) && (inRegisterRdMem == inRegisterRtId) ) begin
		outForwardB = 01;
	end
	// multiple hazards (multiple adds writing to same operand)
	else if(inRegWriteRdMem && (inRegisterRdMem != 0) && (inRegisterRdEx != inRegisterRsId) && (inRegisterRdMem == inRegisterRsId)) begin
		outForwardA = 01;
	end
	else if(inRegWriteRdMem && (inRegisterRdMem != 0) && (inRegisterRdEx != inRegisterRtId) && (inRegisterRdMem == inRegisterRtId)) begin
		outForwardB = 01;
	end
	else begin
		outForwardA = 00;
		outForwardB = 00;
	end
end

endmodule


