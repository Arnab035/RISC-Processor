
`include "Sysbus.defs"

module alu 
#(
	BUS_DATA_WIDTH = 64
)
(
	input clk,
	input end_of_cycle,
	input alu_en,
	input [BUS_DATA_WIDTH-1 : 0] dataA,
	input [BUS_DATA_WIDTH-1 : 0] dataB,  
	input [5:0] alu_control,  
	output [BUS_DATA_WIDTH-1 : 0] dataOut,
	output _aluOps,
	output send_call_for_print,
	output write_en
);

logic aluOps = 0;

logic writeBack_en;

reg [BUS_DATA_WIDTH-1 : 0] val;
reg [BUS_DATA_WIDTH-1 : 0] x;

always_comb 
    if(alu_en) begin
		case(alu_control)
			6'b000001:  // addi
				begin
					val[31:0] = dataA + dataB ;
					aluOps = 1;
				end
			6'b000010:  // slti
				if($signed(dataA) < $signed(dataB)) begin
					val[31:0] = 1;
					aluOps = 1;
				end else begin
					val[31:0] = 0;
					aluOps = 1;
				end
			6'b000011:  // sltiu
				if(dataA < dataB) begin
					val[31:0] = 1;
					aluOps = 1;
				end else begin
					val[31:0] = 0;
					aluOps = 1;
				end
			6'b000100:  // xori
				begin
					val[31:0] = dataA ^ dataB;
					aluOps = 1;
				end
			6'b000101:  // ori
				begin
					val[31:0] = dataA | dataB;
					aluOps = 1;
				end
			6'b000110:  // andi
				begin
					val[31:0] = dataA & dataB;
					aluOps = 1;
				end
			6'b000111: // slli
				begin
					val[31:0] = dataA << dataB[5:0] ;
					aluOps = 1;
				end
			6'b001000: // srli
				begin
					val[31:0] = dataA >> dataB[5:0] ;
					aluOps = 1;
				end
			6'b001001: // srai
				begin
					val[31:0] = dataA >>> dataB[5:0] ;
					aluOps = 1;
				end
			6'b001100: // add
				begin
					val[31:0] = dataA + dataB;
					aluOps = 1;
				end
			6'b001101: // sub
				begin
					val[31:0] = dataA - dataB;
					aluOps = 1;
				end
			6'b001110: // sll
				begin
					val[31:0] = dataA << dataB[4:0];
					aluOps = 1;
				end
			6'b001111: // slt
				begin
					if($signed(dataA) < $signed(dataB)) begin
						val[31:0] = 1;
					end else begin
						val[31:0] = 0;
					end
					aluOps = 1;
				end
			6'b010000: // sltu
				begin
					if(dataA < dataB) begin
						val[31:0] = 1;
					end else begin
						val[31:0] = 0;
					end
					aluOps = 1;
				end
			6'b010001: // xor
				begin
					val[31:0] = dataA ^ dataB;
					aluOps = 1;
				end
			6'b010010:  // srl
				begin
					val[31:0] = dataA >> dataB[4:0] ;
					aluOps = 1;
				end
			6'b010011: // sra
				begin
					val[31:0] = dataA >>> dataB[4:0] ;
					aluOps = 1;
				end
			6'b010100: // or
				begin
					val[31:0] = dataA | dataB ;
					aluOps = 1;
				end
			6'b010101: // and
				begin
					val[31:0] = dataA & dataB;
					aluOps = 1;
				end
		/*********************** 32-bit instructions end ***********************/
			6'b010110: // addiw
				begin
					val[31:0] = dataA + dataB;
					aluOps = 1;
				end
			6'b010111: // slliw
				begin
					val[31:0] = dataA << dataB[4:0];
					aluOps = 1;
				end
			6'b011000: // srliw
				begin
					val[31:0] = dataA >> dataB[4:0];
					aluOps = 1;
				end
			6'b011001: // sraiw
				val[31:0] = dataA >>> dataB[4:0];
			6'b011010: // addw
				val[31:0] = dataA + dataB ;
			6'b011011: // subw
				val[31:0] = dataA - dataB;
			6'b011100: //sllw
				val[31:0] = dataA << dataB[4:0];
			6'b011101: // srlw
				val[31:0] = dataA >> dataB[4:0];
			6'b011110: // sraw
				val[31:0] = dataA >>> dataB[4:0];
		/************************ M - Extension start ************************************/
			6'b011111: // mul
				val[31:0] = dataA * dataB;
			6'b100000: // mulh
				val = $signed(dataA) * $signed(dataB) ;
			6'b100001: // mulhsu
				val = $signed(dataA) * dataB ;
			6'b100010: // mulhu
				val = dataA * dataB;
			6'b100011: // div
				val = $signed(dataA[31:0]) / $signed(dataB[31:0]) ;
			6'b100100: // divu
				val = dataA[31:0] / dataB[31:0] ;
			6'b100101: // rem
				val = $signed(dataA[31:0]) % $signed(dataB[31:0]) ;
			6'b100110: // remu
				val = dataA[31:0] % dataB[31:0];
			6'b100111: // mulw
				val[31:0] = dataA[31:0] * dataB[31:0] ;
			6'b101000: // divw
				val[31:0] = $signed(dataA[31:0]) / $signed(dataB[31:0]) ;
			6'b101001: // divuw
				val[31:0] = dataA[31:0] / dataB[31:0] ;
			6'b101010: // remw
				val[31:0] = $signed(dataA[31:0]) % $signed(dataB[31:0]);
			6'b101011: // remuw
				val[31:0] = dataA[31:0] % dataB[31:0] ;
			default:
				begin
					val[31:0] = 0;
					aluOps = 0;
				end
		endcase
		writeBack_en = 1;
	end else begin
		writeBack_en = 0;
	end

always_comb begin
if(aluOps) begin
	$display("Hi");
	dataOut = val;
	write_en = 1;
end
else
	write_en = 0;
end

/*	
always_comb 
	if(alu_control > 6'b010101) begin
		if(alu_control < 6'b011111 || alu_control >= 6'b100111) begin
			x = {{32{val[31]}}, val[31:0]};
			dataOut = x;
		end
		else if(alu_control >= 6'b100000 && alu_control = 6'b100010) begin
			x = val[63:32];
			dataOut = x;
		end
	end
	else begin
		dataOut = val;
	end*/
	
always_comb begin
	if(end_of_cycle == 1) begin
		send_call_for_print = 1;
	end
end


endmodule
		
		
 			
			
			
			






