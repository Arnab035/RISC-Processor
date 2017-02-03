`include "Sysbus.defs"

module top
#(
  BUS_DATA_WIDTH = 64,
  BUS_TAG_WIDTH = 13
)
(
  input  clk,
         reset,

  // 64-bit address of the program entry point
  input  [63:0] entry,
  
  // interface to connect to the bus
  output bus_reqcyc,
  output bus_respack,
  output [BUS_DATA_WIDTH-1:0] bus_req,
  output [BUS_TAG_WIDTH-1:0] bus_reqtag ,
  input  bus_respcyc,
  input  bus_reqack,
  input  [BUS_DATA_WIDTH-1:0] bus_resp,
  input  [BUS_TAG_WIDTH-1:0] bus_resptag
);

  logic [63:0] pc;
  logic [63:0] ir;
  logic a = 1;

  always @ (posedge clk)
    if (reset) begin
      pc <= entry;
      
    end 
    else begin
      
      if(pc && !bus_resp) begin
        $finish;
      end

      else if(bus_reqack) begin
        bus_reqcyc <= 0;
      end

      else if(bus_respcyc) begin
        ir <= bus_resp;
        $display(ir);
        pc <= pc + 8;
        bus_respack <= 1;
      end

      else if(pc % 64 == 0) begin
        bus_reqcyc <= 1;
        bus_req <= pc;
        bus_respack <= 0;
      end
      

  end

  initial begin
    $display("Initializing top, entry point = 0x%x", entry);
    bus_reqcyc = 1;
    bus_req = entry;
    bus_reqtag = 13'b1000100000000 ;
  end
endmodule
