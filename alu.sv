module alu 
#(
	BUS_DATA_WIDTH = 64
)
(
	input clk,
	input [BUS_DATA_WIDTH-1 : 0] inPc,
	input [BUS_DATA_WIDTH-1 : 0] inDataReg1,  // data direct from register files
	input [BUS_DATA_WIDTH-1 : 0] inDataReg2,  
	input [5:0] inAluControl,  
	input inBranch,
	input inMemRead,
	input inMemWrite,
	input inMemOrReg,
	input inPCSrc,
	input inRegWrite,
	input inJump,
	input inJalr,
	input [BUS_DATA_WIDTH-1 : 0] inImm,  // immediate value
	input [4:0] inDestRegister,
	input [4:0] inRegisterRt,  // to handle store forwarding
	input [2:0] inBranchType,
	input [2:0] inLoadType,
	input [1:0] inStoreType,
	input inEcall,
	input inFlushFromEcall,   // flush pipeline
	input inFlushFromJump,
	input in_stall_from_dcache,
	input in_stall_from_icache,
	input [1:0] inForwardA,
	input [1:0] inForwardB,
	input [BUS_DATA_WIDTH-1 : 0] inResultEx,
	input [BUS_DATA_WIDTH-1 : 0] inResultMem,
	input [63:0] inEpc,

	// outputs are here
	output [1:0] outStoreType,
	output [2:0] outLoadType,
	output [4:0] outDestRegister,
	output [4:0] outRegisterRt,
	output outBranch,
	output outMemRead,
	output outMemWrite,
	output outMemOrReg,
	output outPCSrc,
	output outRegWrite,
	output outJump,
	output outZero,
	output [BUS_DATA_WIDTH-1 : 0] outAddrJump,
	output [BUS_DATA_WIDTH-1 : 0] outResult,
	output [BUS_DATA_WIDTH-1 : 0] outDataReg2,
	output outEcall,
	output [63:0] outEpc,
	output [63:0] outPc
);

`include "Sysbus.defs"

logic branch, memRead, memWrite, memOrReg, pcSrc, regWrite, zero, jump;

logic [BUS_DATA_WIDTH-1 : 0] dataReg2, inData1, inData2;

logic [BUS_DATA_WIDTH-1 : 0] val, addrJump, epc;

logic [4:0] destRegister, registerRt;
logic [1:0] storeType;
logic [2:0] loadType, branchType;

logic [5:0] aluControl;

always_ff @ (posedge clk) begin
	if(!in_stall_from_dcache && !in_stall_from_icache) begin
		if(inAluControl)
			aluControl <= inAluControl;
	end
end

// for jump logic

always_ff @ (posedge clk) begin
	if(!in_stall_from_dcache && !in_stall_from_icache) begin
		if(inFlushFromJump || inFlushFromEcall) begin
			addrJump <= 0;
		end else begin
			if(inJump && !inJalr) begin
				addrJump <= inPc + inImm  ;
			end else if(inJump && inJalr) begin
				addrJump <= inData1 + inImm;
				addrJump[0] <= 0;
			end else if(inBranch) begin
				addrJump <= inPc + inImm ;
			end else begin
				addrJump <= 0;
			end
		end
	end
end

assign outAddrJump = addrJump;

logic [127:0] val_for_multiply;

always_comb begin
	if(!in_stall_from_dcache && !in_stall_from_icache) begin
		if(inForwardA == 2'b00) begin
			inData1 = inDataReg1;
		end else if(inForwardA == 2'b01) begin
			inData1 = inResultMem;
		end else if(inForwardA == 2'b10) begin
			inData1 = inResultEx;
		end
	end
end

always_comb begin
	if(!in_stall_from_dcache && !in_stall_from_icache) begin
		if(inForwardB == 2'b00) begin
			inData2 = inDataReg2;
		end else if(inForwardB == 2'b01) begin
			inData2 = inResultMem;
		end else if(inForwardB == 2'b10) begin
			inData2 = inResultEx;
		end
	end
end

logic ecall;

always_ff @ (posedge clk) begin
	if(!in_stall_from_dcache && !in_stall_from_icache) begin
		if(inFlushFromJump || inFlushFromEcall) begin
			zero <= 0;
		end else begin
			if(inBranch) begin
				if(inBranchType == 3'b010) begin  // beq
					if(inData1 == inData2) begin
						zero <= 1;
					end else begin
						zero <= 0;
					end
				end else if(inBranchType == 3'b011) begin  // bne
					if(inData1 != inData2) begin
						zero <= 1;
					end else begin
						zero <= 0;
					end
				end else if(inBranchType == 3'b100) begin //blt
					if($signed(inData1) < $signed(inData2)) begin
						zero <= 1;
					end else begin
						zero <= 0;
					end
				end else if(inBranchType == 3'b101) begin
					if($signed(inData1) >= $signed(inData2)) begin
						zero <= 1;
					end else begin
						zero <= 0;
					end
				end else if(inBranchType == 3'b110) begin
					if(inData1 < inData2) begin
						zero <= 1;
					end else begin
						zero <= 0;
					end
				end else if(inBranchType == 3'b111) begin
					if(inData1 >= inData2) begin
						zero <= 1;
					end else begin
						zero <= 0;
					end
				end else begin
					zero <= 0;
				end
			end else begin
				zero <= 0;
			end
		end
	end
end

always_ff @ (posedge clk) begin
	if(!in_stall_from_dcache && !in_stall_from_icache) begin
		if(inFlushFromJump || inFlushFromEcall) begin
			ecall <= 0;
			jump <= 0;
			memRead <= 0;
			branch <= 0;
			memWrite <= 0;
			memOrReg <= 0;
			pcSrc <= 0;
			regWrite <= 0;
			destRegister <= 0;
			dataReg2 <= 0;
			loadType <= 0;
			storeType <= 0;
			val <= 0;
			epc <= 0;
			registerRt <= 0;
			outPc <= 0;
		end else begin
			// the below logic values do not change here
			ecall <= inEcall;
			jump <= inJump;
			memRead <= inMemRead;
			branch <= inBranch;
			memWrite <= inMemWrite;
			memOrReg <= inMemOrReg;
			pcSrc <= inPCSrc;
			regWrite <= inRegWrite;
			destRegister <= inDestRegister;
			dataReg2 <= inData2; // for store
			loadType <= inLoadType;
			storeType <= inStoreType;
			epc <= inEpc;
			registerRt <= inRegisterRt;
			outPc <= inPc;
			case(inAluControl)
				6'b000001:  // addi
					begin
						val <= inData1 + inImm;
					end
				6'b000010:  // slti
					begin
						if($signed(inData1) < $signed(inImm)) begin
							val <= 1;
						end else begin
							val <= 0;
						end
					end
				6'b000011:  // sltiu
					begin
						if(inData1 < inImm) begin
							val <= 1;
						end else begin
							val <= 0;
						end
					end
				6'b000100:  // xori
					begin
						val <= inData1 ^ inImm;
					end
				6'b000101:  // ori
					begin
						val <= inData1 | inImm;
					end
				6'b000110:  // andi
					begin
						val <= inData1 & inImm;
					end
				/*  shift amount encoded in lower 6 bits for RV64I , for 5 bits in RV32I  */
				6'b000111: // slli
					begin
						val <= inData1 << inImm[5:0];
					end
				6'b001000: // srli
					begin
						val <= inData1 >> inImm[5:0] ;
					end
				6'b001001: // srai
					begin
						val <= inData1 >>> inImm[5:0] ;
					end
				6'b001100: // add
					begin
						val <= inData1 + inData2;
					end
				6'b001101: // sub
					begin
						val <= inData1 - inData2;
					end
				/* in RV64I lower 6-bits considered for shift */	
				6'b001110: // sll
					begin
						val <= inData1 << inData2[5:0];
					end
				6'b001111: // slt
					begin
						if($signed(inData1) < $signed(inData2)) begin
							val <= 1;
						end else begin
							val <= 0;
						end
					end
				6'b010000: // sltu
					begin
						if(inData1 < inData2) begin
							val <= 1;
						end else begin
							val <= 0;
						end
					end
				6'b010001: // xor
					begin
						val <= inData1 ^ inData2;
					end
				6'b010010:  // srl
					begin
						val <= inData1 >> inData2[5:0];
					end
				6'b010011: // sra
					begin
						val <= inData1 >>> inData2[5:0];
					end
				6'b010100: // or
					begin
						val <= inData1 | inData2 ;
					end
				6'b010101: // and
					begin
						val <= inData1 & inData2;
					end

				/*********************** 32-bit instructions end ***********************/

				6'b010110: // addiw
					begin
						val[31:0] <= inData1[31:0] + inImm[31:0];
					end
				6'b010111: // slliw
					begin
						val[31:0] <= inData1[31:0] << inImm[4:0];  // inImm[5] is 0
					end
				6'b011000: // srliw
					begin
						val[31:0] <= inData1[31:0] >> inImm[4:0];
					end
				6'b011001: // sraiw
					begin
						val[31:0] <= inData1[31:0] >>> inImm[4:0];
					end
				6'b011010: // addw
					begin
						val[31:0] <= inData1[31:0] + inData2[31:0] ;
					end
				6'b011011: // subw
					begin
						val[31:0] <= inData1[31:0] - inData2[31:0] ;
					end
				6'b011100: //sllw
					begin
						val[31:0] <= inData1[31:0] << inData2[4:0] ;
					end
				6'b011101: // srlw
					begin
						val[31:0] <= inData1[31:0] >> inData2[4:0];
					end
				6'b011110: // sraw
					begin
						val[31:0] <= inData1[31:0] >>> inData2[4:0];
					end

				/************************ M - Extension start ************************************/

				6'b011111: // mul
					begin
						val_for_multiply <= inData1 * inData2 ;
					end
				6'b100000: // mulh
					begin
						val_for_multiply <= $signed(inData1) * $signed(inData2);
					end
				6'b100001: // mulhsu
					begin
						val_for_multiply <= $signed(inData1) * inData2 ;
					end
				6'b100010: // mulhu
					begin
						val_for_multiply <= inData1 * inData2;
					end
				6'b100011: // div
					begin
						val <= $signed(inData1) / $signed(inData2) ;
					end
				6'b100100: // divu
					begin
						val <= inData1 / inData2 ;
					end
				6'b100101: // rem
					begin
						val <= $signed(inData1) % $signed(inData2);
					end
				6'b100110: // remu
					begin
						val <= inData1 % inData2;
					end
				6'b100111: // mulw
					begin
						val[31:0] <= inData1[31:0] * inData2[31:0] ;
					end
				6'b101000: // divw
					begin
						val[31:0] <= $signed(inData1[31:0]) / $signed(inData2[31:0]) ;
					end
				6'b101001: // divuw
					begin
						val[31:0] <= inData1[31:0] / inData2[31:0] ;
					end
				6'b101010: // remw
					begin
						val[31:0] <= $signed(inData1[31:0]) % $signed(inData2[31:0]);
					end
				6'b101011: // remuw
					begin
						val[31:0] <= inData1[31:0] % inData2[31:0] ;
					end
				default:
					begin
						val[31:0] <= 0;
					end
			endcase
		end
	end
end

always_comb
	if(!in_stall_from_dcache && !in_stall_from_icache) begin
		if(aluControl > 6'b010101) begin
			if(aluControl < 6'b011111 || aluControl >= 6'b100111) begin
				outResult = {{32{val[31]}}, val[31:0]};
			end
			else if(aluControl == 6'b011111) begin
				outResult = val_for_multiply[63:0];      // mul
			end
			else if(aluControl >= 6'b100011 && aluControl <= 6'b100110) begin
				outResult = val;
			end
			else if(aluControl >= 6'b100000 && aluControl <= 6'b100010) begin
				outResult = val_for_multiply[127:64];   // upper 64-bits   ---> mulh/mulhsu/ mulhu
			end 
		end else begin
			outResult = val;
		end
	end

assign outBranch = branch;
assign outMemRead = memRead;
assign outMemWrite = memWrite;
assign outMemOrReg = memOrReg;
assign outPCSrc = pcSrc;
assign outRegWrite = regWrite;
assign outDataReg2 = dataReg2;
assign outDestRegister = destRegister;  // pass out the destination register also
assign outLoadType = loadType;
assign outStoreType = storeType;
assign outZero = zero;
assign outJump = jump;
assign outEpc = epc;
assign outRegisterRt = registerRt;

assign outEcall = ecall;
	
endmodule
