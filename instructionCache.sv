// a direct-memory mapped cache for starters

`include "Sysbus.defs"

module instructionCache
# (
	BUS_DATA_WIDTH = 64
)
(
	input clk,
	input reset,
	
	input [BUS_DATA_WIDTH-1 : 0] pc,
	input grant,
	
	input [BUS_DATA_WIDTH-1 : 0] resp,
	input [BUS_TAG_WIDTH-1 : 0] resptag,
	input respcyc,
	input reqack,
	
	output bid,
	output [BUS_TAG_WIDTH-1 : 0] reqtag,
	output reqcyc,
	output respack,
	output [BUS_DATA_WIDTH-1 : 0] req
);

logic [63:0] addr = pc;
  
logic [BUS_DATA_WIDTH-1:0] pr_data;
logic [63:0] pr_pc;
  // to update addr on receiving bus resp
logic [63:0] naddr;

// the below operations happen when there is a cache miss

enum {
	CACHE_FETCH = 2'b00,
	CACHE_WAIT = 2'b01,
	CACHE_FILLED = 2'b10
} state;

always_comb begin
	if(mem[addr] && valid) begin
		hit = 1;
	end else miss = 1;
end

always_comb begin
	if(miss && state==CACHE_FETCH) begin
		bid = 1;   // this is an input to the arbiter , who will reply with a bus_grant message
	end
end

// addr stores address sent during bus request
  
always_ff @ (posedge clk) begin
    if (reset);
	else if(hit) begin
	  fetch_en <= 1;
    else if (state == CACHE_FETCH && grant) begin
      req <= addr;
      reqtag[12] <= 1;
      reqtag[11:8] <= 4'b0001;
      reqcyc <= 1;
      state <= CACHE_WAIT;
    end else begin
      req <= 0;
      reqtag <= 0;
      reqcyc <= 0;
    end
 end

assign naddr = addr + 8;
  
always_ff @ (posedge clk) begin
    if (bus_respcyc) begin
      state <= CACHE_FILLED;
      pr_pc <= addr;
      addr <= naddr;
      mem[pc] <= resp;
      respack <= 1;    	
      if (bus_resp == 0)
		$finish;
      else
        fetch_en <= 1;       // next clock pulse start fetching from cache
    end else begin
      if (state == CACHE_FILLED) begin
        state <= CACHE_FETCH;
      end
      respack <= 0;    	
      fetch_en <= 0;
    end
end