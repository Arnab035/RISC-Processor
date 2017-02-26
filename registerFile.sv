`include "Sysbus.defs"

/* register file module */

/* inputs and outputs for register file 
1. 3 address inputs and
2. 1 data input 
2.a) 1 immediate input
3. 2 data outputs */

module registerFile
#(
	BUS_DATA_WIDTH = 64
)
(   
	input clk,
	input [5:0] alu_control,   // which alu operation to perform
	input muxB_control, // multiplexer selects immediate or register
    input write_en,  // ALU SETS THE WRITE-EN LOGIC
	input [4:0] addressA, 
	input [4:0] addressB,
	input [BUS_DATA_WIDTH-1 : 0] writeBack,  /* comes from the writeback module */
	input [4:0] addressC,
	input [BUS_DATA_WIDTH-1 : 0] imm,
	
	output [BUS_DATA_WIDTH-1 : 0] dataA, /* go to the ALU */
	output [BUS_DATA_WIDTH-1 : 0] dataB
);

reg [BUS_DATA_WIDTH-1 : 0] rA, rB;

reg [BUS_DATA_WIDTH-1 : 0] mem[31:0]; 
// 32 * 64 register file

assign mem[0] = 0;

always @ (posedge clk) 
	if(write_en) begin
		mem[addressC] <= writeBack ;
	end else begin
		rA <= mem[addressA];
		if(muxB_control) begin // imm
			rB <= imm;
		end else begin
			rB <= mem[addressB];
		end
	end


assign dataA = rA;
assign dataB = rB;

// define alu module here
 
 alu a (
	.clk(clk),
	.dataA(dataA),
	.dataB(dataB),
	.alu_control(alu_control)
);
 
 
endmodule









