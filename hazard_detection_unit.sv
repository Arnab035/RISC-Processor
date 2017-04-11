
// define this to be a hazard unit module -- it must be defined in the instruction decode stage

module hazard_detection_unit
# (
	BUS_DATA_WIDTH = 64
)
(
	input inMemReadId, // memread signal from id/ex, tells you if it is a load
	// since this module will be used inside instruction decoder, you can pass the instruction directly as input
	input inRegisterRt,
	input [31:0] outIns,
	
	output outPCWrite,  // signal to tell PC not to increment
	output outIfIdWrite,  // do not write to the if/id register
	output outCtrlMux   // set all control signals to 0
)

always_comb begin
	if(inMemReadId && ((inRegisterRtEx == outIns[19:15]) || (inRegisterRtEx == outIns[24:20]))) begin
		//stall pipeline
		outPCWrite = 0;
		outIfIdWrite = 0;
		outCtrlMux = 1;
	end
end
