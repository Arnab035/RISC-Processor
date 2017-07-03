`include "Sysbus.defs"

module alu 
#(
	BUS_DATA_WIDTH = 64
)
(
	input clk,
	input inPc,
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
	input [2:0] inBranchType,
	input [2:0] inLoadType,
	input [1:0] inStoreType,
	
	// TODO : handle forwarding unit logic
	
	input [1:0] inForwardA,
	input [1:0] inForwardB,
	input [BUS_DATA_WIDTH-1 : 0] inResultEx,
	input [BUS_DATA_WIDTH-1 : 0] inResultMem,
	

	// outputs are here
	output [1:0] outStoreType,
	output [2:0] outLoadType,
	output [4:0] outDestRegister,
	output outBranch,
	output outMemRead,
	output outMemWrite,
	output outMemOrReg,
	output outPCSrc,
	output outRegWrite,
	output outJump,
	output [BUS_DATA_WIDTH-1 : 0] outAddrJump,
	output [BUS_DATA_WIDTH-1 : 0] outResult,
	output [BUS_DATA_WIDTH-1 : 0] outDataReg2
);

logic branch, memRead, memWrite, memOrReg, pcSrc, regWrite, zero;

logic [BUS_DATA_WIDTH-1 : 0] dataReg2, inData1, inData2;

logic [BUS_DATA_WIDTH-1 : 0] val, addrJump;

logic [4:0] destRegister;
logic [1:0] storeType;
logic [2:0] loadType;

// for jump logic

always @ (posedge clk) begin
	if(inJump && !inJalr) begin
		addrJump <= inPc + inImm  ;
	end else if(inJump && inJalr) begin
		addrJump <= inData1 + inImm;
	end else begin
		addrJump <= inPc + inImm;
	end
end

assign outAddrJump = addrJump;

// TODO: handle forwarding logic here

always_comb begin
	if(inForwardA == 2'b00) begin
		inData1 = inDataReg1;
	end else if(inForwardA == 2'b01) begin
		inData1 = inResultMem;
	end else if(inForwardA == 2'b10) begin
		inData1 = inResultEx;
	end
end

always_comb begin
	if(inForwardB == 2'b00) begin
		inData2 = inDataReg2;
	end else if(inForwardB == 2'b01) begin
		inData2 = inResultMem;
	end else if(inForwardB == 2'b10) begin
		inData2 = inResultEx;
	end
end


always_ff @ (posedge clk) begin
	// the below logic values do not change here
	jump <= inJump;
	memRead <= inMemRead;
	branch <= inBranch;
	branchType <= inBranchType;
	memWrite <= inMemWrite;
	memOrReg <= inMemOrReg;
	pcSrc <= inPCSrc;
	regWrite <= inRegWrite;
	destRegister <= inDestRegister;
	dataReg2 <= inDataReg2; // for store
	loadType <= inLoadType;
	storeType <= inStoreType;
	case(inAluControl)
		6'b000001:  // addi
			begin
				val[31:0] <= inData1 + inImm;
				zero <= 0;
			end
		6'b000010:  // slti
			begin
				if($signed(inData1) < $signed(inImm)) begin
					val[31:0] <= 1;
				end else begin
					val[31:0] <= 0;
				end
				zero <= 0;
			end
		6'b000011:  // sltiu
			if(inData1 < inImm) begin
				val[31:0] <= 1;
			end else begin
				val[31:0] <= 0;
			end
			zero <= 0;
		6'b000100:  // xori
			begin
				val[31:0] <= inData1 ^ inImm;
				zero <= 0;
			end
		6'b000101:  // ori
			begin
				val[31:0] <= inData1 | inImm;
				zero <= 0;
			end
		6'b000110:  // andi
			begin
				val[31:0] <= inData1 & inImm;
				zero <= 0;
			end
		6'b000111: // slli
			begin
				val[31:0] <= inData1 << inImm[4:0] ;
				zero <= 0;
			end[]
		6'b001000: // srli
			begin
				val[31:0] <= inData1 >> inImm[4:0] ;
				zero <= 0;
			end
		6'b001001: // srai
			begin
				val[31:0] <= inData1 >>> inImm[4:0] ;
				zero <= 0;
			end
		6'b001100: // add
			begin
				val[31:0] <= inData1 + inData2;
				zero <= 0;
			end
		6'b001101: // sub
			begin
				val[31:0] <= inData1 - inData2;
				if(inBranchType == 3'b001) begin
					zero <= ((inData1 - inData2) == 0) ? 1 : 0;
				end else if(inBranchType == 3'b010) begin
					zero <= ((inData1 - inData2) != 0) ? 1 : 0;
				end
			end
		6'b001110: // sll
			begin
				val[31:0] <= inData1 << inData2[4:0];
				zero <= 0;
			end
		6'b001111: // slt
			begin
				if($signed(inData1) < $signed(inData2)) begin
					val[31:0] <= 1;
					if(inBranchType == 3'b100) 
						zero <= 1;
				end else begin
					val[31:0] <= 0;
					if(inBranchType == 3'b011)
						zero <= 1;
				end
			end
		6'b010000: // sltu
			begin
				if(inData1 < inData2) begin
					val[31:0] <= 1;
					if(inBranchType == 3'b110)
						zero <= 1;
				end else begin
					val[31:0] <= 0;
					if(inBranchType == 3'b101)
						zero <= 1;
				end
			end
		6'b010001: // xor
			begin
				val[31:0] <= inData1 ^ inData2;
				zero <= 0;
			end
		6'b010010:  // srl
			begin
				val[31:0] <= inData1 >> inData2[4:0];
				zero <= 0;
			end
		6'b010011: // sra
			begin
				val[31:0] <= inData1 >>> inData2[4:0];
				zero <= 0;
			end
		6'b010100: // or
			begin
				val[31:0] <= inData1 | inData2 ;
				zero <= 0;
			end
		6'b010101: // and
			begin
				val[31:0] <= inData1 & inData2;
				zero <= 0;
			end

		/*********************** 32-bit instructions end ***********************/

		6'b010110: // addiw
			begin
				val[31:0] <= inData1 + inImm;
				zero <= 0;
			end
		6'b010111: // slliw
			begin
				val[31:0] <= inData1 << inImm[4:0];
				zero <= 0;
			end
		6'b011000: // srliw
			begin
				val[31:0] <= inData1 >> inImm[4:0];
				zero <= 0;
			end
		6'b011001: // sraiw
			begin
				val[31:0] <= inData1 >>> inImm[4:0];
				zero <= 0;
			end
		6'b011010: // addw
			begin
				val[31:0] <= inData1 + inData2 ;
				zero <= 0;
			end
		6'b011011: // subw
			begin
				val[31:0] <= inData1 - inData2 ;
				zero <= 0;
			end
		6'b011100: //sllw
			begin
				val[31:0] <= inData1 << inData2[4:0] ;
				zero <= 0;
			end
		6'b011101: // srlw
			begin
				val[31:0] <= inData1 >> inData2[4:0];
				zero <= 0;
			end
		6'b011110: // sraw
			begin
				val[31:0] <= inData1 >>> inData2[4:0];
				zero <= 0;
			end

		/************************ M - Extension start ************************************/

		6'b011111: // mul
			begin
				val[31:0] <= inData1 * inData2;
				zero <= 0;
			end
		6'b100000: // mulh
			begin
				val <= $signed(inData1) * $signed(inData2);
				zero <= 0;
			end
		6'b100001: // mulhsu
			begin
				val <= $signed(inData1) * inData2 ;
				zero <= 0;
			end
		6'b100010: // mulhu
			begin
				val <= inData1 * inData2;
				zero <= 0;
			end
		6'b100011: // div
			begin
				val <= $signed(inData1[31:0]) / $signed(inData2[31:0]) ;
				zero <= 0;
			end
		6'b100100: // divu
			begin
				val <= inData1[31:0] / inData2[31:0] ;
				zero <= 0;
			end
		6'b100101: // rem
			begin
				val <= $signed(inData1[31:0]) % $signed(inData2[31:0]) ;
				zero <= 0;
			end
		6'b100110: // remu
			begin
				val <= inData1[31:0] % inData2[31:0];
				zero <= 0;
			end
		6'b100111: // mulw
			begin
				val[31:0] <= inData1[31:0] * inData2[31:0] ;
				zero <= 0;
			end
		6'b101000: // divw
			begin
				val[31:0] <= $signed(inData1[31:0]) / $signed(inData2[31:0]) ;
				zero <= 0;
			end
		6'b101001: // divuw
			begin
				val[31:0] <= inData1[31:0] / inData2[31:0] ;
				zero <= 0;
			end
		6'b101010: // remw
			begin
				val[31:0] <= $signed(inData1[31:0]) % $signed(inData2[31:0]);
				zero <= 0;
			end
		6'b101011: // remuw
			begin
				val[31:0] <= inData1[31:0] % inData2[31:0] ;
				zero <= 0;
			end
		default:
			begin
				val[31:0] <= 0;
				zero <= 0;
			end
	endcase
end

always_comb 
	if(inAluControl > 6'b010101) begin
		if(inAluControl < 6'b011111 || inAluControl >= 6'b100111) begin
			outResult = {{32{val[31]}}, val[31:0]};
		end
		else if(inAluControl >= 6'b100000 && inAluControl == 6'b100010) begin
			outResult[31:0] = val[63:32];
		end
	end else begin
		outResult = val;
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
	
/*	
always_comb begin
	if(end_of_cycle == 1) begin
		send_call_for_print = 1;
	end
end*/

endmodule




