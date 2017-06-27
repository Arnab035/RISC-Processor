`include "Sysbus.defs"

module decode1
#(
	BUS_DATA_WIDTH = 64
)
(
	input clk,
	input [BUS_DATA_WIDTH-1 : 0] pc,  // pc must go to execute stage
	input [31:0] outIns,

	// input decode_en, 
	// TODO : verify what inputs come from wb stage //
	/*
	input inRegWrite,
	input inCtrlMux,    
	*/

	output outBranch,
	output outPCSrc,
	output outMemRead,
	output outMemWrite,
	output outRegWrite,       
	output outMemOrReg,
	
	output [5:0] outAluControl,   
	output [BUS_DATA_WIDTH-1:0] outReadData1,  
	output [BUS_DATA_WIDTH-1:0] outReadData2,  
	output [4:0] outDestRegister,
	output [BUS_DATA_WIDTH-1:0] outImm,   
	
	
	output [4:0] outRegisterRs,  
	output [4:0] outRegisterRt,	 
	output [BUS_DATA_WIDTH-1 : 0] outPc   
);

logic [BUS_DATA_WIDTH-1 : 0] mem[31:0];   
logic [BUS_DATA_WIDTH-1 : 0] readData1, readData2, _pc;

logic [4:0] destRegister;
logic [4:0] registerRs;
logic [4:0] registerRt;

logic [BUS_DATA_WIDTH-1:0] imm;

logic pcSrc, regWrite;

logic memWrite, memRead, branch, memOrReg;

logic [5:0] aluControl;

// TODO: branch instructions/jump instructions and ins like li/mov 

always @ (posedge clk) begin 
	_pc <= pc;
	pcSrc <= 0;          // this only becomes 1 when there is a branch taken
	if(0) begin          // TODO : inCtrlMux will come here
			// pass  - all control lines are 0.
	end else begin
			// stores
			7'b0100011:
				begin
					branch <= 0;
					memRead <= 0;
					memWrite <= 1;
					memOrReg <= 0; // TODO : does it matter here
					readData1 <= mem[outIns[19:15]];
					destRegister <= 0;
					imm <= {{52{outIns[31]}} , outIns[31:20]};
					readData2 <= mem[outIns[24:20]];
					registerRs <= outIns[19:15];
					registerRt <= outIns[24:20];   // contains the data to be loaded into memory
					case(outIns[14:12]) 
						3'b000: 
							// sb
							aluControl <= 6'b000001;   // addi
						3'b001: 
							// sh
							aluControl <= 6'b000001;
						3'b010:	
							// sw
							aluControl <= 6'b000001;
						3'b011:	
							// sd
							aluControl <= 6'b000001;
					endcase
				end
			// loads
			7'b0000011:
				begin
					branch <= 0;
					memRead <= 1;
					memWrite <= 0;
					memOrReg <= 1; // go from memory
					readData1 <= mem[outIns[19:15]];
					destRegister <= outIns[11:7];
					imm <= {{52{outIns[31]}} , outIns[31:20]};
					readData2 <= mem[outIns[24:20]];
					registerRs <= outIns[19:15];
					registerRt <= outIns[24:20];
					case(outIns[14:12])
						3'b000:
							// lb
							aluControl <= 6'b000001;
						3'b001:
							aluControl <= 6'b000001;
							//lh
						3'b010:
							// lw
							aluControl <= 6'b000001;
						3'b100: 
							// lbu
							aluControl <= 6'b000001;
						3'b101:	
							// lhu
							aluControl <= 6'b000001;
						3'b110:
							// lwu
							aluControl <= 6'b000001;
						3'b011: 
							// ld
							aluControl <= 6'b000001;
						default:
							$display("wrong opcode format");
					endcase
				end           
			// add-sub
			7'b0110011:
				begin
					regWrite <= 1;
					readData1 <= mem[outIns[19:15]];
					readData2 <= mem[outIns[24:20]];
					destRegister <= outIns[11:7];
					imm <= 0;
					branch <= 0;
					memRead <= 0;
					memWrite <= 0;
					memOrReg <= 0;
					registerRs <= outIns[19:15];
					registerRt <= outIns[24:20];
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
					readData1 <= mem[outIns[19:15]];
					readData2 <= mem[outIns[24:20]];
					destRegister <= outIns[11:7];
					imm <= 0;
					regWrite <= 1;
					branch <= 0;
					memRead <= 0;
					memWrite <= 0;
					memOrReg <= 0;
					registerRs <= outIns[19:15];
					registerRt <= outIns[24:20];
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
					readData1 <= mem[outIns[19:15]];
					readData2 <= 0;
					destRegister <= outIns[11:7]; 
					imm <= {{52{outIns[31]}} , outIns[31:20]}; // sign-extended immediate
					regWrite <= 1;
					branch <= 0;
					memRead <= 0;
					memWrite <= 0;
					memOrReg <= 0;
					registerRs <= outIns[19:15];
					registerRt <= outIns[24:20];
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
			default:
				begin
					aluControl <= 0;
					regWrite <= 0;
					readData1 <= 0;
					readData2 <= 0;
					destRegister <= 0;
					imm <= 0;
					branch <= 0;
					memRead <= 0;
					memWrite <= 0;
					memOrReg <= 0;
					registerRs <= 0;
					registerRt <= 0;
				end
		endcase
	end
end
  
assign outPc = _pc;
assign outAluControl = aluControl;
assign outReadData1 = readData1;
assign outReadData2 = readData2;
assign outMemOrReg = memOrReg;
assign outBranch = branch;
assign outPCSrc = pcSrc;
assign outMemRead = memRead;
assign outMemWrite = memWrite;
assign outDestRegister = destRegister;
assign outRegisterRs = registerRs;
assign outRegisterRt = registerRt;  

assign outRegWrite = regWrite;

assign outImm = imm;

endmodule
