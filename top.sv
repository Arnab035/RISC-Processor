`include "Sysbus.defs"
//`include "fetcher.sv"

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
  output [BUS_TAG_WIDTH-1:0] bus_reqtag,
  input  bus_respcyc,
  input  bus_reqack,
  input  [BUS_DATA_WIDTH-1:0] bus_resp,
  input  [BUS_TAG_WIDTH-1:0] bus_resptag
);

  logic [63:0] pc, ir;

  enum {state_init = 2'b00, 
		state_bus_request_sent = 2'b01, 
		state_stop_bus_request = 2'b10, 
		state_receive_bus_data = 2'b11} state, next_state;
	
  // next-state logic //
  always_comb begin
    case(state)	
		state_init:
			if(!reset) begin
				next_state = state_bus_request_sent ;
			end else begin
				next_state = state_init ;
			end
		state_bus_request_sent:
			if(bus_reqack) begin
				next_state = state_stop_bus_request ;
			end else begin
				next_state = state_bus_request_sent ;
			end
		state_stop_bus_request:
			if(bus_respcyc) begin
				next_state = state_receive_bus_data ;
			end else begin
				next_state = state_stop_bus_request ;
			end
		state_receive_bus_data:
			begin
				if(bus_respcyc) begin
					decode_en = 1;
					next_state = state_receive_bus_data ;
				end else begin
					next_state = state_init ;
					decode_en = 0;
				end
			end
		endcase
  end

  always @ (posedge clk)
    if (reset) begin
      pc <= entry;
	  state <= state_init;
    end else begin
	  state <= next_state;
	  if(state != next_state && next_state == state_stop_bus_request) begin
		bus_req <= 0;
		bus_reqtag <= 0;
		bus_reqcyc <= 0;
		bus_respack <= 0;
		pc <= pc + 64;
	  end
	end
	
	// always ff output logic //
  always_ff @ (posedge clk)
	case(state)
		state_init:
			begin
				bus_req <= 0;
				bus_reqtag <= 0;
				bus_respack <= 0;
				bus_reqcyc <= 0;
			end
		state_bus_request_sent:
			begin
				bus_req <= pc;
				bus_reqtag <= 13'b1000100000000 ;
				bus_reqcyc <= 1;
				bus_respack <= 0;
			end
		state_receive_bus_data:
			begin
				bus_req <= 0;
				bus_reqtag <= 0;
				bus_reqcyc <= 0;
				bus_respack <= 1;
				if(bus_resp == 0) begin
					$finish;
				end
				ir <= bus_resp;
			end
	endcase
  
  
  initial begin
    $display("Initializing top, entry point = 0x%x", entry);
  end
  
   decoder d (
    .clk (clk),
    .decode_en (decode_en),
    .data(bus_resp)
  );

  /*
  fetcher f (
    .clk (clk),
    .pc (pc),
    .bus_respcyc (bus_respcyc),
    .bus_resp (bus_resp),
    .bus_reqcyc (bus_reqcyc),
    .bus_req (bus_req),
    .bus_reqtag (bus_reqtag),
    .bus_respack (bus_respack)
  );
  */
endmodule