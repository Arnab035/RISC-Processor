
// arbiter is a state machine which will have two states :- either being idle or busy
// this will allow at one time either the instruction cache or the data cache to access
// the bus and the memory controller subsequently

module arbiter
(
	input bus_bid1,
	input clk,
	input reset,
	input bus_bid2,
	
	output bus_grant1,
	output bus_grant2
)

enum {
	IDLE,
	IC_BUSY,
	DC_BUSY
} state, next_state;

always_comb begin
	// next state logic
	case(state) begin
		IDLE:
			begin
				if(bus_bid1 && bus_bid2) begin
					next_state = DC_BUSY;
				end else if(bus_bid1) begin
					next_state = IC_BUSY;
				end else if(bus_bid2) begin
					next_state = DC_BUSY;
				end
			end
		IC_BUSY:
			begin
				if(!bus_bid1) begin
					next_state = IDLE;
				end
			end
		DC_BUSY:
			begin
				if(!bus_bid2) begin
					next_state = IDLE;
				end 
			end
	endcase
end

always @ (posedge clk)  //for transition of states
  begin
	if(reset)
		state <=IDLE;
	else
		state <= next_state;
	end 

// output logic
always_comb begin
	case(state) 
		IDLE:
			begin
				bus_grant1 = 0;
				bus_grant2 = 0;
			end
		IC_BUSY:
			begin
				bus_grant1 = 1;
				bus_grant2 = 0;
			end
		DC_BUSY:
			begin
				bus_grant1 = 0;
				bus_grant2 = 1;
			end
	endcase
end



