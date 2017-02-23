`include "sysbus.defs"

/* register file module */

/* inputs and outputs for register file 
1. 3 address inputs and
2. 1 data input 
3. 2 data outputs */

module register_file
#(
	BUS_DATA_WIDTH = 64
)
(   
	input clk,
    input write_en,  // ALU SETS THE WRITE-EN LOGIC
	input [4:0] addressA, 
	input [4:0] addressB,
	input [BUS_DATA_WIDTH-1 : 0] writeBack,  /* comes from the writeback module */
	input [4:0] addressC,
	
	output dataA, /* go to the ALU */
	output dataB
);

reg [BUS_DATA_WIDTH-1 : 0] rA, rB;

reg [BUS_DATA_WIDTH-1 : 0] mem[31:0]; // 32 general purpose registers

always @ (posedge clk) begin
	rA <= mem[addressA];
	rB <= mem[addressB];
	
	if(write_en) begin
		mem[addressC] <= writeBack ;
	end
end

assign dataA = rA;
assign dataB = rB;


// define alu module here









