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
  output end_of_cycle,
  output bus_reqcyc,
  output bus_respack,
  output [BUS_DATA_WIDTH-1:0] bus_req,
  output [BUS_TAG_WIDTH-1:0] bus_reqtag,
  input  bus_respcyc,
  input  bus_reqack,
  input  [BUS_DATA_WIDTH-1:0] bus_resp,
  input  [BUS_TAG_WIDTH-1:0] bus_resptag
);

// instruction cache defined here -- ins cache communicates with the bus make sure 

wire [BUS_DATA_WIDTH-1 : 0] pc;

always @ (posedge clk)
    if (reset) begin
      pc <= entry;
    end 
	
wire bus_bid;
wire bus_grant;


instructionCache ich (
		.clk(clk),
		.reset(reset),
		.pc(pc),
		.grant(bus_grant),
		.respcyc(bus_respcyc),
		.resp(bus_resp),
		.reqack(bus_reqack),
		.resptag(bus_resptag),
		
		// list of outputs
		.bid(bus_bid),
		.reqcyc(bus_reqcyc),
		.respack(bus_respack),
		.req(bus_req),
		.reqtag(bus_reqtag)
);

arbiter ab (
	.bus_bid(bus_bid),
	.bus_grant(bus_grant)
);

dataCache dch (
		.clk(clk),
		.reset(reset),
		
		.grant(bus_grant),
		.reqcyc(bus_reqcyc),
		.respack(bus_respack),
		.req(bus_req),
		.resptag(bus_resptag),
		
		// list of outputs
		.bid(bus_bid),
		.reqcyc(bus_reqcyc),
		.respack(bus_respack),
		.req(bus_req),
		.reqtag(bus_reqtag)
);

endmodule