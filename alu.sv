/* first draft of the alu module */
`include "sysbus.defs"

module alu 
#(
	BUS_DATA_WIDTH = 64
)
(
	input [BUS_DATA_WIDTH-1 : 0] dataA,
	input [BUS_DATA_WIDTH-1 : 0] dataB,  // could be immediate or register
	input [5:0] alu_control,  // for 41 ALU ops, 6 bits
	output [BUS_DATA_WIDTH-1 : 0] dataOut
);

reg [BUS_DATA_WIDTH-1 : 0] val;

always @ (posedge clk) begin
	case(alu_control)
		6'b000001:  // addi
			val <= dataA + dataB ;
		6'b000010:  // slti
			if($signed(dataA) < $signed(dataB)) begin
				val <= 1;
			end else begin
				val <= 0;
			end
		6'b000011:  // sltiu
			if(dataA < dataB) begin
				val <= 1;
			end else begin
				val <= 0;
			end
		6'b000100:  // xori
			val <= dataA ^ dataB;
		6'b000101:  // ori
			val <= dataA | dataB;
		6'b000110:  // andi
			val <= dataA & dataB;
		6'b000111: // slli
			val <= dataA << dataB[4:0] ;
		6'b001000: // srli
			val <= dataA >> dataB[4:0] ;
		6'b001001: // srai
			val <= dataA >>> dataB[4:0] ;
		6'b001100: // add
			val <= dataA + dataB;
		6'b001101: // sub
			val <= dataA - dataB;
		6'b001110: // sll
			val <= dataA << dataB[4:0];
		6'b001111: // slt
			if($signed(dataA) < $signed(dataB)) begin
				val <= 1;
			end else begin
				val <= 0;
			end
		6'b010000: // sltu
			if(dataA < dataB) begin
				val <= 1;
			end else begin
				val <= 0;
			end
		6'b010001: // xor
			val <= dataA ^ dataB;
		6'b010010:  // srl
			val <= dataA >> dataB[4:0] ;
		6'b010011: // sra
			val <= dataA >>> dataB[4:0] ;
		6'b010100: // or
			val <= dataA | dataB ;
		6'b010101: // and
			val <= dataA & dataB;
		6'b010110: // 
 			
			
			
			






