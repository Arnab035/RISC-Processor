/********************************************************* Useful functions ***********************************************************/
			
function int compute_offset;
	input [6:0] offset_high;
	input [5:0] offset_low;
	begin
		compute_offset = ($signed(offset_high) << 5) | ($signed(offset_low)) ;
	end
endfunction

/****************************************************************************************************************************/


function decode(
	input [BUS_DATA_WIDTH - 1:0] pc, ir
	);
	
	logic signed [63:0] imm ;
	
	string register_file[31:0];
	
	register_file[0] = "zero";
	register_file[1] = "ra";
	register_file[2] = "sp";
	register_file[3] = "gp";
	register_file[4] = "tp";
	register_file[5] = "t0";
	register_file[6] = "t1";
	register_file[7] = "t2";
	register_file[8] = "s0";
	register_file[9] = "s1";
	register_file[10] = "a0";
	register_file[11] = "a1";
	register_file[12] = "a2";
	register_file[13] = "a3";
	register_file[14] = "a4";
	register_file[15] = "a5";
	register_file[16] = "a6";
	register_file[17] = "a7";
	register_file[18] = "s2";
	register_file[19] = "s3";
	register_file[20] = "s4";
	register_file[21] = "s5";
	register_file[22] = "s6";
	register_file[23] = "s7";
	register_file[24] = "s8";
	register_file[25] = "s9";
	register_file[26] = "s10";
	register_file[27] = "s11";
	register_file[28] = "t3";
	register_file[29] = "t4";
	register_file[30] = "t5";
	register_file[31] = "t6";
	
	begin
		for(int i = 0; i < 2 && ir; i++) begin // loop twice for 64-bit data - fetch 32-bit in first loop
			case(ir[6:0])
				7'b0010011: 
					case(ir[14:12])
						3'b000:
							if(ir[31:20] == 11'd0 && ir[11:7] == 5'd0 && ir[19:15] == 5'd0) begin
								$display("  %0h:\t%h\tnop", pc, ir[31:0] );
							end
							else if(ir[31:20] == 11'd0 && ir[19:15] == 5'd0) begin
								$display("  %0h:\t%h\tli\t%s,0", pc, ir[31:0], register_file[ir[11:7]]);
							end else if(ir[31:20] == 11'd0) begin
								$display("  %0h:\t%h\tmv\t%s,%s",pc,ir[31:0],register_file[ir[11:7]] ,register_file[ir[19:15]]);
							end else begin
								$display("  %0h:\t%h\taddi\t%s,%s,%0d",pc,ir[31:0],register_file[ir[11:7]] ,register_file[ir[19:15]], $signed(ir[31:20])) ;
							end
						3'b010:
								$display("  %0h:\t%h\tslti\t%s,%s,%0d",pc,ir[31:0],register_file[ir[11:7]] ,register_file[ir[19:15]], $signed(ir[31:20]));
						3'b011:
							if(ir[31:20] == 11'd1) begin
								$display("  %0h:\t%h\tseqz\t%s,%s",pc, ir[31:0], register_file[ir[11:7]], register_file[ir[19:15]]);
							end else begin
								$display("  %0h:\t%h\tsltiu\t%s,%s,%0d",pc,ir[31:0], register_file[ir[11:7]], register_file[ir[19:15]], $signed(ir[31:20]));
							end
						3'b100:
							if(ir[31:20] == -11'd1) begin
								$display("  %0h:\t%h\tnot\t%s,%s", pc, ir[31:0], register_file[ir[11:7]], register_file[ir[19:15]]);
							end else begin
								$display("  %0h:\t%h\txori\t%s,%s,%0d", pc, ir[31:0], register_file[ir[11:7]], register_file[ir[19:15]], $signed(ir[31:20]));
							end
						3'b110:
							$display("  %0h:\t%h\tori\t%s,%s,%0d", pc, ir[31:0], register_file[ir[11:7]], register_file[ir[19:15]], $signed(ir[31:20]));
						3'b111:
							$display("  %0h:\t%h\tandi\t%s,%s,%0d", pc, ir[31:0], register_file[ir[11:7]], register_file[ir[19:15]], $signed(ir[31:20])) ;
						3'b001:
							$display("  %0h:\t%h\tslli\t%s,%s,0x%h",pc, ir[31:0], register_file[ir[11:7]], register_file[ir[19:15]], $signed(ir[24:20]));
						3'b101:
							if(ir[31:25] == 7'b0000000) begin
								$display("  %0h:\t%h\tsrli\t%s,%s,0x%h", pc, ir[31:0], register_file[ir[11:7]], register_file[ir[19:15]], $signed(ir[24:20])) ;
							end
							else if(ir[31:25] == 7'b0100000) begin
								$display("  %0h:\t%h\tsrai\t%s,%s,0x%h", pc, ir[31:0], register_file[ir[11:7]], register_file[ir[19:15]], $signed(ir[24:20])) ;
							end
					endcase
				7'b0100011:
					case(ir[14:12]) 
						3'b000: 
							$display("  %0h:\t%h\tsb\t%s,%0d(%s)", pc, ir[31:0], register_file[ir[24:20]], compute_offset(ir[31:25], ir[11:7]), register_file[ir[19:15]]);
						3'b001: 
							$display("  %0h:\t%h\tsh\t%s,%0d(%s)", pc, ir[31:0], register_file[ir[24:20]], compute_offset(ir[31:25], ir[11:7]), register_file[ir[19:15]]);
						3'b010:	
							$display("  %0h:\t%h\tsw\t%s,%0d(%s)", pc, ir[31:0], register_file[ir[24:20]], compute_offset(ir[31:25], ir[11:7]), register_file[ir[19:15]]);
						3'b011:	
							$display("  %0h:\t%h\tsd\t%s,%0d(%s)", pc, ir[31:0], register_file[ir[24:20]], compute_offset(ir[31:25], ir[11:7]), register_file[ir[19:15]]);
						default:
							$display("wrong opcode format");
					endcase
				7'b0110011:
					case(ir[14:12])
						3'b000:
							if(ir[31:25] == 7'b0000000) begin
								$display("  %0h:\t%h\tadd\t%s,%s,%s", pc, ir[31:0], register_file[ir[11:7]], register_file[ir[19:15]], register_file[ir[24:20]]) ;
							end
							else if(ir[31:25] == 7'b0100000) begin
								if(ir[19:15]==5'd0) begin
									$display("  %0h:\t%h\tneg\t%s,%s", pc, ir, register_file[ir[11:7]], register_file[ir[24:20]]);
								end else
								begin
									$display("  %0h:\t%h\tsub\t%s,%s,%s", pc, ir, register_file[ir[11:7]], register_file[ir[19:15]], register_file[ir[24:20]]);
								end
							end
							else if(ir[31:25] == 7'b0000001) begin
								$display("  %0h:\t%h\tmul\t%s,%s,%s", pc, ir, register_file[ir[11:7]], register_file[ir[19:15]], register_file[ir[24:20]]) ;
							end
						3'b001:
							if(ir[31:25] == 7'b0000000) begin
								$display("  %0h:\t%h\tsll\t%s,%s,%s", pc, ir, register_file[ir[11:7]], register_file[ir[19:15]], register_file[ir[24:20]]) ;
							end
							else if(ir[31:25] == 7'b0000001) begin
								$display("  %0h:\t%h\tmulh\t%s,%s,%s", pc, ir, register_file[ir[11:7]], register_file[ir[19:15]], register_file[ir[24:20]]) ;
							end
						3'b010:
							if(ir[31:25] == 7'b0000000) begin
								if(ir[19:15] == 5'd0) begin
									$display("  %0h:\t%h\tsgtz\t%s,%s", pc, ir, register_file[ir[11:7]], register_file[ir[24:20]]) ;
								end else if(ir[24:20] == 5'd0) begin
									$display("  %0h:\t%h\tsltz\t%s,%s", pc, ir, register_file[ir[11:7]], register_file[ir[19:15]]) ;
								end else begin
									$display("  %0h:\t%h\tslt\t%s,%s,%s", pc, ir, register_file[ir[11:7]], register_file[ir[19:15]], register_file[ir[24:20]]) ;
								end
							end
							else if(ir[31:25] == 7'b0000001) begin
								$display("  %0h:\t%h\tmulhsu\t%s,%s,%s", pc, ir, register_file[ir[11:7]], register_file[ir[19:15]], register_file[ir[24:20]]) ;
							end
						3'b011:
							if(ir[31:25] == 7'b0000000) begin
								if(ir[19:15] == 5'd0) begin 
									$display("  %0h:\t%h\tsnez\t%s,%s", pc, ir, register_file[ir[11:7]], register_file[ir[24:20]]) ;
								end else begin
									$display("  %0h:\t%h\tsltu\t%s,%s,%s", pc, ir, register_file[ir[11:7]], register_file[ir[19:15]], register_file[ir[24:20]]) ;
								end
							end
							else if(ir[31:25] == 7'b0000001) begin
								$display("  %0h:\t%h\tmulhu\t%s,%s,%s", pc, ir, register_file[ir[11:7]], register_file[ir[19:15]], register_file[ir[24:20]]) ;
							end
						3'b100:
							if(ir[31:25] == 7'b0000000) begin
								$display("  %0h:\t%h\txor\t%s,%s,%s", pc, ir, register_file[ir[11:7]], register_file[ir[19:15]], register_file[ir[24:20]]) ;
							end
							else if(ir[31:25] == 7'b0000001) begin
								$display("  %0h:\t%h\tdiv\t%s,%s,%s", pc, ir, register_file[ir[11:7]], register_file[ir[19:15]], register_file[ir[24:20]]) ;
							end
						3'b101:
							if(ir[31:25] == 7'b0000000) begin
								$display("  %0h:\t%h\tsrl\t%s,%s,%s", pc, ir, register_file[ir[11:7]], register_file[ir[19:15]], register_file[ir[24:20]]) ;
							end else if(ir[31:25] == 7'b0100000) begin
								$display("  %0h:\t%h\tsra\t%s,%s,%s", pc, ir, register_file[ir[11:7]], register_file[ir[19:15]], register_file[ir[24:20]]) ;
							end else if(ir[31:25] == 7'b0000001) begin
								$display("  %0h:\t%h\tdivu\t%s,%s,%s", pc, ir, register_file[ir[11:7]], register_file[ir[19:15]], register_file[ir[24:20]]) ;
							end
						3'b110:
							if(ir[31:25] == 7'b0000000) begin
								$display("  %0h:\t%h\tor\t%s,%s,%s", pc, ir, register_file[ir[11:7]], register_file[ir[19:15]], register_file[ir[24:20]]) ;
							end else if(ir[31:25] == 7'b0000001 ) begin
								$display("  %0h:\t%h\trem\t%s,%s,%s", pc, ir, register_file[ir[11:7]], register_file[ir[19:15]], register_file[ir[24:20]]) ;
							end
						3'b111:
							if(ir[31:25] == 7'b0000000) begin
								$display("  %0h:\t%h\tand\t%s,%s,%s", pc, ir, register_file[ir[11:7]], register_file[ir[19:15]], register_file[ir[24:20]]) ;
							end
							else if(ir[31:25] == 7'b0000001) begin
								$display("  %0h:\t%h\tremu\t%s,%s,%s", pc, ir, register_file[ir[11:7]], register_file[ir[19:15]], register_file[ir[24:20]]) ;
							end
					endcase
				7'b1100011:
					// introduce immediate for ease of computation //
					begin
						imm[0] = 0;
						imm[4:1] = ir[11:8];
						imm[10:5] = ir[30:25];
						imm[11] = ir[7];
						imm[12] = ir[31];
						imm = {{51{imm[12]}}, imm[12:0]};
					
						case(ir[14:12])
							3'b000: 
								if(ir[24:20] == 5'd0) begin
									$display("  %0h:\t%h\tbeqz\t%s,0x%0h", pc, ir[31:0], register_file[ir[19:15]], pc+imm) ;
								end else begin
									$display("  %0h:\t%h\tbeq\t%s,%s,0x%0h", pc, ir[31:0], register_file[ir[19:15]], register_file[ir[24:20]],
											pc+imm) ;
								end
							3'b001:	
								if(ir[24:20] == 5'd0) begin
									$display("  %0h:\t%h\tbnez\t%s,0x%0h", pc, ir[31:0], register_file[ir[19:15]], pc+imm) ;
								end else begin
									$display("  %0h:\t%h\tbne\t%s,%s,0x%0h", pc, ir[31:0], register_file[ir[19:15]], register_file[ir[24:20]],
											pc+imm) ;
								end
							3'b100: 
								if(ir[24:20] == 5'd0) begin
									$display("  %0h:\t%h\tbltz\t%s,0x%0h", pc, ir[31:0], register_file[ir[19:15]], pc+imm) ;
								end else begin
									$display("  %0h:\t%h\tblt\t%s,%s,0x%0h", pc, ir[31:0], register_file[ir[19:15]], register_file[ir[24:20]],
											pc+imm) ;
								end
							3'b101: 
								if(ir[24:20] == 5'd0) begin
									$display("  %0h:\t%h\tbgez\t%s,0x%0h", pc, ir[31:0], register_file[ir[19:15]], pc+imm) ;
								end else begin
									$display("  %0h:\t%h\tbge\t%s,%s,0x%0h", pc, ir[31:0], register_file[ir[19:15]], register_file[ir[24:20]],
											pc+imm) ;
								end
							3'b110: 
								$display("  %0h:\t%h\tbltu\t%s,%s,0x%0h", pc, ir[31:0], register_file[ir[19:15]], register_file[ir[24:20]],
											pc+imm) ;
							3'b111:
								$display("  %0h:\t%h\tbgeu\t%s,%s,0x%0h", pc, ir[31:0], register_file[ir[19:15]], register_file[ir[24:20]],
											pc+imm) ;
							default:
								$display("wrong opcode format");
						endcase
					end
				7'b0000011:
					case(ir[14:12])
						3'b000:
							$display("  %0h:\t%h\tlb\t%s,%0d(%s)", pc, ir[31:0], register_file[ir[11:7]], $signed(ir[31:20]), register_file[ir[19:15]]) ;
						3'b001:
							$display("  %0h:\t%h\tlh\t%s,%0d(%s)", pc, ir[31:0], register_file[ir[11:7]], $signed(ir[31:20]), register_file[ir[19:15]]) ;
						3'b010: 
							$display("  %0h:\t%h\tlw\t%s,%0d(%s)", pc, ir[31:0], register_file[ir[11:7]], $signed(ir[31:20]), register_file[ir[19:15]]) ;
						3'b100: 
							$display("  %0h:\t%h\tlbu\t%s,%0d(%s)", pc, ir[31:0], register_file[ir[11:7]], $signed(ir[31:20]), register_file[ir[19:15]]) ;
						3'b101:	
							$display("  %0h:\t%h\tlhu\t%s,%0d(%s)", pc, ir[31:0], register_file[ir[11:7]], $signed(ir[31:20]), register_file[ir[19:15]]) ;
						3'b110:
							$display("  %0h:\t%h\tlwu\t%s,%0d(%s)", pc, ir[31:0], register_file[ir[11:7]], $signed(ir[31:20]), register_file[ir[19:15]]) ;
						3'b011: 
						    $display("  %0h:\t%h\tld\t%s,%0d(%s)", pc, ir[31:0], register_file[ir[11:7]], $signed(ir[31:20]), register_file[ir[19:15]]) ;
						default:
							$display("wrong opcode format");
					endcase
				7'b0111011:
					case(ir[14:12])
						3'b000:
							if(ir[31:25] == 7'b0000000) begin
								$display("  %0h:\t%h\taddw\t%s,%s,%s", pc, ir[31:0], register_file[ir[11:7]], register_file[ir[19:15]], register_file[ir[24:20]]) ;
							end
							else if(ir[31:25] == 7'b0100000) begin
								if(ir[19:15] == 5'd0) begin
									$display("  %0h:\t%h\tnegw\t%s,%s", pc, ir[31:0], register_file[ir[11:7]], register_file[ir[24:20]]) ;
								end else begin
									$display("  %0h:\t%h\tsubw\t%s,%s,%s", pc, ir[31:0], register_file[ir[11:7]], register_file[ir[19:15]], register_file[ir[24:20]]) ;
								end
							end
							else if(ir[31:25] == 7'b0000001) begin
								$display("  %0h:\t%h\tmulw\t%s,%s,%s", pc, ir[31:0], register_file[ir[11:7]], register_file[ir[19:15]], register_file[ir[24:20]]) ;
							end
						3'b001:
							$display("  %0h:\t%h\tsllw\t%s,%s,%s", pc, ir[31:0], register_file[ir[11:7]], register_file[ir[19:15]], register_file[ir[24:20]]) ;
						3'b101:
							if(ir[31:25] == 7'b0000000) begin
								$display("  %0h:\t%h\tsrlw\t%s,%s,%s", pc, ir[31:0], register_file[ir[11:7]], register_file[ir[19:15]], register_file[ir[24:20]]) ;
							end
							else if(ir[31:25] == 7'b0100000) begin
								$display("  %0h:\t%h\tsraw\t%s,%s,%s", pc, ir[31:0], register_file[ir[11:7]], register_file[ir[19:15]], register_file[ir[24:20]]) ;
							end
							else if(ir[31:25] == 7'b0000001) begin
								$display("  %0h:\t%h\tdivuw\t%s,%s,%s", pc, ir[31:0], register_file[ir[11:7]], register_file[ir[19:15]], register_file[ir[24:20]]) ;
							end
						3'b100:
							$display("  %0h:\t%h\tdivw\t%s,%s,%s", pc, ir[31:0], register_file[ir[11:7]], register_file[ir[19:15]], register_file[ir[24:20]]) ;
						3'b110:
							$display("  %0h:\t%h\tremw\t%s,%s,%s", pc, ir[31:0], register_file[ir[11:7]], register_file[ir[19:15]], register_file[ir[24:20]]) ;
						3'b111:
							$display("  %0h:\t%h\tremuw\t%s,%s,%s", pc, ir[31:0], register_file[ir[11:7]], register_file[ir[19:15]], register_file[ir[24:20]]) ;
						default:
							$display("wrong opcode format") ;
					endcase
				7'b0011011:
					case(ir[14:12])
						3'b000:
							$display("  %0h:\t%h\taddiw\t%s,%s,%0d", pc, ir[31:0], register_file[ir[11:7]], register_file[ir[19:15]], $signed(ir[31:20]));
						3'b001:
							$display("  %0h:\t%h\tslliw\t%s,%s,%0d", pc, ir[31:0], register_file[ir[11:7]], register_file[ir[19:15]], $signed(ir[31:20]));
						3'b101:
							if(ir[31:25] == 7'b0000000) begin
								$display("  %0h:\t%h\tsrliw\t%s,%s,%0d", pc, ir[31:0], register_file[ir[11:7]], register_file[ir[19:15]], $signed(ir[31:20]));
							end
							else if(ir[31:25] == 7'b0100000) begin
								$display("  %0h:\t%h\tsraiw\t%s,%s,%0d", pc, ir[31:0], register_file[ir[11:7]], register_file[ir[19:15]], $signed(ir[31:20]));
							end
					endcase
				7'b0110111:
					$display("  %0h:\t%h\tlui\t%s,0x%0h", pc, ir[31:0], register_file[ir[11:7]], $signed(ir[31:12]));
				7'b0010111:
					$display("  %0h:\t%h\tauipc\t%s,0x%0h", pc, ir[31:0], register_file[ir[11:7]], $signed(ir[31:12]));
				7'b1101111:	
					// compute immediate as it is complicated //
					begin
						imm[0] = 0;
						imm[10:1] = ir[30:21];
						imm[11] = ir[20];
						imm[20] = ir[31];
						imm[19:12] = ir[19:12];
					// sign extension
						imm = {{44{imm[20]}}, imm[19:0]};
					
						if(ir[11:7] == 5'd0) begin
							$display("  %0h:\t%h\tj\t0x%0h", pc, ir[31:0], pc + imm ) ;  
						end else if(ir[11:7] == 5'd1) begin
							$display("  %0h:\t%h\tjal\t0x%0h", pc, ir[31:0], pc + imm ) ; 
						end
					end			
				7'b1100111:
					if(ir[11:7] == 5'd0 && ir[19:15] == 5'd1 && ir[31:20] == 12'd0) begin
						$display("  %0h:\t%h\tret", pc, ir[31:0]);
					end else if(ir[11:7] == 5'd0 && ir[31:20] == 12'd0) begin
						$display("  %0h:\t%h\tjr\t%s",pc, ir[31:0], register_file[ir[19:15]]);
					end else if(ir[11:7] == 5'd1 && ir[31:20] == 12'd0) begin
						$display("  %0h:\t%h\tjalr\t%s",pc, ir[31:0], register_file[ir[19:15]]);
					end 
				
				endcase
			ir = ir >> 32;
			pc += 4;
		end
	end
endfunction
	
/**************************************************************************************************************************************/
	

