module decode1
#(
	BUS_DATA_WIDTH = 64
)
(
	input clk,
	input reset,
	input [BUS_DATA_WIDTH-1 : 0] pc, 
	input [31:0] outIns,
	input [63:0] inStackPtr,
	input inRegWrite,
	input [4:0] inDestRegister,
	input [BUS_DATA_WIDTH-1:0] inRegData,    
	input inFlushFromEcall,
	input inFlushFromJump,
	input in_stall_from_dcache,
	input in_stall_from_icache,
	input in_stall_from_hazardunit,
	input [4:0] inDestRegisterFromEcall,
	input [BUS_DATA_WIDTH-1:0] inRegDataFromEcall,
	input inRegWriteFromEcall,
	input in_bp_miss,
	input in_bp_is_branch_taken,
	output outBranch,
	output outPCSrc,
	output outMemRead,
	output outMemWrite,
	output outRegWrite,       
	output outMemOrReg,
	output outJalr,
	output outJump,
	output outStall,	
	output [5:0] outAluControl,   
	output [BUS_DATA_WIDTH-1:0] outReadData1,  
	output [BUS_DATA_WIDTH-1:0] outReadData2,  
	output [4:0] outDestRegister,
	output [BUS_DATA_WIDTH-1:0] outImm,   
	output [4:0] outRegisterRs,  
	output [4:0] outRegisterRt,	 
	output [BUS_DATA_WIDTH-1 : 0] outPc,
	output [2:0] outBranchType,
	output [2:0] outLoadType,
	output [1:0] outStoreType,
	output outEcall,
	output out_bp_miss,
	output out_bp_is_branch_taken,
	// ecall registers
	output [63:0] outMem10,
	output [63:0] outMem11,
	output [63:0] outMem12,
	output [63:0] outMem13,
	output [63:0] outMem14,
	output [63:0] outMem15,
	output [63:0] outMem16,
	output [63:0] outMem17 ,
	output [63:0] outEpc   // handle ecalls 
);

`include "Sysbus.defs"

logic [BUS_DATA_WIDTH-1 : 0] mem[31:0];  

always_comb begin
	if(reset) begin
    	mem[2] = inStackPtr;
    	mem[0] = 0;
    end
end

logic [BUS_DATA_WIDTH-1 : 0] readData1, readData2, _pc, epc;

logic [4:0] destRegister;
logic [4:0] registerRs;
logic [4:0] registerRt;


logic [1:0] storeType;
logic [2:0] loadType, branchType;

logic [BUS_DATA_WIDTH-1:0] imm;

logic pcSrc, regWrite, jump, ecall;
logic jalr=0;
logic memWrite, memRead, branch, memOrReg;

logic [5:0] aluControl;

always_ff @ (posedge clk) begin
	if(!in_stall_from_dcache && !in_stall_from_icache) begin
		if(inRegWrite) begin
			mem[inDestRegister] <= inRegData;
			//$display("Data 0x%x written to register 0x%x", inRegData, inDestRegister);
		end
	end
end

always_ff @ (posedge clk) begin
	if(!in_stall_from_dcache && !in_stall_from_icache) begin
		if(inRegWriteFromEcall) begin
			mem[inDestRegisterFromEcall] <= inRegDataFromEcall;
		end
	end
end

logic bp_miss, bp_is_branch_taken;

always_ff @ (posedge clk) begin
	if(!in_stall_from_dcache && !in_stall_from_icache) begin 
		if(inFlushFromJump || inFlushFromEcall || in_stall_from_hazardunit) begin          
			regWrite <= 0;
			branch <= 0;
			memRead <= 0;
			memWrite <= 0;
			memOrReg <= 0;
			aluControl <= 0;
			readData1 <= 0;
			readData2 <= 0;
			destRegister <= 0;
			imm <= 0;
			registerRs <= 0;
			registerRt <= 0;
			jump <= 0;
			jalr <= 0;
			ecall <= 0;
			storeType <= 0;
			loadType <= 0;
			branchType <= 0;
			_pc <= 0;
			epc <= 0;
			pcSrc <= 0;
			bp_is_branch_taken <= 0;
			bp_miss <= 0;
		end else begin
			_pc <= pc;
			pcSrc <= 0;          // this only becomes 1 when there is a branch taken
			bp_miss <= in_bp_miss;
			bp_is_branch_taken <= in_bp_is_branch_taken;
			case(outIns[6:0])
				// lui
				7'b0110111:
					begin
						readData1 <= 0;
						readData2 <= 0;
						destRegister <= outIns[11:7];
						branch <= 0;
						jump <= 0;
						jalr <= 0;
						ecall <= 0;
						memRead <= 0;
						memWrite <= 0;
						imm[11:0] <= 0;
						imm[63:12] <= {{32{outIns[31]}}, outIns[31:12]};
						regWrite <= 1;
						aluControl <= 0; 
						memOrReg <= 0;
						registerRs <= 0;
						registerRt <= 0;
						storeType <= 0;
						loadType <= 0;
						branchType <= 0;
						epc <= 0; 
					end
				//auipc
				7'b0010111:
					begin
						readData1 <= pc;
						readData2 <= 0;
						destRegister <= outIns[11:7];
						branch <= 0;
						jump <= 0;
						jalr <= 0;
						ecall <= 0;
						memRead <= 0;
						memWrite <= 0;
						imm[11:0] <= 0;
						imm[63:12] <= {{32{outIns[31]}}, outIns[31:12]};
						regWrite <= 1;
						aluControl <= 6'b000001;
						memOrReg <= 0;
						registerRs <= 0;
						registerRt <= 0;
						storeType <= 0;
						loadType <= 0;
						branchType <= 0;
						epc <= 0;
					end
				// ECALL
				7'b1110011:
					begin
						readData1 <= 0;
						readData2 <= 0;
						destRegister <= 0;
						branch <= 0;
						jump <= 0;
						jalr <= 0;
						ecall <= 1;
						memRead <= 0;
						memWrite <= 0;
						imm <= 0;
						regWrite <= 0;
						aluControl <= 0;
						memOrReg <= 0;
						registerRs <= 0;
						registerRt <= 0;
						storeType <= 0;
						loadType <= 0;
						branchType <= 0;
						epc <= pc + 4; 
					end
				// add-sub immediate
				7'b0010011:
					begin
						if(inDestRegister == outIns[19:15] && inRegWrite) begin
							readData1 <= inRegData;
						end else if(inDestRegisterFromEcall == outIns[19:15] && inRegWriteFromEcall) begin
							readData1 <= inRegDataFromEcall;
						end else begin
							readData1 <= mem[outIns[19:15]];
						end
						readData2 <= 0;
						destRegister <= outIns[11:7];
						regWrite <= 1;
						branch <= 0;
						memRead <= 0;
						memWrite <= 0;
						imm <= {{52{outIns[31]}} , outIns[31:20]};  // sign-extended immediate sent
						memOrReg <= 0;  // value from alu
						registerRs <= outIns[19:15];
						registerRt <= 0;   // immediate
						jump <= 0;
						jalr <= 0;
						ecall <= 0;
						loadType <= 0;
						storeType <= 0;
						branchType <= 0;
						epc <= 0;
						case(outIns[14:12])
							3'b000:
								aluControl <= 6'b000001;  // addi
							3'b010:
								aluControl <= 6'b000010;   // slti
							3'b011:
								aluControl <= 6'b000011;    // sltiu
							3'b100:
								aluControl <= 6'b000100;    // xori
							3'b110:
								aluControl <= 6'b000101;  // ori
							3'b111:
								aluControl <= 6'b000110;   // andi
							3'b001:
								aluControl <= 6'b000111;          // slli
							3'b101:
								if(outIns[31:26] == 6'b000000 ) begin
									aluControl <= 6'b001000;         // srli
								end else if(outIns[31:26] == 6'b010000) begin
									aluControl <= 6'b001001;        // srai
								end
							endcase
						end
				7'b1101111:
					// jal
					begin
						branch <= 0;
						jump <= 1;
						jalr <= 0;
						imm[0] <= 0;
						imm[63:1] <= {{43{outIns[31]}}, outIns[31], outIns[19:12], outIns[20], outIns[30:21]};
						regWrite <= 1;
						memRead <= 0;
						memWrite <= 0;
						memOrReg <= 0;
						destRegister <= outIns[11:7];
						registerRs <= 0;
						registerRt <= 0;
						aluControl <= 0;
						ecall <= 0;
						readData1 <= 0;
						readData2 <= 0;
						loadType <= 0;
						storeType <= 0;
						branchType <= 0;
						epc <= 0;
					end
				7'b1100111:
					// jalr
					begin
						branch <= 0;
						jump <= 1;
						imm <= {{52{outIns[31]}}, outIns[31:20]};
						if(inDestRegister == outIns[19:15] && inRegWrite) begin
							readData1 <= inRegData;
						end else if(inDestRegisterFromEcall == outIns[19:15] && inRegWriteFromEcall) begin
							readData1 <= inRegDataFromEcall;
						end else begin
							readData1 <= mem[outIns[19:15]];
						end
						readData2 <= 0;
						jalr <= 1; 
						regWrite <= 1;
						memRead <= 0;
						memWrite <= 0;
						memOrReg <= 0;
						destRegister <= outIns[11:7];
						registerRs <= outIns[19:15];
						registerRt <= 0;
						aluControl <= 0;
						ecall <= 0;
						readData2 <= 0;
						loadType <= 0;
						storeType <= 0;
						branchType <= 0;
						epc <= 0;
					end
				7'b1100011:
					// branches
					begin
						jump <= 0;
						jalr <= 0;
						imm[0] <= 0;
						imm[63:1] <= {{51{outIns[31]}}, outIns[31], outIns[7], outIns[30:25], outIns[11:8]};
						branch <= 1;
						if(inDestRegister == outIns[19:15] && inRegWrite) begin
							readData1 <= inRegData;
						end else if(inDestRegisterFromEcall == outIns[19:15] && inRegWriteFromEcall) begin
							readData1 <= inRegDataFromEcall;
						end else begin
							readData1 <= mem[outIns[19:15]];
						end
						if(inDestRegister == outIns[24:20] && inRegWrite) begin
							readData2 <= inRegData;
						end else if(inDestRegisterFromEcall == outIns[24:20] && inRegWriteFromEcall) begin
							readData2 <= inRegDataFromEcall;
						end else begin
							readData2 <= mem[outIns[24:20]];
						end
						destRegister <= 0;
						regWrite <= 0;
						memRead <= 0;
						memWrite <= 0;
						memOrReg <= 0;  
						registerRs <= outIns[19:15];
						registerRt <= outIns[24:20];
						ecall <= 0;
						loadType <= 0;
						storeType <= 0;
						epc <= 0;
						aluControl <= 0;
						case(outIns[14:12])
							3'b000:  // beq
								begin
									branchType <= 3'b010;
								end
							3'b001:	// bne
								begin
									branchType <= 3'b011;
								end
							3'b100:  // blt
								begin
									branchType <= 3'b100;
								end
							3'b101:   // bge
								begin
									branchType <= 3'b101;
								end
							3'b110:   // bltu
								begin
									branchType <= 3'b110;
								end
							3'b111:   // bgeu
								begin
									branchType <= 3'b111;
								end
							default:
								begin
									branchType <= 3'b000;
								end
						endcase
					end
				7'b0100011:
					// stores
					begin
						jump <= 0;
						jalr <= 0;
						regWrite <= 0;
						branch <= 0;
						memRead <= 0;
						memWrite <= 1;
						memOrReg <= 0; 
						if(inDestRegister == outIns[19:15] && inRegWrite) begin
							readData1 <= inRegData;
						end else if(inDestRegisterFromEcall == outIns[24:20] && inRegWriteFromEcall) begin
							readData1 <= inRegDataFromEcall;
						end else begin
							readData1 <= mem[outIns[19:15]];
						end
						destRegister <= 0;
						imm <= {{52{outIns[31]}}, outIns[31:25], outIns[11:7]};  // store immediate
						if(inDestRegister == outIns[24:20] && inRegWrite) begin
							readData2 <= inRegData;
						end else if(inDestRegisterFromEcall == outIns[24:20] && inRegWriteFromEcall) begin
							readData2 <= inRegDataFromEcall;
						end else begin
							readData2 <= mem[outIns[24:20]];
						end
						registerRs <= outIns[19:15];
						registerRt <= outIns[24:20];
						ecall <= 0; 
						loadType <= 0;
						branchType <= 0;
						epc <= 0;  
						case(outIns[14:12]) 
							3'b000: 
								// sb
								begin
									aluControl <= 6'b000001;   // addi
									storeType <= 2'b11;
								end
							3'b001: 
								// sh
								begin
									aluControl <= 6'b000001;
									storeType <= 2'b10;
								end
							3'b010:	
								// sw
								begin
									aluControl <= 6'b000001;
									storeType <= 2'b01;
								end
							3'b011:	
								// sd
								begin
									aluControl <= 6'b000001;
									storeType <= 2'b00;
								end
						endcase
					end
				// loads
				7'b0000011:
					begin
						jump <= 0;
						jalr <= 0;
						branch <= 0;
						memRead <= 1;
						regWrite <= 1;
						memWrite <= 0;
						memOrReg <= 1; // go from memory
						if(inDestRegister == outIns[19:15] && inRegWrite) begin
							readData1 <= inRegData;
						end else if(inDestRegister == outIns[24:20] && inRegWriteFromEcall) begin 
							readData1 <= inRegDataFromEcall;
						end else begin
							readData1 <= mem[outIns[19:15]];
						end
						destRegister <= outIns[11:7];
						imm <= {{52{outIns[31]}} , outIns[31:20]};
						readData2 <= 0;
						registerRs <= outIns[19:15];
						registerRt <= 0;
						ecall <= 0; 
						storeType <= 0;
						branchType <= 0;
						epc <= 0;
						case(outIns[14:12])
							3'b000:
								// lb
								begin
									aluControl <= 6'b000001;
									loadType <= 3'b001;
								end
							3'b001:
								begin
									aluControl <= 6'b000001;
									loadType <= 3'b010;
								end
								//lh
							3'b010:
								// lw
								begin
									aluControl <= 6'b000001;
									loadType <= 3'b011;
								end
							3'b100: 
								// lbu
								begin
									aluControl <= 6'b000001;
									loadType <= 3'b100;
								end
							3'b101:	
								// lhu
								begin
									aluControl <= 6'b000001;
									loadType <= 3'b101;
								end
							3'b110:
								// lwu
								begin
									aluControl <= 6'b000001;
									loadType <= 3'b110;
								end
							3'b011: 
								// ld
								begin
									aluControl <= 6'b000001;
									loadType <= 3'b000;
								end
							default:
								$display("wrong opcode format");
						endcase
					end           
				// add-sub
				7'b0110011:
					begin
						jump <= 0;
						jalr <= 0;
						regWrite <= 1;
						if(inDestRegister == outIns[19:15] && inRegWrite) begin
							readData1 <= inRegData;
						end else if(inDestRegisterFromEcall == outIns[19:15] && inRegWriteFromEcall) begin
							readData1 <= inRegDataFromEcall;
						end else begin
							readData1 <= mem[outIns[19:15]];
						end
						if(inDestRegister == outIns[24:20] && inRegWrite) begin
							readData2 <= inRegData;
						end else if(inDestRegisterFromEcall == outIns[24:20] && inRegWriteFromEcall) begin
							readData2 <= inRegDataFromEcall;
						end else begin
							readData2 <= mem[outIns[24:20]];
						end
						destRegister <= outIns[11:7];
						imm <= 0;
						branch <= 0;
						memRead <= 0;
						memWrite <= 0;
						memOrReg <= 0;
						registerRs <= outIns[19:15];
						registerRt <= outIns[24:20];
						ecall <= 0;
						loadType <= 0;
						storeType <= 0;
						branchType <= 0;
						epc <= 0;
						case(outIns[14:12])
							3'b000:
								if(outIns[31:25] == 7'b0000000) begin
									aluControl <= 6'b001100;
									// add
								end else if(outIns[31:25] == 7'b0100000) begin
									aluControl <= 6'b001101;
								end // sub
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
									aluControl <= 6'b001111;
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
						jump <= 0;
						jalr <= 0;
						if(inDestRegister == outIns[19:15] && inRegWrite) begin
							readData1 <= inRegData;
						end else if(inDestRegisterFromEcall == outIns[19:15] && inRegWriteFromEcall) begin
							readData1 <= inRegDataFromEcall;
						end else begin
							readData1 <= mem[outIns[19:15]];
						end
						if(inDestRegister == outIns[24:20] && inRegWrite) begin
							readData2 <= inRegData;
						end else if(inDestRegisterFromEcall == outIns[24:20] && inRegWriteFromEcall) begin
							readData2 <= inRegDataFromEcall;
						end else begin
							readData2 <= mem[outIns[24:20]];
						end
						destRegister <= outIns[11:7];
						imm <= 0;
						regWrite <= 1;
						branch <= 0;
						memRead <= 0;
						memWrite <= 0;
						memOrReg <= 0;
						registerRs <= outIns[19:15];
						registerRt <= outIns[24:20];
						ecall <= 0;
						loadType <= 0;
						storeType <= 0;
						branchType <= 0;
						epc <= 0;
						case(outIns[14:12])
							3'b000:
								if(outIns[31:25] == 7'b0000000) begin
									aluControl <= 6'b011010;
									//addw 
								end
								else if(outIns[31:25] == 7'b0100000) begin
									aluControl <= 6'b011011; // subw
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
						jump <= 0;
						jalr <= 0;
						if(inDestRegister == outIns[19:15] && inRegWrite) begin
							readData1 <= inRegData;
						end else if(inDestRegisterFromEcall == outIns[19:15] && inRegWriteFromEcall) begin
							readData1 <= inRegDataFromEcall;
						end else begin
							readData1 <= mem[outIns[19:15]];
						end
						readData2 <= 0;
						destRegister <= outIns[11:7]; 
						imm <= {{52{outIns[31]}} , outIns[31:20]}; // sign-extended immediate
						regWrite <= 1;
						branch <= 0;
						memRead <= 0;
						memWrite <= 0;
						memOrReg <= 0;
						registerRs <= outIns[19:15];
						registerRt <= 0;
						ecall <= 0;
						loadType <= 0;
						storeType <= 0;
						branchType <= 0;
						epc <= 0;
						case(outIns[14:12])
							3'b000:
								aluControl <= 6'b010110;
								// addiw
							3'b001:
								aluControl <= 6'b010111;
								// slliw
							3'b101:
								if(outIns[31:25] == 6'b0000000) begin
									aluControl <= 6'b011000;
									// srliw
								end
								else if(outIns[31:25] == 6'b0100000) begin
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
						jump <= 0;
						jalr <= 0;
						ecall <= 0;
						loadType <= 0;
						storeType <= 0;
						branchType <= 0;
						epc <= 0;
					end
			endcase
		end
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
assign outLoadType = loadType;
assign outRegWrite = regWrite;
assign outStoreType = storeType;
assign outBranchType = branchType;
assign outEcall = ecall;
assign out_bp_miss = bp_miss;
assign out_bp_is_branch_taken = bp_is_branch_taken;
assign outJump = jump;
assign outJalr = jalr;
assign outImm = imm;
assign outEpc = epc;

assign outMem10 = mem[10];
assign outMem11 = mem[11];
assign outMem12 = mem[12];
assign outMem13 = mem[13];
assign outMem14 = mem[14];
assign outMem15 = mem[15];
assign outMem16 = mem[16];
assign outMem17 = mem[17];

endmodule
