`include "Sysbus.defs"

module registerFile
#(
	BUS_DATA_WIDTH = 64
)
(   
	input clk,
	input end_of_cycle,
	input reg_file_en,
	input [5:0] alu_control,   // which alu operation to perform
	input muxB_control, // multiplexer selects immediate or register
    input write_en,  // ALU SETS THE WRITE-EN LOGIC
	input [4:0] addressA, 
	input [4:0] addressB,
	input [BUS_DATA_WIDTH-1 : 0] writeBack,  /* comes from the writeback module */
	input [4:0] addressC,
	input [BUS_DATA_WIDTH-1 : 0] imm,
	input call_for_print,
	
	output [BUS_DATA_WIDTH-1 : 0] dataA, /* go to the ALU */
	output [BUS_DATA_WIDTH-1 : 0] dataB,
	output [5:0] out_alu_control,
	output out_alu_en
);

reg [BUS_DATA_WIDTH-1 : 0] rA, rB;

reg [5:0] _alu_control;
logic alu_en;

reg [BUS_DATA_WIDTH-1 : 0] mem[31:0]; 
// 32 * 64 register file

assign mem[0] = 0;

always @ (posedge clk) begin
	
    if(reg_file_en) begin
		$display("%x,%x", addressA, imm);
		_alu_control <= alu_control;
		if(write_en) begin
			mem[addressC] <= writeBack ;
		end
		rA <= mem[addressA];
		if(muxB_control) begin // imm
			rB <= imm;
		end else begin
			rB <= mem[addressB];
		end
		alu_en <= 1;
	end else begin
		alu_en <= 0;
		if(write_en) begin
			mem[addressC] <= writeBack ;
		end
	end
end
 

always @ (posedge clk) 
	if(call_for_print) begin
		print_registers();
	end
	
assign dataA = rA;
assign dataB = rB;
assign out_alu_control = _alu_control;
assign out_alu_en = alu_en;

function void print_registers;
    int i;
	for(i = 0; i < 32; i++) begin
		$display("Register\t%d: %x ", i+1, mem[i]);
	end
	$finish;
endfunction

endmodule












