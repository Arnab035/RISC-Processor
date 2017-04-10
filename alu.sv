`include "Sysbus.defs"

module alu 
#(
	BUS_DATA_WIDTH = 64
)
(
	input clk,
	input end_of_cycle,
	
	input [BUS_DATA_WIDTH-1 : 0] inDataReg1,  // data direct from register files
	input [BUS_DATA_WIDTH-1 : 0] inDataReg2,  
	input [5:0] inAluControl,  
	input inBranch,
	input inMemRead,
	input inMemWrite,
	input inMemOrReg,
	input inRegisterRs,
	input inRegisterRt,
	input inPCSrc,
	input inRegWrite,
	input [BUS_DATA_WIDTH-1 : 0] inImm,  // immediate value
	input [4:0] inDestReg;
	
	// inputs from forwarding unit, as well as pipeline registers 
	input [BUS_DATA_WIDTH-1 : 0] inExResult,
	input [BUS_DATA_WIDTH-1 : 0] inMemResult,
	input [1:0] forwardingLogicA,
	input [1:0] forwardingLogicB,
	
	// final data inputs to be selected by a mux
	input [BUS_DATA_WIDTH-1 : 0] inData1,
	input [BUS_DATA_WIDTH-1 : 0] inData2,
	
	// outputs are here
	output outBranch,
	output outMemRead,
	output outMemWrite,
	output outMemOrReg,
	output outPCSrc,
	output outRegWrite,
	output outZero,       // this is a zero indicator to be used when we perform branches
	
	output [BUS_DATA_WIDTH-1 : 0] outResult,
	output send_call_for_print  // not sure of this yet..
);

logic branch, memRead, memWrite, memOrReg, pcSrc, regWrite;

reg [BUS_DATA_WIDTH-1 : 0] val;

logic [4:0] destReg;

always_comb begin
	// inputs from forwarding unit module
	case(forwardingLogicA)
		2'b00:
			begin
				inData1 = inDataReg1;
			end
		2'b01:
			begin
				inData1 = inMemResult;
			end
		2'b10:
			begin
				inData1 = inExResult;
			end
	endcase
	case(forwardingLogicB)
		2'b00:
			begin
				inData2 = inDataReg1;
			end
		2'b01:
			begin
				inData2 = inMemResult;
			end
		2'b10:
			begin
				inData2 = inExResult;
			end
	endcase
end

// allow for forwarded values
always @ (posedge clk)
	// the below logic values do not change here
	branch <= inBranch;
	memRead <= inMemRead;
	memWrite <= inMemWrite;
	memOrReg <= inMemOrReg;
	pcSrc <= inPcSrc;
	regWrite <= inRegWrite;
	
	destReg <= inDestReg;
	case(inAluControl)
		6'b000001:  // addi
			begin
				val[31:0] <=  inData1 + inImm;
			end
		6'b000010:  // slti
			if($signed(inData1) < $signed(inImm)) begin
				val[31:0] <= 1;
			end else begin
				val[31:0] <= 0;
			end
		6'b000011:  // sltiu
			if(inData1 < inImm) begin
				val[31:0] <= 1;
			end else begin
				val[31:0] <= 0;
			end
		6'b000100:  // xori
			begin
				val[31:0] <= inData1 ^ inImm;
			end
		6'b000101:  // ori
			begin
				val[31:0] <= inData1 | inImm;
			end
		6'b000110:  // andi
			begin
				val[31:0] <= inData1 & inImm;
			end
		6'b000111: // slli
			begin
				val[31:0] <= inData1 << inImm[4:0] ;
			end
		6'b001000: // srli
			begin
				val[31:0] <= inData1 >> inImm[4:0] ;
			end
		6'b001001: // srai
			begin
				val[31:0] <= inData1 >>> inImm[4:0] ;
			end
		6'b001100: // add
			begin
				val[31:0] <= inData1 + inData2;
			end
		6'b001101: // sub
			begin
				val[31:0] <= inData1 - inData2;
			end
		6'b001110: // sll
			begin
				val[31:0] <= inData1 << inData2[4:0];
			end
		6'b001111: // slt
			begin
				if($signed(inData1) < $signed(inData2)) begin
					val[31:0] <= 1;
				end else begin
					val[31:0] <= 0;
				end
			end
		6'b010000: // sltu
			begin
				if(inData1 < inData2) begin
					val[31:0] <= 1;
				end else begin
					val[31:0] <= 0;
				end
			end
		6'b010001: // xor
			begin
				val[31:0] <= inData1 ^ inData2;
			end
		6'b010010:  // srl
			begin
				val[31:0] <= inData1 >> inData2[4:0] ;
			end
		6'b010011: // sra
			begin
				val[31:0] <= inData1 >>> inData2[4:0] ;
			end
		6'b010100: // or
			begin
				val[31:0] <= inData1 | inData2 ;
			end
		6'b010101: // and
			begin
				val[31:0] <= inData1 & inData2;
			end
		/*********************** 32-bit instructions end ***********************/
		6'b010110: // addiw
			begin
				val[31:0] <= inData1 + inImm;
			end
		6'b010111: // slliw
			begin
				val[31:0] <= inData1 << inImm[4:0];
			end
		6'b011000: // srliw
			begin
				val[31:0] <= inData1 >> inImm[4:0];
			end
		6'b011001: // sraiw
			val[31:0] <= inData1 >>> inImm[4:0];
		6'b011010: // addw
			val[31:0] <= inData1 + inData2 ;
		6'b011011: // subw
			val[31:0] <= inData1 - inData2;
		6'b011100: //sllw
			val[31:0] <= inData1 << inData2[4:0];
		6'b011101: // srlw
			val[31:0] <= inData1 >> inData2[4:0];
		6'b011110: // sraw
			val[31:0] <= inData1 >>> inData2[4:0];
		/************************ M - Extension start ************************************/
		6'b011111: // mul
			val[31:0] <= inData1 * inData2;
		6'b100000: // mulh
			val <= $signed(inData1) * $signed(inData2) ;
		6'b100001: // mulhsu
			val <= $signed(inData1) * inData2 ;
		6'b100010: // mulhu
			val <= inData1 * inData2;
		6'b100011: // div
			val <= $signed(inData1[31:0]) / $signed(inData2[31:0]) ;
		6'b100100: // divu
			val <= inData1[31:0] / inData2[31:0] ;
		6'b100101: // rem
			val <= $signed(inData1[31:0]) % $signed(inData2[31:0]) ;
		6'b100110: // remu
			val <= inData1[31:0] % inData2[31:0];
		6'b100111: // mulw
			val[31:0] <= inData1[31:0] * inData2[31:0] ;
		6'b101000: // divw
			val[31:0] <= $signed(inData1[31:0]) / $signed(inData2[31:0]) ;
		6'b101001: // divuw
			val[31:0] <= inData1[31:0] / inData2[31:0] ;
		6'b101010: // remw
			val[31:0] <= $signed(inData1[31:0]) % $signed(inData2[31:0]);
		6'b101011: // remuw
			val[31:0] <= inData1[31:0] % inData2[31:0] ;
		default:
			begin
				val[31:0] = 0;
			end
	endcase


always_comb 
	if(inAluControl > 6'b010101) begin
		if(inAluControl < 6'b011111 || inAluControl >= 6'b100111) begin
			outResult = {{32{val[31]}}, val[31:0]};
		end
		else if(inAluControl >= 6'b100000 && inAluControl = 6'b100010) begin
			outResult[31:0] = val[63:32];
		end
	else if(inAluControl == 6'b001101 && val == 0) begin
		outZero = 1;  // this is the zero output
	end else begin
		outResult = val;
	end

assign outBranch = branch;
assign outMemRead = memRead;
assign outMemWrite = memWrite;
assign outMemOrReg = memOrReg;
assign outPcSrc = pcSrc;
assign outRegWrite = regWrite;

assign outDestReg = destReg;  // pass out the destination register also
	
/*	
always_comb begin
	if(end_of_cycle == 1) begin
		send_call_for_print = 1;
	end
end*/

endmodule




