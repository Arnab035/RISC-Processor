
module decoder
(
	input signed [31:0] ir, // this comes from instruction fetch module
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

function compute_offset

//****************************************************************************************************************************//

always_comb begin
	case(ir[6:0])
		7'b0010011 : 
			case(ir[14:12])
				3'b000 :
					if(ir[31:20] == 11'd0 && ir[11:7] == 5'd0 && ir[19:15] == 5'd0) begin
						$display("nop");
					end
					else if(ir[31:20] == 11'd0) begin
						$display("mv	%s,%s", find_register(ir[11:7]) ,find_register(ir[19:15]));
					end else begin
						$display("addi	%s,%s,%d", find_register(ir[11:7]) ,find_register(ir[19:15]), ir[31:20]);
					end
				3'b010:
					$display("slti	%s,%s,%d", find_register(ir[11:7]), find_register(ir[19:15]), ir[31:20]);
				3'b011:
					if(ir[31:20] == 11'd1) begin
						$display("seqz	%s,%s", find_register(ir[11:7]), find_register(ir[19:15]));
					end else begin
						$display("sltiu	%s,%s,%d", find_regsiter(ir[11:7]), find_register(ir[19:15]), ir[31:20]);
					end
				3'b100:
					if(ir[31:20] == -11'd1) begin
						$display("not	%s,%s", find_register(ir[11:7]), find_register(ir[19:15]));
					end else begin
						$display("xori	%s,%s,%d", find_register(ir[11:7]), find_register(ir[19:15]), ir[31:20]);
					end
				3'b110:
					$display("ori	%s,%s,%d", find_register(ir[11:7]), find_register(ir[19:15]), ir[31:20]);
				3'b111:
					$display("andi	%s,%s,%d", find_register(ir[11:7]), find_register(ir[19:15]), ir[31:20]) ;
				3'b001:
					$display("slli	%s,%s,0x%h", find_register(ir[11:7]), find_register(ir[19:15]), ir[24:20]);
				3'b101:
					if(ir[31:25] == 7'b0000000) begin
						$display("srli	%s,%s,0x%h", find_register(ir[11:7]), find_register(ir[19:15]), ir[24:20]) ;
					end
					else if(ir[31:25] == 7'b0100000) begin
						%display("srai	%s,%s,0x%h", find_register(ir[11:7]), find_register(ir[19:15]), ir[24:20]) ;
					end
			endcase
		7'b0100011:
			case(ir[14:12]) begin
				3'b000: 
					$display("sb	%s,%d(%s)", find_register(ir[24:20]), compute_offset(ir[31:25], ir[11:7]), find_register(ir[19:15]));
				3'b001: 
					$display("sh	%s,%d(%s)", find_register(ir[24:20]), compute_offset(ir[31:25], ir[11:7]), find_register(ir[19:15]));
				3'b010:	
					$display("sw	%s,%d(%s)", find_register(ir[24:20]), compute_offset(ir[31:25], ir[11:7]), find_register(ir[19:15]));
				3'b011:	
					$display("sd	%s,%d(%s)", find_register(ir[24:20]), compute_offset(ir[31:25], ir[11:7]), find_register(ir[19:15]));
				default:
					// TODO: default case.
		7'b0110011:
			case(ir[14:12])
				3'b000:
					if(ir[31:25] == 7'b0000000) begin
						$display("add	%s,%s,%s", find_register(ir[11:7]), find_register(ir[19:15]), find_register(ir[24:20])) ;
					end
					else if(ir[31:25] == 7'b0100000) begin
						if(ir[19:15]==5'd0) begin
							$display("neg	%s,%s", find_register(ir[11:7]), find_register(ir[24:20]));
						end else
						begin
							$display("sub	%s,%s,%s", find_register(ir[11:7]), find_register(ir[19:15]), find_register(ir[24:20]));
						end
					end
					else if(ir[31:25] == 7'b0000001) begin
						$display("mul	%s,%s,%s", find_register(ir[11:7]), find_register(ir[19:15]), find_register(ir[24:20])) ;
					end
				3'b001:
					if(ir[31:25] == 7'b0000000) begin
						$display("sll	%s,%s,%s", find_register(ir[11:7]), find_register(ir[19:15]), find_register(ir[24:20])) ;
					end
					else if(ir[31:25] = 7'b0000001) begin
						$display("mulh	%s,%s,%s", find_register(ir[11:7]), find_register(ir[19:15]), find_register(ir[24:20])) ;
					end
				3'b010:
					if(ir[31:25] == 7'b0000000) begin
						if(ir[19:15] == 5'd0) begin
							$display("sgtz	%s,%s", find_register(ir[11:7]), find_register(ir[24:20]));
						end else if(ir[24:20] == 5'd0) begin
							$display("sltz	%s,%s", find_register(ir[11:7]), find_register(ir[19:15]));
						end else begin
							$display("slt  %s,%s,%s", find_register(ir[11:7]), find_register(ir[19:15]), find_register(ir[24:20])) ;
						end
					end
					else if(ir[31:25] == 7'b0000001) begin
						$display("mulhsu	%s,%s,%s", find_register(ir[11:7]), find_register(ir[19:15]), find_register(ir[24:20])) ;
					end
				3'b011:
					if(ir[31:25] == 7'b0000000) begin
						if(ir[19:15] == 5'd0) begin 
							$display("snez	%s,%s", find_register(ir[11:7]), find_register(ir[24:20]));
						end else begin
							$display("sltu	%s,%s,%s", find_register(ir[11:7]), find_register(ir[19:15]), find_register(ir[24:20])) ;
						end
					end
					else if(ir[31:25] == 7'b0000001) begin
						$display("mulhu	%s,%s,%s", find_register(ir[11:7]), find_register(ir[19:15]), find_register(ir[24:20])) ;
					end
				3'b100:
					if(ir[31:25] == 7'b0000000) begin
						$display("xor	%s,%s,%s", find_register(ir[11:7]), find_register(ir[19:15]), find_register(ir[24:20]) ) ;
					end
					else if(ir[31:25] == 7'b0000001) begin
						$display("div	%s,%s,%s", find_register(ir[11:7]), find_register(ir[19:15]), find_register(ir[24:20]) );
					end
				3'b101:
					if(ir[31:25] == 7'b0000000) begin
						$display("srl	%s,%s,%s", find_register(ir[11:7]), find_register(ir[19:15]), find_register(ir[24:20])) ;
					else if(ir[31:25] == 7'b0100000) begin
						$display("sra	%s,%s,%s", find_register(ir[11:7]), find_register(ir[19:15]), find_register(ir[24:20]));
					else if(ir[31:25] == 7'b0000001) begin
						$display("divu	%s,%s,%s", find_register(ir[11:7]), find_register(ir[19:15]), find_register(ir[24:20])) ;
				3'b110:
					if(ir[31:25] == 7'b0000000) begin
						$display("or	%s,%s,%s", find_register(ir[11:7]), find_register(ir[19:15]), find_register(ir[24:20])) ;
					else if(ir[31:25] == 7'b0000001 ) begin
						$display("rem	%s,%s,%s", find_register(ir[11:7]), find_register(ir[19:15]), find_register(ir[24:20])) ;
					end
				3'b111:
					if(ir[31:25] == 7'b0000000) begin
						$display("and	%s,%s,%s", find_register(ir[11:7]), find_register(ir[19;15]), find_register(ir[24:20])) ;
					end
					else if(ir[31:25] == 7'b0000001) begin
						$display("remu	%s,%s,%s", find_register(ir[11:7]), find_register(ir[19:15]), find_register(ir[24:20])) ;
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
			$display("auipc	%s,0x%h", find_register(ir[11:7]), ir[31:12]);
		7'b1101111:
			if(ir[11:7] == 5'd0) begin
				$display("j	0x%h", calculate_jump(pc, ir[31:12]) ) ;  // right shift offset by 8 --> add to pc
			end else if(ir[11:7] == 5'd1) begin
				$display("jal	0x%h", calculate_jump(pc, ir[31:12]) ) ;
			end
		7'b1100111:
			if(ir[11:7] == 5'd0 && ir[31:20] == 12'd0) begin
				$display("jr	%s", find_register(ir[19:15]));
			end else if(ir[11:7] == 5'd1 && ir[31:20] == 12'd0) begin
				$display("jalr	%s", find_register(ir[19:15]));
			end else if(ir[11:7] == 5'd0 && ir[19:15] == 5'd1 && ir[31:20] == 12'd0) begin
				$display("ret");
			end
		7'b0000011:
			case(ir[14:12])
				3'b000: 
					$display("lb	%s,%d(%s)", find_register(ir[11:7]), ir[31:20], find_register(ir[19:15])) ;
				3'b001: 
					$display("lh	%s,%d(%s)", find_register(ir[11:7]), ir[31:20], find_register(ir[19:15])) ;
				3'b010: 
					$display("lw	%s,%d(%s)", find_register(ir[11:7]), ir[31:20], find_register(ir[19:15]));
				3'b100: 
					$display("lbu	%s,%d(%s)", find_register(ir[11:7]), ir[31:20], find_register(ir[19:15]));
				3'b101:	
					$display("lhu	%s,%d(%s)", find_register(ir[11:7]), ir[31:20], find_register(ir[19:15]));
				3'b110: 
					$display("lwu	%s,%d(%s)", find_register(ir[11:7]), ir[31:20], find_register(ir[19:15]));
				3'b011: 
					$display("ld	%s,%d(%s)", find_register(ir[11:7]), ir[31:20], find_register(ir[19:15]));
				default:
					// TODO: default do something here
			endcase
		7'b0111011:
			case(ir[14:12])
				3'b000:
					if(ir[31:25] == 7'b0000000) begin
						$display("addw	%s,%s,%s", find_register(ir[11:7]), find_register(ir[19:15]), find_register(ir[24:20]));
					end
					else if(ir[31:25] == 7'b0100000) begin
						if(ir[19:15] == 5'd0) begin
							$display("negw	%s,%s", find_register(ir[11:7]), find_register(ir[24:20]));
						end else
							$display("subw	%s,%s,%s", find_register(ir[11:7]), find_register(ir[19:15]), find_register(ir[24:20]));
						begin
						end
					end
					else if(ir[31:25] == 7'b0000001) begin
						$display("mulw	%s,%s,%s", find_register(ir[11:7]), find_register(ir[19:15]), find_register(ir[24:20])) ;
					end
				3'b001:
					$display("sllw	%s,%s,%s", find_register(ir[11:7]), find_register(ir[19:15]), find_register(ir[24:20]));
				3'b101:
					if(ir[31:25] == 7'b0000000) begin
						$display("srlw	%s,%s,%s", find_register(ir[11:7]), find_register(ir[19:15]), find_register(ir[24:20]));
					end
					else if(ir[31:25] == 7'b0100000) begin
						$display("sraw	%s,%s,%s", find_register(ir[11:7]), find_register(ir[19:15]), find_register(ir[24:20]));
					end
					else if(ir[31:25] == 7'b0000001) begin
						$display("divuw	%s,%s,%s", find_register(ir[11:7]), find_register(ir[19:15]), find_register(ir[24:20]));
					end;
				3'b100:
					$display("divw	%s,%s,%s", find_register(ir[11:7]), find_register(ir[19:15]), find_register(ir[24:20])) ;
				3'b110:
					$display("remw	%s,%s,%s", find_register(ir[11:7]), find_register(ir[19:15]), find_register(ir[24:20])) ;
				3'b111:
					$display("remuw	%s,%s,%s", find_register(ir[11:7]), find_register(ir[19:15]), find_register(ir[24:20])) ;
				default:
					// TODO: default do something here
			endcase;
		7'b0011011:
			case(ir[14:12])
				3'b000:
					$display("addiw	%s,%s,%d", find_register(ir[11:7]), find_register(ir[19:15]), ir[31:20]);
				3'b001:
					$display("slliw	%s,%s,%d", find_register(ir[11:7]), find_register(ir[19:15]), ir[31:20]);
				3'b101:
					if(ir[31:25] == 7'b0000000) begin
						$display("srliw	%s,%s,%d", find_register(ir[11:7]), find_register(ir[19:15]), ir[31:20]);
					end
					else if(ir[31:25] == 7'b0100000) begin
						$display("sraiw	%s,%s,%d", find_register(ir[11:7]), find_register(ir[19:15]), ir[31:20]);
					end
				default:
					$display("wrong opcode format");
			endcase
end