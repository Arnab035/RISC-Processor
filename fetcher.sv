module fetcher
#(
  BUS_DATA_WIDTH = 64,
  BUS_TAG_WIDTH = 13
)
(
  input  clk,
  input  reset,
  input  [63:0] pc,
  input  bus_respcyc,
  input  [BUS_DATA_WIDTH-1:0] bus_resp,
  input  [BUS_TAG_WIDTH-1:0] bus_resptag,
  input   bus_reqack,
  input  inMiss,
  output out_do_invalidate,
  output [63:0] out_invalid_phys_addr,
  output bus_reqcyc,
  output [9:0] out_offset,
  output [BUS_DATA_WIDTH-1:0] bus_req,
  output [BUS_TAG_WIDTH-1:0] bus_reqtag,
  output bus_respack,
  output [511:0] out_data
);

`include "Sysbus.defs"

logic [9:0] offset = 0;
logic do_invalidate = 0;
logic [63:0] invalid_phys_addr;

enum {
  STATE_FETCH = 2'b00,
  STATE_WAIT = 2'b01,
  STATE_WAIT_ONE_CLK = 2'b10
} state;

logic [BUS_DATA_WIDTH:0] addr;
logic [BUS_DATA_WIDTH:0] pr_pc;
logic [511:0] buffer;
logic [BUS_DATA_WIDTH:0] naddr;

always_ff @ (posedge clk) begin
  if(inMiss && state == STATE_FETCH) begin
    bus_req <= pc & ~63;
    bus_reqtag[12] <= 1;
    bus_reqtag[11:8] <= 4'b0001;
    bus_reqcyc <= 1;
    state <= STATE_WAIT;
  end else begin
    bus_req <= 0;
    bus_reqtag <= 0;
    bus_reqcyc <= 0;
  end
end

// 64 byte data read from memory

always_ff @ (posedge clk) begin
  if (bus_respcyc && offset <= 64 * 8) begin
    if(bus_resptag == 13'b0100000000000) begin
      bus_respack <= 1;
      do_invalidate <= 1;
      invalid_phys_addr <= bus_resp;
    end else begin
      buffer[offset +: 64] <= bus_resp ;
      bus_respack <= 1;
      offset <= offset + 64;
      do_invalidate <= 0;
      invalid_phys_addr <= 0;
    end
  end else begin
    bus_respack <= 0;
    offset <= 0;
    out_offset <= offset;
    out_data <= buffer;
    if(offset >= 64 * 8  && state == STATE_WAIT)
        state <= STATE_WAIT_ONE_CLK;
    do_invalidate <= 0;
    invalid_phys_addr <= 0;
  end
end

// pause for 2 clock cycles
logic wait_time = 0;

always_ff @ (posedge clk) begin
  if(state == STATE_WAIT_ONE_CLK) begin
    wait_time <= 1; 
    if(wait_time) begin
      wait_time <= 0;
      state <= STATE_FETCH;
    end
  end
end


assign out_invalid_phys_addr = invalid_phys_addr;
assign out_do_invalidate = do_invalidate;


endmodule	