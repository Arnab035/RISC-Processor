`include "Sysbus.defs"

module decoder
#(
  BUS_DATA_WIDTH = 64
)
(
  input  clk,
  input  decode_en,
  input  [BUS_DATA_WIDTH-1:0] data
);

`include "decode.sv"

  logic signed [63:0] pc = 0;

  always @ (posedge clk) begin
    if (decode_en) begin
	  pc <= pc + 8;
      decode(pc, data);
    end
  end
endmodule