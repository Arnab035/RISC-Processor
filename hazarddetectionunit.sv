module hazarddetectionunit
# (
	BUS_DATA_WIDTH = 64
)
(
	input clk,
	input inMemReadEx, 
	input [4:0] inDestRegisterEx,
	input [31:0] inIns,
	input inFlushFromJump,
	input in_stall_from_icache,
	input in_stall_from_dcache,
	output outStall
);

`include "Sysbus.defs"

enum {
	STATE_READY_TO_STALL = 2'b00,
	STATE_STALL = 2'b01
} state;

logic /* verilator lint_off UNOPTFLAT */stall;

always_comb begin
	if(!in_stall_from_icache && !in_stall_from_dcache) begin
		if(state == STATE_READY_TO_STALL) begin
			if(inFlushFromJump) begin
				stall = 0;
			end else begin
				if(inMemReadEx && ((inDestRegisterEx == inIns[19:15]) || (inDestRegisterEx == inIns[24:20]))) begin
					// stall will become zero after one clock pulse
						stall = 1;
				end else begin
					stall = 0;
				end
			end
		end
	end
end

assign outStall = stall;

always_ff @ (posedge clk) begin
	if(!in_stall_from_icache && !in_stall_from_dcache) begin
		if(stall == 1)
			state <= STATE_STALL;
	end
end

always_comb begin
	if(!in_stall_from_icache && !in_stall_from_dcache) begin
		if(state == STATE_STALL)
			stall = 0;
	end
end

always_ff @ (posedge clk) begin
	if(!in_stall_from_icache && !in_stall_from_dcache) begin
		if(state == STATE_STALL) begin
			state <= STATE_READY_TO_STALL;
		end
	end
end

endmodule