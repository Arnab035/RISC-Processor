
// define this to be a hazard unit module -- it must be defined in the instruction decode stage

module hazard_detection_unit
# (
	BUS_DATA_WIDTH = 64
)
(
	input inMemReadIdEx, // memread signal from id/ex, tells you if it is a load
	
	input inRegisterRtIdEx,
	input inRegisterRsIfId,
	input inRegisterRtIfId,
	
	output outPCWrite,  // signal to tell PC not to increment
	output outIfIdWrite,  // do not write to the if/id register
	output outCtrlMux   // set all control signals to 0
)

always_comb begin
	if(inMemReadIdEx && ((inRegisterRtIdEx == inRegisterRsIfId) || (inRegisterRtIdEx == inRegisterRtIfId))) begin
		//stall pipeline
		outPCWrite = 0;
		outIfIdWrite = 0;
		outCtrlMux = 0;
	end
end
