
module decoder
(
	input [31:0] ir, // this comes from instruction fetch module
	output reg[25*8:0] inst  // final instruction output
);

// the below piece of code can be made into a function..

always_comb begin
	case(ir[6:0])
		7'b0010011 : 
			case(ir[14:12])
				3'b000 :
					inst = {"addi", } ; 
				3'b010:
					inst = {"slti", } ;
				3'b011:
					inst = {"sltiu", } ;
				3'b100:
					inst = {"xori", } ;
				3'b110:
					inst = {"ori", };
				3'b111:
					inst = {"andi", };
				3'b001:
					inst = {"slli", };
				3'b101:
					if(ir[31:25] == 7'b0000000) begin
						inst = {"srli", } ;
					end
					else if(ir[31:25] == 7'b0100000) begin
						inst = {"srai", } ;
					end
			endcase
		7'b0110011:
			case(ir[14:12])
				3'b000:
					if(ir[31:25] == 7'b0000000) begin
						inst = {"add", } ;
					end
					else if(ir[31:25] == 7'b0100000) begin
						inst = {"sub", } ;
					end
				3'b001:
					inst = {"sll", } ;
				3'b010:
					inst = {"slt", } ;
				3'b011:
					inst = {"sltu", };
				3'b100:
					inst = {"xor", } ;
				3'b101:
					if(ir[31:25] = 7'b0000000) begin
						inst = {"srl", } ;
					else if(ir[31:25] = 7'b0100000) begin
						inst = {"sra", };
				3'b110:
					inst = {"or"} ;
				3'b111:
					inst = {"and"} ;
			endcase
		7'b1100011:
			case(ir[14:12])
				3'b000:
					inst = {"beq", };
				3'b001:
					inst = {"bne", };
				3'b100:
					inst = {"blt", };
				3'b101:
					inst = {"bge", };
				3'b110:
					inst = {"bltu", };
				3'b111:
					inst = {"bgeu", };
				default:
					// TODO: default do something here
			endcase
		7'b0110111:
			inst = {"lui", };
		7'b0010111:
			inst = {"auipc", };
		7'b1101111:
			inst = {"jal", } ;
		7'b1100111:
			inst = {"jalr", };
		7'b0000011:
			case(ir[14:12])
				3'b000:
					inst = {"lb ",} ;
				3'b001:
					inst = {"lh ", };
				3'b010:
					inst = {"lw", };
				3'b100:
					inst = {"lbu", };
				3'b101:
					inst = {"lhu", };
				default:
					// TODO: default do something here
			endcase
		7'b0001111:
			case(ir[14:12])
				3'b000:
					inst = {"fence", } ;
				3'b001:
					inst = {"fence.i", };
				default:
					// TODO: default do something here
			endcase
		7'b1110011:
			case(ir[14:12])
				3'b000:
					if(ir[31:25] == 7'b0000000) begin
						inst = {"ecall", };
					end
					else if(ir[31:25] == 7'b0000001) begin
						inst = {"ebreak", };
					end
				3'b001:
					inst = {"csrrw ", };
				3'b010:
					inst = {"csrrs ", };
				3'b011:
					inst = {"csrrc ", };
				3'b101:
					inst = {"csrrwi ", };
				3'b110:
					inst = {"csrrsi ", };
				3'b111:
					inst = {"csrrci ", };
				default:
					// TODO: default do something here
			endcase
						
				
				

end