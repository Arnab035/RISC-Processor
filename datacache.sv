module datacache
#(
	BUS_TAG_WIDTH = 13,
	BUS_DATA_WIDTH = 64
)
(
	input clk,
	input [511 : 0] inData,
	input [9:0] in_out_offset,
	input [9:0] in_out_offset_write,
	input inFlushFromEcall,
	input [4:0] inDestRegister,
	input [4:0] inRegisterRt,
	input [4:0] inDestRegisterWb,
	input inBranch,
	input inMemRead,
	input inMemReadWb,
	input [63:0] inReadDataWb,
	input inMemWrite,
	input inMemOrReg,
	input inPCSrc,
	input inRegWrite,
	input inZero,
	input [BUS_DATA_WIDTH-1 : 0] inAddrJump,
	input [BUS_DATA_WIDTH-1 : 0] inResult,      // either an address to load/store or a value to be written to reg file
	input [BUS_DATA_WIDTH-1 : 0] inDataReg2,
	input inJump,
	input [63:0] inEpc,
	input [1:0] inStoreType,
	input [2:0] inLoadType,
	input [511:0] inEcallValue,
	input inEcall,
	input in_do_invalidate,
	input [63 : 0] in_invalid_phys_addr,
	input in_do_invalidate_2,
	input [63 : 0] in_invalid_phys_addr_2,
	input in_stall_from_icache,
	input [63 : 0] inPc,
	output outMiss,
	output outStall,
	output outDoPendingWrite,        // will go to wb
	output [63 : 0] out_data_for_pending_write,
	output [63 : 0] outAddressPendingWrite,
	output [3 : 0] outSizePendingWrite,
	output outFlushJump,
	output [511 : 0] outDataWriteBack,
  	output outPCSrc,
  	output [BUS_DATA_WIDTH-1 : 0] outAddrJump,
  	output [BUS_DATA_WIDTH-1 : 0] outReadData,
  	output [BUS_DATA_WIDTH-1 : 0] outResult,
  	output [4 : 0] outDestRegister,
  	output outMemOrReg,
  	output outMemRead,
  	output outRegWrite,
  	output outMemWrite,
  	output [63 : 0] outAddress,
  	output outEcall,
  	output [63 : 0] outEpc,
  	output outJump,
  	output [63 : 0] outPc
);

`include "Sysbus.defs"

// 2-way set associative cache with LRU

/*    
	general L1 cache design : 2-way set associative cache   ---

		address --   tag (49)  --- index (9) --- offset (6)

                                    1123-1075    1074-563           562          561         560-512         511-0
	    dirty(1) ---  valid (1) --- tag (49) --- data (512) | --- dirty(1) --- valid (1) --- tag (49) ---- data(512)  

	       ----------    block (0)   -----------            |      ------------   block (1)  ------------

	    lru -- single bit to help indicate least recently used block, start with 1

	    way selector -- LRU data replacement policy
*/

logic [63:0] data;

logic [8:0] index_bits;
logic [48:0] tag_bits;
logic [5:0] offset_bits;
logic [63:0] address_for_pending_write;

logic miss, /* verilator lint_off UNOPTFLAT */stall;

logic [1125:0] dcache[511:0];   // 512 sets, instead of 1024
 
always_comb begin
	if(inMemRead || inMemWrite) begin
		index_bits = inResult[14 : 6];
		tag_bits = inResult[63 : 15];
		offset_bits = (inResult[5 : 0]) ; 
	end else begin
		index_bits = 0;
		tag_bits = 0;
		offset_bits = 0;
	end
end 

enum {
	CACHE_BEGIN = 2'b00,
	CACHE_WAIT = 2'b01,
	CACHE_WRITE_BACK = 2'b10,
	CACHE_UPDATE_LINE = 2'b11
} state;


logic lru = 1;
logic do_pending_writes = 0;
logic [9:0] cache_line_offset;
logic [10:0] cache_line_offset_new;
logic [3:0] size_for_pending_write;

always_comb begin
	cache_line_offset = 8 * offset_bits;
	cache_line_offset_new = 563 + (8 * offset_bits);
end

logic memOrReg, regWrite, memRead;
logic [4:0] destRegister;
logic [63:0] result, epc, dataReg2;

logic ecall;
logic flush_jump=0;

logic PCSrc, block_to_write;


assign	outAddrJump = inAddrJump;
assign  PCSrc = (((inZero && inBranch) == 1) || inJump) ? 1 : 0 ;

/* forwarding values ----------------
*****    ld $2,0($3)  
		 sd $2,0($8)  
*/


always_comb begin
	if(!in_stall_from_icache) begin
		if(inDestRegisterWb == inRegisterRt && inMemReadWb) begin
			dataReg2 = inReadDataWb;
		end else begin
			dataReg2 = inDataReg2;
		end
	end
end

always_comb begin
	if(!in_stall_from_icache) begin 
		if(inFlushFromEcall) begin
			flush_jump = 0;
		end else begin
			if(!inMemRead && !inMemWrite) begin
				if(PCSrc) begin
					flush_jump = 1;
				end else begin
					flush_jump = 0;
				end
			end
		end
	end
end

assign outPCSrc = PCSrc;
assign outFlushJump = flush_jump;

logic zero_extension = 0;
logic update_lru;

always_comb begin
	if(!in_stall_from_icache) begin
		if(inFlushFromEcall == 1) begin
			miss = 0;
			stall = 0;
			block_to_write = 0;
			outMemWrite = 0;
		end else begin 
			if((inMemRead || inMemWrite) && state == CACHE_BEGIN) begin
				if((dcache[index_bits][560:512] == tag_bits) && (dcache[index_bits][561] == 1)) begin
				    miss = 0;
					stall = 0;
					update_lru = 0;                 // on a hit, update lru
					if(inMemRead) begin
						if(inLoadType == 3'b000) begin
							data = dcache[index_bits][cache_line_offset +: 64];            // ld
						end else if(inLoadType == 3'b001) begin
							data = {{56{dcache[index_bits][cache_line_offset + 7]}}, dcache[index_bits][cache_line_offset +: 8]};  // lb
						end else if(inLoadType == 3'b010) begin
							data = {{48{dcache[index_bits][cache_line_offset + 15]}}, dcache[index_bits][cache_line_offset +: 16]};  // lh
						end else if(inLoadType == 3'b011) begin
							data = {{32{dcache[index_bits][cache_line_offset + 31]}}, dcache[index_bits][cache_line_offset +: 32]};  // lw
						end else if(inLoadType == 3'b100) begin
							data = {{56{zero_extension}}, dcache[index_bits][cache_line_offset +: 8]};    // lbu
						end else if(inLoadType == 3'b101) begin
							data = {{48{zero_extension}}, dcache[index_bits][cache_line_offset +: 16]};   // lhu
						end else if(inLoadType == 3'b110) begin
							data = {{32{zero_extension}}, dcache[index_bits][cache_line_offset +: 32]};    // lwu
						end
						//$display("Data : 0x%x loaded from address : 0x%x", data, inResult);
					end else begin
						block_to_write = 1;  // writes happen synchronously - at posedge of clock pulse
						data = 0;
					end
				end else if((dcache[index_bits][1123:1075] == tag_bits) && (dcache[index_bits][1124] == 1)) begin
					miss = 0;
					stall = 0;
					update_lru = 1;
					if(inMemRead) begin
						if(inLoadType == 3'b000) begin
							data = dcache[index_bits][cache_line_offset_new +: 64];            // ld
						end else if(inLoadType == 3'b001) begin
							data = {{56{dcache[index_bits][cache_line_offset_new + 7]}}, dcache[index_bits][cache_line_offset_new +: 8]};  // lb
						end else if(inLoadType == 3'b010) begin
							data = {{48{dcache[index_bits][cache_line_offset_new + 15]}}, dcache[index_bits][cache_line_offset_new +: 16]};  // lh
						end else if(inLoadType == 3'b011) begin
							data = {{32{dcache[index_bits][cache_line_offset_new + 31]}}, dcache[index_bits][cache_line_offset_new +: 32]};  // lw
						end else if(inLoadType == 3'b100) begin
							data = {{56{zero_extension}}, dcache[index_bits][cache_line_offset_new +: 8]};    // lbu
						end else if(inLoadType == 3'b101) begin
							data = {{48{zero_extension}}, dcache[index_bits][cache_line_offset_new +: 16]};   // lhu
						end else if(inLoadType == 3'b110) begin
							data = {{32{zero_extension}}, dcache[index_bits][cache_line_offset_new +: 32]};    // lwu
						end
						//$display("Data : 0x%x loaded from address : 0x%x", data, inResult);
					end else begin
		      			block_to_write = 0;
		      			data = 0;
		      		end
				end else begin
					miss = 1;
					stall = 1;
					data = 0;
					if(lru == 1) begin
						if(dcache[index_bits][562] == 1) begin
				      		outMemWrite = 1;
				      		outDataWriteBack = dcache[index_bits][511:0];
				      		outAddress[5:0] = 6'b0;                // addresses are 64-byte aligned
				      		outAddress[63:6] = {dcache[index_bits][560:512], index_bits};
				      		$display("Dirty write to address 0x%x and data 0x%x", outAddress, outDataWriteBack);
				      	end else begin
				      		outMemWrite = 0;
				      		outDataWriteBack = 0;
				      		outAddress = inResult;
				      		$display("About to send address to memory: %x", inResult);
				      	end
					end else begin
						if(dcache[index_bits][1125] == 1) begin    // dirty bit
				    		// $display("about to write back");
				    		outMemWrite = 1;
				      		outDataWriteBack = dcache[index_bits][1074:563];  
				      		outAddress[5:0] = 6'b0;                // addresses are 64-byte aligned
				      		outAddress[63:6] = {dcache[index_bits][1123:1075], index_bits};
				      		//$display("Dirty write to address 0x%x and data 0x%x", outAddress, outDataWriteBack);
				      	end else begin
				      		outMemWrite = 0;
				      		outDataWriteBack = 0;
				      		outAddress = inResult;
				      	end
			      	end
				end
			end
		end
	end
end

/*
always_ff @ (posedge clk) begin
	if(!in_stall_from_icache) begin
		if(inMemRead || inMemWrite) begin
			if(!miss) begin
				if(update_lru == 0) begin
					lru <= 0;
				end else if(update_lru == 1) begin
					lru <= 1;
				end
			end
		end
	end
end
*/

// change state
always_ff @ (posedge clk) begin
	if(!in_stall_from_icache) begin
		if(miss) begin
			if(lru == 1) begin
				if(dcache[index_bits][562] == 1) begin
					state <= CACHE_WRITE_BACK;
				end else begin
					state <= CACHE_WAIT;
				end
			end else begin
				if(dcache[index_bits][1125] == 1) begin
					state <= CACHE_WRITE_BACK;
				end else begin
					state <= CACHE_WAIT;
				end
			end
		end
	end
end

// handle stores
always_ff @ (posedge clk) begin
	if(!in_stall_from_icache) begin
		if(inFlushFromEcall == 1) begin
			do_pending_writes <= 0;
		end else begin 
			if(!miss) begin
				if(inMemRead) begin
					do_pending_writes <= 0;
				end else if(inMemWrite) begin
					do_pending_writes <= 1;
					if(block_to_write == 1) begin
						case(inStoreType)
							2'b00:  // sd
								begin
									dcache[index_bits][cache_line_offset +: 64] <= dataReg2; 
									out_data_for_pending_write <= dataReg2;   // send it for do_pending_write
									address_for_pending_write <= inResult;
									size_for_pending_write <= 4'b1000; // in bytes
									//$display("About to call do-pending-write with args : data : 0x%x, address : 0x%x", dataReg2, inResult);
								end
							2'b01:  // sw
								begin
									dcache[index_bits][cache_line_offset +: 32] <= dataReg2[31:0];
									out_data_for_pending_write <= dataReg2[31:0];
									address_for_pending_write <= inResult;
									size_for_pending_write <= 4'b0100;  // bytes
									//$display("About to call do-pending-write with args : data : 0x%x, address : 0x%x", dataReg2, inResult);
								end
							2'b10:  // sh
								begin
									dcache[index_bits][cache_line_offset +: 16] <= dataReg2[15:0];
									out_data_for_pending_write <= dataReg2[15:0];
									address_for_pending_write <= inResult;
									size_for_pending_write <= 4'b0010;
									//$display("About to call do-pending-write with args : data : 0x%x, address : 0x%x", dataReg2, inResult);
								end
							2'b11:  // sb
								begin
									dcache[index_bits][cache_line_offset +: 8] <= dataReg2[7:0];
									out_data_for_pending_write <= dataReg2[7:0];
									address_for_pending_write <= inResult;
									size_for_pending_write <= 4'b0001;
									//$display("About to call do-pending-write with args : data : 0x%x, address : 0x%x", dataReg2, inResult);
								end
						endcase
						dcache[index_bits][562] <= 1;   // dirty bit
					end else begin
						case(inStoreType)
							2'b00:  // sd
								begin
									dcache[index_bits][cache_line_offset_new +: 64] <= dataReg2;
									out_data_for_pending_write <= dataReg2;
									address_for_pending_write <= inResult;
									size_for_pending_write <= 4'b1000;
									//$display("About to call do-pending-write with args : data : 0x%x, address : 0x%x", dataReg2, inResult);
								end 
							2'b01:  // sw
								begin
									dcache[index_bits][cache_line_offset_new +: 32] <= dataReg2[31:0];
									out_data_for_pending_write <= dataReg2[31:0];
									address_for_pending_write <= inResult;
									size_for_pending_write <= 4'b0100;
									//$display("About to call do-pending-write with args : data : 0x%x, address : 0x%x", dataReg2, inResult);
								end
							2'b10:  // sh
								begin
									dcache[index_bits][cache_line_offset_new +: 16] <= dataReg2[15:0];
									out_data_for_pending_write <= dataReg2[15:0];
									address_for_pending_write <= inResult;
									size_for_pending_write <= 4'b0010;
									//$display("About to call do-pending-write with args : data : 0x%x, address : 0x%x", dataReg2, inResult);
								end
							2'b11:  // sb
								begin
									dcache[index_bits][cache_line_offset_new +: 8] <= dataReg2[7:0];
									out_data_for_pending_write <= dataReg2[7:0];
									address_for_pending_write <= inResult;
									size_for_pending_write <= 4'b0001;
									//$display("About to call do-pending-write with args : data : 0x%x, address : 0x%x", dataReg2, inResult);
								end
						endcase
						dcache[index_bits][1125] <= 1;   // dirty bit
					end
				end else begin
					do_pending_writes <= 0;
				end
			end else begin
				do_pending_writes <= 0;
			end
		end
	end
end

always_comb begin
	if(!in_stall_from_icache) begin
		if(inFlushFromEcall == 1) begin
			outMemWrite = 0;
			outAddress = 0;
		end else begin
			if((in_out_offset_write == 64 * 8) && state == CACHE_WRITE_BACK) begin
				outMemWrite = 0;
				outAddress = inResult;
			end
		end
	end
end

always_ff @ (posedge clk) begin
	if(!in_stall_from_icache) begin
		if((in_out_offset_write == 64 * 8) && state == CACHE_WRITE_BACK) begin  // writeback complete
			state <= CACHE_WAIT;
			if(lru == 1)
				dcache[index_bits][562] <= 0;   // no longer dirty
			else
				dcache[index_bits][1125] <= 0;
		end
	end
end



always_ff @ (posedge clk) begin
	if(!in_stall_from_icache) begin
		if(in_out_offset == 64 * 8 && state == CACHE_WAIT) begin
			if(lru == 1) begin
				dcache[index_bits][511:0] <= inData;
				dcache[index_bits][561] <= 1;  // valid bit
				dcache[index_bits][560:512] <= tag_bits;
				state <= CACHE_BEGIN;
				lru <= 0;
				//$display("data 0x%x is being brought in from memory at address 0x%x", inData, inResult);
			end else begin 
				dcache[index_bits][1074:563] <= inData;
				dcache[index_bits][1124] <= 1;
				dcache[index_bits][1123:1075] <= tag_bits;
				state <= CACHE_BEGIN;
				lru <= 1;
				//$display("data 0x%x is being brought in from memory at address 0x%x", inData, inResult);
			end
		end
	end
end

always_ff @ (posedge clk) begin
	if(!in_stall_from_icache) begin
		if(inFlushFromEcall == 0) begin
			if(in_do_invalidate) begin
				if(dcache[in_invalid_phys_addr[14:6]][560:512] == in_invalid_phys_addr[63:15])
					dcache[in_invalid_phys_addr[14:6]][561] <= 0;  // invalidate
				else if(dcache[in_invalid_phys_addr[14:6]][1123:1075] == in_invalid_phys_addr[63:15])
					dcache[in_invalid_phys_addr[14:6]][1124] <= 0;   // invalidate    
			end else if(in_do_invalidate_2) begin
				if(dcache[in_invalid_phys_addr_2[14:6]][560:512] == in_invalid_phys_addr_2[63:15])
					dcache[in_invalid_phys_addr_2[14:6]][561] <= 0; 
				else if(dcache[in_invalid_phys_addr_2[14:6]][1123:1075] == in_invalid_phys_addr_2[63:15])
					dcache[in_invalid_phys_addr_2[14:6]][1124] <= 0;
			end
		end
	end
end

always_ff @ (posedge clk) begin
	if(!in_stall_from_icache && !stall) begin
		if(inFlushFromEcall) begin
			outReadData <= 0;
		end else begin
			outReadData <= data;
		end
	end
end


always_ff @ (posedge clk) begin
	if(!in_stall_from_icache && !stall) begin
		if(inFlushFromEcall == 1) begin
			memOrReg <= 0;
			result <= 0;
			regWrite <= 0;
			destRegister <= 0;
			ecall <= 0;
			epc <= 0;
			memRead <= 0;
			outPc <= 0;
			outJump <= 0;
		end else begin
			memRead <= inMemRead;
			memOrReg <= inMemOrReg;
			result <= inResult;
			regWrite <= inRegWrite;
			destRegister <= inDestRegister;
			ecall <= inEcall;
			epc <= inEpc;
			outPc <= inPc;
			outJump <= inJump;
		end
	end
end

assign outMiss = miss;
assign outStall = stall;
assign outMemOrReg = memOrReg;
assign outRegWrite = regWrite;
assign outResult = result;
assign outDoPendingWrite = do_pending_writes;
assign outAddressPendingWrite = address_for_pending_write;
assign outFlushJump = flush_jump;
assign outEcall = ecall;
assign outDestRegister = destRegister;
assign outEpc = epc;
assign outMemRead = memRead;
assign outSizePendingWrite = size_for_pending_write;

endmodule