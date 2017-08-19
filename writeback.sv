module writeback 
#(
	BUS_DATA_WIDTH = 64
)
(
	input inMemOrReg,
	input [BUS_DATA_WIDTH-1 : 0] inReadData,     
	input [BUS_DATA_WIDTH-1 : 0] inResult, 
	input inDoPendingWrite,
	input [63:0] inDataPendingWrite,
	input [63:0] inAddressPendingWrite,    
	input [4:0] inDestRegister,
	input inRegWrite,
	input clk,
	input inEcall,
	// ecall registers

	input [63:0] inMem10,
	input [63:0] inMem11,
	input [63:0] inMem12,
	input [63:0] inMem13,
	input [63:0] inMem14,
	input [63:0] inMem15,
	input [63:0] inMem16,
	input [63:0] inMem17,
	input [63:0] inEpc,
	input [63:0] inPc,
	input inJump,
	input [63 : 0] in_data_for_pending_write,
	input [3 : 0] inSizePendingWrite,

	input in_stall_from_icache,
	input in_stall_from_dcache,
	output [BUS_DATA_WIDTH-1:0] outRegData,
	output [4:0] outDestRegister,
	output outRegWrite,
	output outFlush,
	output [63:0] outEpc,

	output [63:0] outRegDataFromEcall,
	output outRegWriteFromEcall,
	output [63:0] outDestRegisterFromEcall                            
);

`include "Sysbus.defs"

enum {
	STATE_DO_ECALL,
	STATE_WAIT
} state;

logic flush = 0;

always_comb begin
	if(!in_stall_from_icache && !in_stall_from_dcache) begin
		if(inEcall) begin
			flush = 1;
			outEpc = inEpc;
		end else begin
			flush = 0;
			outEpc = inEpc;  // don't care
		end
	end
end

assign outFlush = flush;

always_comb begin
	if(!in_stall_from_icache && !in_stall_from_dcache) begin
		if(!inEcall) begin
			outDestRegister = inDestRegister;
			outRegWrite = inRegWrite;
			if(inJump) begin
				if(inDestRegister == 0)
					outRegData = 0;
				else 
					outRegData = inPc + 4;
			end else begin
				if(!inMemOrReg) begin
					outRegData = inResult;
				end else begin
					outRegData = inReadData;
				end
			end
		end  
	end
end

always_ff @ (posedge clk) begin
	if(!in_stall_from_icache && !in_stall_from_dcache) begin
		if(inDoPendingWrite) begin
			// do_pending_write(address, value, size in bytes); 
			if(inSizePendingWrite == 4'b0001)
				do_pending_write(inAddressPendingWrite, in_data_for_pending_write, 1);
			else if(inSizePendingWrite == 4'b0010)
				do_pending_write(inAddressPendingWrite, in_data_for_pending_write, 2);
			else if(inSizePendingWrite == 4'b0100)
				do_pending_write(inAddressPendingWrite, in_data_for_pending_write, 4);
			else
				do_pending_write(inAddressPendingWrite, in_data_for_pending_write, 8);
		end
	end	
end

logic [63:0] returnEcallValue;

always_ff @ (posedge clk) begin
	if(!in_stall_from_icache && !in_stall_from_dcache) begin
		if(inEcall && state == STATE_DO_ECALL) begin
			// do_ecall(a7, a0, a1, a2, a3, a4, a5, a6, a0);
			do_ecall(inMem17, inMem10, inMem11, inMem12, inMem13, inMem14, inMem15, inMem16, returnEcallValue);
			state <= STATE_WAIT;
			//$display("ecall 0x%x is being called here", inMem17);
		end
	end
end

always_comb begin
	if(!in_stall_from_icache && !in_stall_from_dcache) begin
		if(state == STATE_WAIT) begin
			outRegDataFromEcall = returnEcallValue;
			outRegWriteFromEcall = 1;
			outDestRegisterFromEcall = 5'b01010;
		end else begin
			outRegDataFromEcall = 0;
			outRegWriteFromEcall = 0;
			outDestRegisterFromEcall = 0;
		end
	end
end

always_ff @ (posedge clk) begin
	if(!in_stall_from_icache && !in_stall_from_dcache) begin
		if(state == STATE_WAIT) begin
			state <= STATE_DO_ECALL;
		end
	end
end

endmodule