module instructionCache
#(
	BUS_TAG_WIDTH = 13,
	BUS_DATA_WIDTH = 64
)
(
	input clk,
	input reset,
	input [511 : 0] inData,
	input [BUS_DATA_WIDTH-1 : 0] pc,
	input [9:0] in_out_offset,
	input inFlushFromEcall,
	input in_stall_from_hazardunit,
	input in_stall_from_invalidation,
	input inFlushFromJump,
	input in_stall_from_dcache,
	output [31 : 0] outInstr,
	output outMiss,
	output outStall,
	output [BUS_DATA_WIDTH-1 : 0] outPc
);

`include "Sysbus.defs"

// direct-mapped cache - 64 kb cache with 64 byte lines
// convert this into a 2-way set-associative cache with LRU replacement

/*    
	general L1 cache design : 2-way set associative cache   ---

		address --   tag (49)  --- index (9) --- offset (6)

	   valid (1) --- tag (49) --- data (512)  -- valid (1) --- tag (49) ---- data(512)  

	   lru -- single bit to help indicate least recently used block, start with 0

	  way selector -- LRU data replacement policy
*/

logic [31:0] instr;

logic [8:0] index_bits;
logic [48:0] tag_bits;
logic [5:0] offset_bits;

logic miss=0, write_complete, /* verilator lint_off UNOPTFLAT */stall;
logic lru = 1, update_lru;
logic [1123:0] icache[511:0];   // 512 sets, instead of 1024


assign index_bits = pc[14 : 6];
assign tag_bits = pc[63 : 15];
assign offset_bits = pc[5 : 0];  // unsigned 4- byte aligned

logic [9:0] cache_line_offset = 8 * offset_bits;
logic [10:0] cache_line_offset_new = 562 + (8 * offset_bits);

enum {
	CACHE_BEGIN = 2'b00,
	CACHE_WAIT = 2'b01
} state;

always_comb begin
	if(!reset) begin
		if(!in_stall_from_dcache && !in_stall_from_hazardunit) begin
			if(state == CACHE_BEGIN) begin
				if(icache[index_bits][560:512] == tag_bits && icache[index_bits][561]) begin
					miss = 0;
					instr = icache[index_bits][cache_line_offset +: 32];
					stall = 0;
				end else if(icache[index_bits][1122:1074] == tag_bits && icache[index_bits][1123]) begin
					miss = 0;
					instr = icache[index_bits][cache_line_offset_new +: 32];
					stall = 0;
				end else begin
					miss = 1;
					stall = 1;
					instr = 0;
				end
			end
		end
	end
end

always_ff @ (posedge clk) begin
	if(!in_stall_from_dcache && !in_stall_from_hazardunit) begin 
		if(miss) begin
			state <= CACHE_WAIT;
		end
	end
end

// writes to cache-stall the pc all this while

always_ff @ (posedge clk) begin
	if(!in_stall_from_dcache && !in_stall_from_hazardunit) begin
		if((in_out_offset == 64*8) && state == CACHE_WAIT) begin
			if(lru == 1) begin
				icache[index_bits][511:0] <= inData;
				icache[index_bits][561] <= 1;  // valid bit
				icache[index_bits][560:512] <= tag_bits; 
				state <= CACHE_BEGIN;
				lru <= 0;
			end else begin
				icache[index_bits][1073:562] <= inData;
				icache[index_bits][1123] <= 1;
				icache[index_bits][1122:1074] <= tag_bits;
				state <= CACHE_BEGIN;
				lru <= 1;
			end 
		end
	end
end

assign outMiss = miss;
assign outStall = stall;

always_ff @ (posedge clk) begin
	if(!reset) begin
		if(!in_stall_from_dcache && !in_stall_from_hazardunit && !stall) begin
			if(!inFlushFromJump && !inFlushFromEcall) begin
				outInstr <= instr;
				outPc <= pc;
				//$display("Instruction being executed is 0x%x at address 0x%x", instr, pc);
			end else begin
				outInstr <= 0;
				outPc <= 0;
			end
		end
	end
end

endmodule