// 2nd stage of the pipeline - must contain the register file definition as well
// added alucontrol as an additional output because the instruction format does not match MIPS

`include "Sysbus.defs"

module decode1
# (
	BUS_DATA_WIDTH = 64
)
(
	input clk,
	input [BUS_DATA_WIDTH-1 : 0] pc,
	input [31:0] outIns,
	input decode_en, 
	input inRegWrite,  // regWrite input as well
	input end_of_cycle,
	
	// output all the important signals from here-- 8 signals in total
	output outBranch,
	output outAluSrc,      // either read from reg2 or sign-extended mem address
	output outPCSrc,
	output outMemRead,
	output outMemWrite,
	output outRegWrite,       // whether writeback to be done
	output outMemOrReg,       // whether memory or register value to be written back
	
	output [5:0] outAluControl,   // which ALU operation to perform
	output [BUS_DATA_WIDTH-1:0] outReadData1,  // read data from register 1
	output [BUS_DATA_WIDTH-1:0] outReadData2,  // read data from register 2
	output [4:0] outDestRegister,
	output [BUS_DATA_WIDTH-1:0] outImm,           // sign-extended imm
);

reg [BUS_DATA_WIDTH-1 : 0] mem[31:0];   // register file definition

reg [BUS_DATA-WIDTH-1 : 0] readData1, readData2;

reg [4:0] destRegister;

reg [BUS_DATA_WIDTH-1:0] imm;
logic aluSrc = 0;
logic out_reg_file_en;
reg [BUS_DATA_WIDTH-1:0] _pc;

logic pcSrc, regWrite;

logic memWrite, memRead, branch;

reg [5:0] aluControl;

// for branch instructions try to form the immediate

always @ (posedge clk) 
	if(decode_en) begin
		_pc <= pc;
		pcSrc <= 0;          // this only becomes 1 when there is a branch taken
		case(outIns[6:0])           
			7'b0010011:
				begin
					aluSrc <= 1; // immediate
					readData1 <= mem[outIns[19:15]];
					readData2 <= 0;
					destRegister <= outIns[11:7];
					regWrite <= 1;
					imm <= {{52{outIns[31]}} , outIns[31:20]};  // sign-extended immediate sent
					case(outIns[14:12])
						/*
						3'b000:
							if(outIns[31:20] == 11'd0 && outIns[11:7] == 5'd0 && outIns[19:15] == 5'd0) begin
								//nop;
							end
							else if(outIns[31:20] == 11'd0 && outIns[19:15] == 5'd0) begin
								//$display("%h\tli,0", outIns[31:0]);
							end else if(outIns[31:20] == 11'd0) begin
								//$display("%h\tmv",outIns[31:0]);
							end else begin
								alu_control <= 6'b000001;
							end
						*/
						3'b010:
							aluControl <= 6'b000010;   // slti
						3'b011:q
							if(outIns[31:20] == 11'd1) begin //seqz
								aluControl <= 6'b000011;
							end else begin     //sltiu
								aluControl <= 6'b000011;
							end
						3'b100:
							if(outIns[31:20] == -11'd1) begin
								// not
								aluControl <= 6'b000100;
							end else begin // xori
								aluControl <= 6'b000100;
							end
						3'b110:
							aluControl <= 6'b000101;  // ori
						3'b111:
							aluControl <= 6'b000110;   // andi
						3'b001:
							aluControl <= 6'b000111;     // slli
						3'b101:
							if(outIns[31:25] == 7'b0000000) begin
								aluControl <= 6'b001000;
								// srli
							end
							else if(outIns[31:25] == 7'b0100000) begin
								aluControl <= 6'b001001;
								// srai
							end
					endcase
				end
			// store instructions here -- handled later !!
			7'b0100011:
				memWrite <= 1;
				regWrite <= 0;
				case(ir[14:12]) 
					3'b000: 
						// sb
						$display("  %0h:\t%h\tsb\t%s,%0d(%s)", pc, ir[31:0], register_file[ir[24:20]], compute_offset(ir[31:25], ir[11:7]), register_file[ir[19:15]]);
					3'b001: 
						// sh
						$display("  %0h:\t%h\tsh\t%s,%0d(%s)", pc, ir[31:0], register_file[ir[24:20]], compute_offset(ir[31:25], ir[11:7]), register_file[ir[19:15]]);
					3'b010:	
						// sw
						$display("  %0h:\t%h\tsw\t%s,%0d(%s)", pc, ir[31:0], register_file[ir[24:20]], compute_offset(ir[31:25], ir[11:7]), register_file[ir[19:15]]);
					3'b011:	
						// sd
						$display("  %0h:\t%h\tsd\t%s,%0d(%s)", pc, ir[31:0], register_file[ir[24:20]], compute_offset(ir[31:25], ir[11:7]), register_file[ir[19:15]]);
					default:
						$display("wrong opcode format");
				endcase
			// add-sub instruction types
			7'b0110011:
				begin
					aluSrc <= 0;   // 0 means it comes from register
					regWrite <= 1;
					readData1 <= mem[outIns[19:15]];
					readData2 <= mem[outIns[24:20]];
					destRegister <= outIns[11:7];
					imm <= 0;
					case(outIns[14:12])
						3'b000:
							if(outIns[31:25] == 7'b0000000) begin
								aluControl <= 6'b001100;
								// add
							end else if(outIns[31:25] == 7'b0100000) begin
								if(outIns[19:15]==5'd0) begin
									aluControl <= 6'b001101;
									// neg
								end else begin
									aluControl <= 6'b001101;
									// sub
								end
							end
							else if(outIns[31:25] == 7'b0000001) begin
								aluControl <= 6'b011111;
								// mul
							end
						3'b001:
							if(outIns[31:25] == 7'b0000000) begin
								aluControl <= 6'b001110;
								// sll
							end
							else if(outIns[31:25] == 7'b0000001) begin
								aluControl <= 6'b100000;
								// mulh
							end
						3'b010:
							if(outIns[31:25] == 7'b0000000) begin
								if(outIns[19:15] == 5'd0) begin
									aluControl <= 6'b001111;
									// sgtz
								end else if(outIns[24:20] == 5'd0) begin
									aluControl <= 6'b001111;
									// sltz
								end else begin
									aluControl <= 6'b001111;
									// slt
								end
							end else if(outIns[31:25] == 7'b0000001) begin
								aluControl <= 6'b100001;
								// mulhsu
							end
						3'b011:
							if(outIns[31:25] == 7'b0000000) begin
								if(outIns[19:15] == 5'd0) begin
									aluControl <= 6'b010000;
									// snez
								end else begin
									aluControl <= 6'b010000;
									// sltu
								end
							end
							else if(outIns[31:25] == 7'b0000001) begin
								aluControl <= 6'b100010;
								// mulhu
							end
						3'b100:
							if(outIns[31:25] == 7'b0000000) begin
								aluControl <= 6'b010001;
								// xor
							end
							else if(outIns[31:25] == 7'b0000001) begin
								aluControl <= 6'b100011;
								// div
							end
						3'b101:
							if(outIns[31:25] == 7'b0000000) begin
								aluControl <= 6'b010010;
								// srl
							end else if(outIns[31:25] == 7'b0100000) begin
								aluControl <= 6'b010011;
								// sra
							end else if(outIns[31:25] == 7'b0000001) begin
								aluControl <= 6'b100100;
								// divu
							end
						3'b110:
							if(outIns[31:25] == 7'b0000000) begin
								aluControl <= 6'b010100;
								// or
							end else if(outIns[31:25] == 7'b0000001 ) begin
								aluControl <= 6'b100101;
								// rem
							end
						3'b111:
							if(outIns[31:25] == 7'b0000000) begin
								aluControl <= 6'b010101;
								// and
							end
							else if(outIns[31:25] == 7'b0000001) begin
								aluControl <= 6'b100110;
								// remu
							end
							
					endcase
				end
			7'b0111011:
				begin
					aluSrc <= 0;        // non-immediate
					readData1 <= mem[outIns[19:15]];
					readData2 <= mem[outIns[24:20]];
					destRegister <= outIns[11:7];
					imm <= 0;
					regWrite <= 1;
					case(outIns[14:12])
						3'b000:
							if(outIns[31:25] == 7'b0000000) begin
								aluControl <= 6'b011010;
								//addw 
							end
							else if(outIns[31:25] == 7'b0100000) begin
								aluControl <= 6'b011011;
								if(outIns[19:15] == 5'd0) begin
									readData1 <= 0;
								end else begin
									// subw
								end
							end
							else if(outIns[31:25] == 7'b0000001) begin
								aluControl <= 6'b100111;
								// mulw
							end
						3'b001:
							aluControl <= 6'b011100;
							// sllw
						3'b101:
							if(outIns[31:25] == 7'b0000000) begin
								aluControl <= 6'b011101;
								//srlw
							end
							else if(outIns[31:25] == 7'b0100000) begin
								aluControl <= 6'b011110;
								//sraw 
							end
							else if(outIns[31:25] == 7'b0000001) begin
								aluControl <= 6'b101001;
								//divuw
							end
						3'b100:
							aluControl <= 6'b101000;
							//divw
						3'b110:
							aluControl <= 6'b101010;
							// remw
						3'b111:
							aluControl <= 6'b101011;
							// remuw
						default:
							aluControl <= 0;   // not an ALU operation 
					endcase
				end
			7'b0011011:
				begin
					aluSrc <= 1;
					readData1 <= mem[outIns[19:15]];
					readData2 <= 0;
					destRegister <= outIns[11:7]; 
					imm <= {{52{outIns[31]}} , outIns[31:20]}; // sign-extended immediate
					regWrite <= 1;
					case(outIns[14:12])
						3'b000:
							aluControl <= 6'b010110;
							// addiw
						3'b001:
							aluControl <= 6'b010111;
							// slliw
						3'b101:
							if(outIns[31:25] == 7'b0000000) begin
								aluControl <= 6'b011000;
								// srliw
							end
							else if(outIns[31:25] == 7'b0100000) begin
								aluControl <= 6'b011001;
								// sraiw
							end
						default:
							aluControl <= 0; // some other operation
					endcase
				end
			7'b1100011:
					// introduce immediate for ease of computation //
					// branch instructions here
					begin
						imm <= {{51{outIns[31]}}, outIns[7], outIns[30:25], outIns[11:8], 0};
						branch <= 1;
						aluSrc <= 0;
						readData1 <= mem[outIns[19:15]];
						readData2 <= mem[outIns[24:20]];
						regWrite <= 0;
						case(ir[14:12])
							3'b000: 
								if(outIns[24:20] == 5'd0) begin
									// beqz
									aluControl <= 6'b001101;   // subtract
								end else begin
									// beq
									aluControl <= 6'b001101;
								end
							3'b001:	
								if(ir[24:20] == 5'd0) begin
									// bnez
									aluControl <= 6'b001101;
									
								end else begin
									aluControl <= 6'b001101;
								end
							3'b100: 
								if(ir[24:20] == 5'd0) begin
									aluControl <= 6'b001101;  // subtract suffices
								end else begin
									aluControl <= 6'b001101;
								end
							3'b101: 
								if(ir[24:20] == 5'd0) begin
									// bgez
									aluControl <= 6'b001101;
								end else begin
									aluControl <= 6'b001101;
								end
							3'b110: 
								aluControl <= 6'b001101;
							3'b111:
								aluControl <= 6'b001101;
							default:
								aluControl <= 0;
						endcase
					end
			default:
				begin
					alu_control <= 0;
					addressA <= 0;
					addressB <= 0;
					addressC <= 0;
					muxB_control <= 0;
					imm <= 0;
				end
		endcase
		out_reg_file_en <= 1;
	end
	else begin
		out_reg_file_en <= 0;
	end
  

assign outPc = _pc;

assign outAluControl = aluControl;
assign outReadData1 = readData1;
assign outReadData2 = readData2;
assign out_addressC = addressC;
assign out_imm = imm;
assign out_muxB_control = muxB_control;
assign reg_file_en = out_reg_file_en;

endmodule