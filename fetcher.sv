module fetcher
#(
  BUS_DATA_WIDTH = 64,
  BUS_TAG_WIDTH = 13
)
(
  input  clk,
  input  [63:0] pc,
  input  bus_respcyc,
  input  [BUS_DATA_WIDTH-1:0] bus_resp,
  input  [BUS_TAG_WIDTH-1:0] bus_resptag,
  input  inIdWrite,
  input  inPCWrite,
  output bus_reqcyc,
  output [BUS_DATA_WIDTH-1:0] bus_req,
  output [BUS_TAG_WIDTH-1:0] bus_reqtag,
  output bus_respack,

  output [BUS_DATA_WIDTH-1:0] out_addr,
  output [31:0] out_pr_data
);

  logic [BUS_DATA_WIDTH:0] addr;
  logic [BUS_DATA_WIDTH:0] pr_pc;
  logic [31:0] pr_data;
  logic [BUS_DATA_WIDTH:0] naddr;
  // logic decode_en;
  logic send_respack=0;

  always_ff @ (posedge clk) begin
    if (pc % 64 == 0) begin
      bus_req <= pc;
      bus_reqtag[12] <= 1;
      bus_reqtag[11:8] <= 4'b0001;
      bus_reqcyc <= 1;
    end else begin
      bus_req <= 0;
      bus_reqtag <= 0;
      bus_reqcyc <= 0;
    end
  end

  assign naddr = addr + 4;
  
  always_ff @ (posedge clk) begin
    if (bus_respcyc && send_respack) begin
      pr_pc <= addr;
      if(inIdWrite == 0) begin
        addr <= naddr;
        pr_data <= bus_resp[63:32];
      end
      bus_respack <= 1;
      if (bus_resp == 0) begin
	       $finish;
      end
      send_respack <= 0;
    end 
    else if(bus_respcyc && !send_respack) begin
      pr_pc <= addr;
      if(inIdWrite == 0) begin
        addr <= naddr;
        pr_data <= bus_resp[31:0];
      end
      bus_respack <= 0;
      if (bus_resp == 0) begin
         $finish;
      end
      if(inPCWrite == 0) begin
        send_respack <= 1;
      end    	
    end
    else begin
      send_respack <= 0;
      bus_respack <= 0;
      pr_data <= 0;
    end
  end

  assign out_addr = addr;
  assign out_pr_data = pr_data;

endmodule	