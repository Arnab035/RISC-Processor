`include "Sysbus.defs"
`include "decode1.sv"
`include "registerFile.sv"
`include "alu.sv"


module fetcher
#(
  BUS_DATA_WIDTH = 64
)
(
  input  clk,
  input  fetch_en,
  input  [BUS_DATA_WIDTH-1:0] data,
  input count ,
  input end_of_cycle,
  
  output [31:0] outIns
);
 
logic low = 1;
reg [31:0] ins, outIns;

wire [5:0] out_alu_control;
wire [5:0] out1_alu_control;
wire [4:0] out_addressA;
wire [4:0] out_addressB;
wire [4:0] out_addressC;
wire [BUS_DATA_WIDTH-1 : 0] out_imm;
wire out_muxB_control;
wire write_en;
wire [BUS_DATA_WIDTH-1 : 0] dataA;
wire [BUS_DATA_WIDTH-1 : 0] dataB;
wire [BUS_DATA_WIDTH-1 : 0] dataOut;
wire [BUS_DATA_WIDTH-1 : 0] writeBack;
wire call_for_print, out_decode_en, out_reg_file_en, out_alu_en, out_writeBack_en;

logic r_decode_en;

always @ (posedge clk)
	if(fetch_en) begin
		if(low) begin
				ins <= data[31:0];
				low <= 0;
		end else begin
				ins <= data[63:32];
				low <= 1;
			end
		r_decode_en <= 1;
	end
	else begin
		r_decode_en <= 0;
	end
	
assign out_decode_en = r_decode_en;
	
assign outIns = ins;

decode1 d (
	.clk(clk),
	.end_of_cycle(end_of_cycle),
	.decode_en(out_decode_en),
	.outIns(outIns),
	.out_alu_control(out_alu_control),
	.out_addressA(out_addressA),
	.out_addressB(out_addressB),
	.out_addressC(out_addressC),
	.out_imm(out_imm),
	.out_muxB_control(out_muxB_control),
	.reg_file_en(out_reg_file_en)
);

registerFile rf (
	.clk(clk),
	.end_of_cycle(end_of_cycle),
	.reg_file_en(out_reg_file_en),
	.alu_control(out_alu_control),
	.muxB_control(out_muxB_control),
	.write_en(write_en),
	.call_for_print(call_for_print),
	.addressA(out_addressA),
	.addressB(out_addressB),
	.writeBack(dataOut),
	.addressC(out_addressC),
	.imm(out_imm),
	.dataA(dataA),
	.dataB(dataB),
	.out_alu_control(out1_alu_control),
	.out_alu_en(out_alu_en)
);

alu al (
	.clk(clk),
	.end_of_cycle(end_of_cycle),
	.alu_en(out_alu_en),
	.dataA(dataA),
	.dataB(dataB),
	.alu_control(out1_alu_control),
	.dataOut(dataOut),
	._aluOps(aluOps),
	.send_call_for_print(call_for_print),
	.write_en(write_en)
);

endmodule

