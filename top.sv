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

  logic [63:0] pc, ir, naddr;
  logic [5:0] count, count_next;
  logic fetch_en;
  
  enum {state_init = 2'b00, 
		state_bus_request_sent = 2'b01, 
		state_stop_bus_request = 2'b10, 
		state_receive_bus_data = 2'b11, state_dummy} state, next_state;
	
  // next-state logic //
  always_comb begin
    case(state)	
		state_init:
			if(!reset) begin
				next_state = state_bus_request_sent;
			end else begin
				next_state = state_init;
			end
		state_bus_request_sent:
			if(bus_reqack) begin
				next_state = state_stop_bus_request;
			end else begin
				next_state = state_bus_request_sent;
			end
		state_stop_bus_request:
			if(bus_respcyc) begin
				next_state = state_receive_bus_data;
			end else begin
				next_state = state_stop_bus_request;
			end
		state_dummy:
			begin
				next_state = state_receive_bus_data;
				naddr = pc + 8;
			end
		state_receive_bus_data:
			if(bus_respcyc) begin
				next_state = state_dummy;
			end else begin
				next_state = state_init;
			end
	endcase
  end
  
  always @ (posedge clk)
    if (reset) begin
      pc <= entry;
	  state <= state_init;
	end else begin
	  state <= next_state;
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
				fetch_en <= 0;
			end
		state_bus_request_sent:
			begin
				bus_req <= pc;
				bus_reqtag <= 13'b1000100000000 ;
				bus_reqcyc <= 1;
				bus_respack <= 0;
			end
		state_stop_bus_request:
			begin
				bus_req <= 0;
				bus_reqtag <= 0;
				bus_reqcyc <= 0;
				bus_respack <= 0;
			end
		state_dummy:
			begin
				bus_req <= 0;
				bus_reqtag <= 0;
				bus_reqcyc <= 0;
				bus_respack <= 0;
				fetch_en <= 1;
			end
		state_receive_bus_data:
			begin
				count <= count_next;
				fetch_en <= 1;
				pc <= naddr;
				bus_req <= 0;
				bus_reqtag <= 0;
				bus_reqcyc <= 0;
				bus_respack <= 1;
				ir <= bus_resp;
				if(bus_resp == 0) begin
					//$finish;
					end_of_cycle <= 1;
				end
			end
	endcase
	
  
  initial begin
    $display("Initializing top, entry point = 0x%x", entry);
  end
  
  fetcher f (
	.clk(clk),
	.fetch_en(fetch_en),
	.data(ir),
	.count(count),
	.end_of_cycle(end_of_cycle)
  );
  
  
 
 endmodule