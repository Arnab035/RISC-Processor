module branchpredictor
(
	input clk,
	input [63:0] inPc,
	input in_write_to_bp,
	input in_is_update_state,
	input [63:0] in_branch_source,
	input [63:0] in_branch_target,
	input in_is_actual_branch_taken,
	input [63:0] in_source,         // pc used to update the state
	input in_stall_from_icache,
	input in_stall_from_dcache,
	input in_stall_from_hazardunit,
	output outMiss,
	output is_branch_taken,
	output [63 : 0] outPc 
);

logic [120:0] btbuffer[1023:0];
logic miss;

logic [9:0] index_bits;
logic [53:0] tag_bits;

/*
	-- general Branch Target Buffer design -- 10 index bits means 1024 entries

	-- address --------  tag(54) ---------   index(10)

	-- cache design ----------  valid(1) -------  tag(54)  --------   target address(64) -------- prediction (2)
								btbuffer[120]	btbuffer[119:66]		btbuffer[65:2]			  btbuffer[1:0]
*/

assign index_bits = inPc[9:0];
assign tag_bits = inPc[63:10];

always_comb begin
	if(!in_stall_from_icache && !in_stall_from_dcache && !in_stall_from_hazardunit) begin
		if(btbuffer[index_bits][119:66] == tag_bits && btbuffer[index_bits][120]) begin 
			if(btbuffer[index_bits][1:0] == 2'b11 || btbuffer[index_bits][1:0] == 2'b10) begin
				outPc = btbuffer[index_bits][65:2]; 
				miss = 0;
				is_branch_taken = 1;
			end else begin
				outPc = inPc + 4;
				miss = 0;
				is_branch_taken = 0;
			end
		end
		else begin
			outPc = inPc + 4;
			miss = 1;
			is_branch_taken = 0;
		end
	end
end

assign outMiss = miss;

always_ff @ (posedge clk) begin
	if(!in_stall_from_icache && !in_stall_from_dcache && !in_stall_from_hazardunit) begin
		if(in_write_to_bp) begin
			btbuffer[in_branch_source[9:0]][65:2] <= in_branch_target;
			btbuffer[in_branch_source[9:0]][119:66] <= in_branch_source[63:10];
			btbuffer[in_branch_source[9:0]][120] <= 1;   // valid 
			btbuffer[in_branch_source[9:0]][1:0] <= 2'b10;   // branch predicted not taken, but actually taken
		end
	end
end

// update prediction states based on 2-bit saturating counter
/*
States change based on the below (4 * 2) logic ---
1. If state is 00 --> branch predicted not taken and is actually not taken --> state stays at 00
2. If state is 00 --> branch predicted not taken and is actually taken --> state goes to 01
3. If state is 01 --> branch predicted not taken and is actually not taken --> state goes to 00
4. If state is 01 --> branch predicted not taken and is actually taken --> state goes to 10

5. If state is 10 --> branch predicted taken and is actually taken --> state goes to 11.
6. If state is 10 --> branch predicted taken and is actually not taken --> state goes to 01.
7. If state is 11 --> branch predicted taken and is actually taken --> state goes to 11.
8. If state is 11 --> branch predicted taken and is actually not taken --> state goes to 10.
*/

always_ff @ (posedge clk) begin
	if(!in_stall_from_icache && !in_stall_from_dcache && !in_stall_from_hazardunit) begin
		if(in_is_update_state) begin
			if(btbuffer[in_source[9:0]][1:0] == 2'b00) begin
				if(in_is_actual_branch_taken == 0) begin
					btbuffer[in_source[9:0]][1:0] <= 2'b00;
				end else begin
					btbuffer[in_source[9:0]][1:0] <= 2'b01;
				end
			end else if(btbuffer[in_source[9:0]][1:0] == 2'b01) begin
				if(in_is_actual_branch_taken == 0) begin
					btbuffer[in_source[9:0]][1:0] <= 2'b00;
				end else begin
					btbuffer[in_source[9:0]][1:0] <= 2'b10;
				end
			end else if(btbuffer[in_source[9:0]][1:0] == 2'b10) begin
				if(in_is_actual_branch_taken == 0) begin
					btbuffer[in_source[9:0]][1:0] <= 2'b01;
				end else begin
					btbuffer[in_source[9:0]][1:0] <= 2'b10;
				end
			end else if(btbuffer[in_source[9:0]][1:0] == 2'b11) begin
				if(in_is_actual_branch_taken == 0) begin
					btbuffer[in_source[9:0]][1:0] <= 2'b10;
				end else begin
					btbuffer[in_source[9:0]][1:0] <= 2'b11;
				end
			end
		end
	end
end

endmodule