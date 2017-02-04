
module decoder
(
	input [31:0] ir, // this comes from instruction fetch module
);
//******************************************** helper functions defined here ************************************************//

function string find_register;
	input [4:0] reg_number;
	begin
		case(reg_number)
			5'b00000:
				find_register = "zero" ;
			5'b00001:
				find_register = "ra" ;
			5'b00010:
				find_register = "sp" ;
			5'b00011:
				find_register = "gp" ;
			5'b00100:
				find_register = "tp" ;
			5'b00101:
				find_register = "t0" ;
			5'b00110:
				find_register = "t1" ;
			5'b00111:
				find_register = "t2" ;
			5'b01000:
				find_register = "s0" ;
			5'b01001:
				find_register = "s1" ;
			5'b01010:
				find_register = "a0" ;
			5'b01011:
				find_register = "a1" ;
			5'b01100:
				find_register = "a2" ;
			5'b01101:
				find_register = "a3" ;
			5'b01110:
				find_register = "a4" ;
			5'b01111:
				find_register = "a5" ;
			5'b10000:
				find_register = "a6" ;
			5'b10001:
				find_register = "a7" ;
			5'b10010:
				find_register = "s2" ;
			5'b10011:
				find_register = "s3" ;
			5'b10100:
				find_register = "s4" ;
			5'b10101:
				find_register = "s5" ;
			5'b10110:
				find_register = "s6" ;
			5'b10111:
				find_register = "s7" ;
			5'b11000:
				find_register = "s8" ;
			5'b11001:
				find_register = "s9" ;
			5'b11010:
				find_register = "s10" ;
			5'b11011:
				find_register = "s11" ;
			5'b11100:
				find_register = "t3" ;
			5'b11101:
				find_register = "t4" ;
			5'b11110:
				find_register = "t5" ;
			5'b11111:
				find_register = "t6" ;
		endcase
	end
endfunction

//****************************************************************************************************************************//

always_comb begin
	case(ir[6:0])
		7'b0010011 : 
			case(ir[14:12])
				3'b000 :
					inst = {"addi  ", } ; 
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
		7'b0100011:
			case(ir[14:12]) begin
				3'b000:
					inst = {"sb ", };
				3'b001:
					inst = {"sh ", };
				3'b010:
					inst = {"sw ", };
				3'b011:
					inst = {"sd ", };
				default:
					// TODO: default case.
		7'b0110011:
			case(ir[14:12])
				3'b000:
					if(ir[31:25] == 7'b0000000) begin
						inst = {"add", } ;
					end
					else if(ir[31:25] == 7'b0100000) begin
						inst = {"sub", } ;
					end
					else if(ir[31:25] == 7'b0000001) begin
						inst = {"mul", } ;
					end
				3'b001:
					if(ir[31:25] == 7'b0000000) begin
						inst = {"sll", } ;
					end
					else if(ir[31:25] = 7'b0000001) begin
						inst = {"mulh", };
					end
				3'b010:
					if(ir[31:25] == 7'b0000000) begin 
						inst = {"slt", } ;
					end
					else if(ir[31:25] == 7'b0000001) begin
						inst = {"mulhsu", } ;
					end
				3'b011:
					if(ir[31:25] == 7'b0000000) begin
						inst = {"sltu", };
					end
					else if(ir[31:25] == 7'b0000001) begin
						inst = {"mulhu ", };
					end
				3'b100:
					if(ir[31:25] == 7'b0000000) begin
						inst = {"xor", } ;
					end
					else if(ir[31:25] == 7'b0000001) begin
						inst = {"div", };
					end
				3'b101:
					if(ir[31:25] == 7'b0000000) begin
						inst = {"srl", } ;
					else if(ir[31:25] == 7'b0100000) begin
						inst = {"sra", };
					else if(ir[31:25] == 7'b0000001) begin
						inst = {"divu", };
				3'b110:
					if(ir[31:25] == 7'b0000000) begin
						inst = {"or", } ;
					else if(ir[31:25] == 7'b0000001 ) begin
						inst = {"rem", };
					end
				3'b111:
					if(ir[31:25] == 7'b0000000) begin
						inst = {"and", } ;
					end
					else if(ir[31:25] == 7'b0000001) begin
						inst = {"remu", } ;
					end
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
			$display("lui	%s,0x%h", find_register(ir[11:7]), ir[31:12]);
		7'b0010111:
			$display("auipc	%s,0x%h, find_register(ir[11:7], ir[31:12]);
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
				3'b110:
					inst = {"lwu ", };
				3'b011:
					inst = {"ld ", };
				default:
					// TODO: default do something here
			endcase
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
		7'b0111011:
			case(ir[14:12])
				3'b000:
					if(ir[31:25] == 7'b0000000) begin
						inst = {"addw ", } ;
					end
					else if(ir[31:25] == 7'b0100000) begin
						inst = {"subw ", };
					end
					else if(ir[31:25] == 7'b0000001) begin
						inst = {"mulw ", } ;
					end
				3'b001:
					inst = {"sllw ", };
				3'b101:
					if(ir[31:25] == 7'b0000000) begin
						inst = {"srlw ", };
					end
					else if(ir[31:25] == 7'b0100000) begin
						inst = {"sraw ", };
					end
					else if(ir[31:25] == 7'b0000001) begin
						inst = {"divuw ", };
					end;
				3'b100:
					inst = {"divw ", } ;
				3'b110:
					inst = {"remw", } ;
				3'b111:
					inst = {"remuw", } ;
				default:
					// TODO: default do something here
			endcase;
		7'b0011011:
			case(ir[14:12])
				3'b000:
					inst = {"addiw", };
				3'b001:
					inst = {"slliw", };
				3'b101:
					if(ir[31:25] == 7'b0000000) begin
						inst = {"srliw", };
					end
					else if(ir[31:25] == 7'b0100000) begin
						inst = {"sraiw", };
					end
				default:
					// TODO: default do something here
			endcase
end