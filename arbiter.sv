module arbiter 
#(
	BUS_DATA_WIDTH = 64,
	BUS_TAG_WIDTH = 13
)
(
	input clk,
	input reset,

	// interface to top
	output [BUS_DATA_WIDTH-1 : 0] bus_req,
	output bus_reqcyc,
	output [BUS_TAG_WIDTH-1 : 0] bus_reqtag,
	output bus_respack,
	input bus_respcyc,
	input bus_reqack,
	input [BUS_DATA_WIDTH-1 : 0] bus_resp,
	input [BUS_TAG_WIDTH-1 : 0] bus_resptag,
	
	// bus fetcher
	input [BUS_DATA_WIDTH-1 : 0] ibus_req,
	input ibus_reqcyc,
	input [BUS_TAG_WIDTH-1 : 0] ibus_reqtag,
	input ibus_respack,
	output ibus_respcyc,
	output [BUS_DATA_WIDTH-1 : 0] ibus_resp,
	output [BUS_TAG_WIDTH - 1 : 0] ibus_resptag,
	
	// bus data
	input [BUS_DATA_WIDTH-1 : 0] dbus_req,
	input dbus_reqcyc,
	input [BUS_TAG_WIDTH-1 : 0] dbus_reqtag,
	input dbus_respack,
	output dbus_respcyc,
	output [BUS_DATA_WIDTH-1 : 0] dbus_resp,
	output [BUS_TAG_WIDTH - 1 : 0] dbus_resptag
);

always_comb begin
	bus_req = 0;
	bus_reqcyc = 0;
	bus_reqtag = 0;
	if(ibus_req) begin
		bus_req = ibus_req;
		bus_reqcyc = ibus_reqcyc;
		bus_reqtag = ibus_reqtag;
	end
end

always_comb begin
	bus_req = 0;
	bus_reqcyc = 0;
	bus_reqtag = 0;
	if(dbus_req) begin
		bus_req = dbus_req;
		bus_reqcyc = dbus_reqcyc;
		bus_reqtag = dbus_reqtag;
	end
end

always_comb begin
	bus_respack = 0;
	if(ibus_respack) begin
		bus_respack = ibus_respack;
	end else if(dbus_respack) begin
		bus_respack = dbus_respack;
	end
end

always_comb begin
	ibus_respcyc = 0;
	ibus_resp = 0;
	ibus_resptag = 0;
	//ibus_reqack = 0;
	if(bus_respcyc) begin
		ibus_respcyc = bus_respcyc;
		ibus_resp = bus_resp;
		ibus_resptag = bus_resptag;
		//ibus_reqack = bus_reqack;
	end
end

always_comb begin
	dbus_respcyc = 0;
	dbus_resp = 0;
	dbus_resptag = 0;
	//dbus_reqack = 0;
	if(bus_respcyc) begin
		dbus_respcyc = bus_respcyc;
		dbus_resp = bus_resp;
		dbus_resptag = bus_resptag;
		//dbus_reqack = bus_reqack;
	end
end
	
endmodule
