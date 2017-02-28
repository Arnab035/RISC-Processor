`include "Sysbus.defs"
`include "decode1.sv"
`include "registerFile.sv"
`include "alu.sv"
`include "writeback.sv"

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
wire call_for_print;

always @ (posedge clk) 
	if(fetch_en) begin
		$display(data);
		if(low) begin
				ins <= data[31:0];
				low <= 0;
		end else begin
				ins <= data[63:32];
				low <= 1;
			end
	end
	

	
assign outIns = ins;

decode1 d (
	.clk(clk),
	.end_of_cycle(end_of_cycle),
	.fetch_en(fetch_en),
	.outIns(outIns),
	.out_alu_control(out_alu_control),
	.out_addressA(out_addressA),
	.out_addressB(out_addressB),
	.out_addressC(out_addressC),
	.out_imm(out_imm),
	.out_muxB_control(out_muxB_control)
);

registerFile rf (
	.clk(clk),
	.end_of_cycle(end_of_cycle),
	.fetch_en(fetch_en),
	.alu_control(out_alu_control),
	.muxB_control(out_muxB_control),
	.write_en(write_en),
	.call_for_print(call_for_print),
	.addressA(out_addressA),
	.addressB(out_addressB),
	.writeBack(writeBack),
	.addressC(out_addressC),
	.imm(out_imm),
	.dataA(dataA),
	.dataB(dataB),
	.out_alu_control(out1_alu_control)
);

alu al (
	.clk(clk),
	.end_of_cycle(end_of_cycle),
	.fetch_en(fetch_en),
	.dataA(dataA),
	.dataB(dataB),
	.alu_control(out1_alu_control),
	.dataOut(dataOut),
	._aluOps(aluOps)
);

writeback wb (
	.clk(clk),
	.end_of_cycle(end_of_cycle),
	.fetch_en(fetch_en),
	.dataOut(dataOut),
	.y(writeBack),
	.out_write_en(write_en),
	._aluOps(aluOps),
	.call_for_print(call_for_print)
);

endmodule

