
module hazarddetectionunit
# (
	BUS_DATA_WIDTH = 64
)
(
	input inMemReadEx, 
	input inDestRegisterEx,
	input [31:0] inIns,

	output outStall,
	output outIdWrite,
	output outPCWrite
);

always_comb begin
	if(inMemReadEx && ((inDestRegisterEx == inIns[19:15]) || (inDestRegisterEx == inIns[24:20]))) begin
		//stall pipeline
		outStall = 1;
		outIdWrite = 1;
		outPCWrite = 1;
	end else begin 
		outStall = 0;
		outIdWrite = 0;
		outPCWrite = 0;
	end
end

endmodule