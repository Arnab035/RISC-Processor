// only ALU ops defined

`include "Sysbus.defs"

module decode1
# (
	BUS_DATA_WIDTH = 64
)
(
	input clk,
	input [31:0] outIns,
	output [5:0] out_alu_control,
	output [4:0] out_addressA,
	output [4:0] out_addressB,
	output [4:0] out_addressC,
	output [BUS_DATA_WIDTH-1:0] out_imm,
	output logic out_muxB_control
);

reg [4:0] addressA, addressB, addressC;

reg [BUS_DATA_WIDTH-1:0] imm;
logic muxB_control = 0;

reg [5:0] alu_control;

always @ (posedge clk) 
	case(outIns[6:0])
		7'b0010011:
			begin
				muxB_control <= 1; // immediate
				addressA <= outIns[19:15];
				addressB <= 0;
				addressC <= outIns[11:7]; 
				imm <= {{52{outIns[31]}} , outIns[31:20]};
				case(outIns[14:12])
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
					3'b010:
						alu_control <= 6'b000010;
					3'b011:
						if(outIns[31:20] == 11'd1) begin //seqz
							alu_control <= 6'b000011;
						end else begin     //sltiu
							alu_control <= 6'b000011;
						end
					3'b100:
						if(outIns[31:20] == -11'd1) begin
							// not
							alu_control <= 6'b000100;
						end else begin // xori
							alu_control <= 6'b000100;
						end
					3'b110:
						alu_control <= 6'b000101;
					3'b111:
						alu_control <= 6'b000110;
					3'b001:
						alu_control <= 6'b000111;
					3'b101:
						if(outIns[31:25] == 7'b0000000) begin
							alu_control <= 6'b001000;
							// srli
						end
						else if(outIns[31:25] == 7'b0100000) begin
							alu_control <= 6'b001001;
							// srai
						end
				endcase
			end
		7'b0110011:
			begin
				muxB_control <= 0;
				addressA <= outIns[19:15];
				addressB <= outIns[24:20];
				addressC <= outIns[11:7];
				imm <= 0;
				case(outIns[14:12])
					3'b000:
						if(outIns[31:25] == 7'b0000000) begin
							alu_control <= 6'b001100;
							// add
						end else if(outIns[31:25] == 7'b0100000) begin
							if(outIns[19:15]==5'd0) begin
								alu_control <= 6'b001101;
								// neg
							end else begin
								alu_control <= 6'b001101;
								// sub
							end
						end
						else if(outIns[31:25] == 7'b0000001) begin
							alu_control <= 6'b011111;
							// mul
						end
					3'b001:
						if(outIns[31:25] == 7'b0000000) begin
							alu_control <= 6'b001110;
							// sll
						end
						else if(outIns[31:25] == 7'b0000001) begin
							alu_control <= 6'b100000;
							// mulh
						end
					3'b010:
						if(outIns[31:25] == 7'b0000000) begin
							if(outIns[19:15] == 5'd0) begin
								alu_control <= 6'b001111;
								// sgtz
							end else if(outIns[24:20] == 5'd0) begin
								alu_control <= 6'b001111;
								// sltz
							end else begin
								alu_control <= 6'b001111;
								// slt
							end
						end else if(outIns[31:25] == 7'b0000001) begin
							alu_control <= 6'b100001;
							// mulhsu
						end
					3'b011:
						if(outIns[31:25] == 7'b0000000) begin
							if(outIns[19:15] == 5'd0) begin
								alu_control <= 6'b010000;
								// snez
							end else begin
								alu_control <= 6'b010000;
								// sltu
							end
						end
						else if(outIns[31:25] == 7'b0000001) begin
							alu_control <= 6'b100010;
							// mulhu
						end
					3'b100:
						if(outIns[31:25] == 7'b0000000) begin
							alu_control <= 6'b010001;
							// xor
						end
						else if(outIns[31:25] == 7'b0000001) begin
							alu_control <= 6'b100011;
							// div
						end
					3'b101:
						if(outIns[31:25] == 7'b0000000) begin
							alu_control <= 6'b010010;
							// srl
						end else if(outIns[31:25] == 7'b0100000) begin
							alu_control <= 6'b010011;
							// sra
						end else if(outIns[31:25] == 7'b0000001) begin
							alu_control <= 6'b100100;
							// divu
						end
					3'b110:
						if(outIns[31:25] == 7'b0000000) begin
							alu_control <= 6'b010100;
							// or
						end else if(outIns[31:25] == 7'b0000001 ) begin
							alu_control <= 6'b100101;
							// rem
						end
					3'b111:
						if(outIns[31:25] == 7'b0000000) begin
							alu_control <= 6'b010101;
							// and
						end
						else if(outIns[31:25] == 7'b0000001) begin
							alu_control <= 6'b100110;
							// remu
						end
							
				endcase
			end
		7'b0111011:
			begin
				muxB_control <= 0; // non-immediate
				addressA <= outIns[19:15];
				addressB <= outIns[24:20];
				addressC <= outIns[11:7];
				imm <= 0;
				case(outIns[14:12])
					3'b000:
						if(outIns[31:25] == 7'b0000000) begin
							alu_control <= 6'b011010;
							//addw 
						end
						else if(outIns[31:25] == 7'b0100000) begin
							alu_control <= 6'b011011;
							if(outIns[19:15] == 5'd0) begin
								// negw
							end else begin
								// subw
							end
						end
						else if(outIns[31:25] == 7'b0000001) begin
							alu_control <= 6'b100111;
							// mulw
						end
					3'b001:
						alu_control <= 6'b011100;
						// sllw
					3'b101:
						if(outIns[31:25] == 7'b0000000) begin
							alu_control <= 6'b011101;
							//srlw
						end
						else if(outIns[31:25] == 7'b0100000) begin
							alu_control <= 6'b011110;
							//sraw 
						end
						else if(outIns[31:25] == 7'b0000001) begin
							alu_control <= 6'b101001;
							//divuw
						end
					3'b100:
						alu_control <= 6'b101000;
						//divw
					3'b110:
						alu_control <= 6'b101010;
						// remw
					3'b111:
						alu_control <= 6'b101011;
					    // remuw
					default:
						alu_control <= 0; 
				endcase
			end
		7'b0011011:
			begin
				muxB_control <= 1;
				addressA <= outIns[19:15];
				addressB <= 0;
				addressC <= outIns[11:7]; 
				imm <= {{52{outIns[31]}} , outIns[31:20]}; 
				case(outIns[14:12])
					3'b000:
						alu_control <= 6'b010110;
						// addiw
					3'b001:
						alu_control <= 6'b010111;
						// slliw
					3'b101:
						if(outIns[31:25] == 7'b0000000) begin
							alu_control <= 6'b011000;
							// srliw
						end
						else if(outIns[31:25] == 7'b0100000) begin
							alu_control <= 6'b011001;
							// sraiw
						end
					default:
						alu_control <= 0;
				endcase
			end
		default:
			alu_control <= 0;
	endcase
	
assign out_alu_control = alu_control;
assign out_addressA = addressA;
assign out_addressB = addressB;
assign out_addressC = addressC;
assign out_imm = imm;
assign out_muxB_control = muxB_control;

registerFile regFil (
	.alu_control(out_alu_control),
	.addressA(out_addressA),
	.addressB(out_addressB),
	.addressC(out_addressC),
	.muxB_control(out_muxB_control),
	.imm(out_imm)
);
 
 endmodule