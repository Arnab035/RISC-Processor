`include "Sysbus.defs"


/* register file module */

/* inputs and outputs for register file 
1. 3 address inputs and
2. 1 data input 
2.a) 1 immediate input
3. 2 data outputs */

module registerFile
#(
	BUS_DATA_WIDTH = 64
)
(   
	input clk,
	input end_of_cycle,
	input fetch_en,
	input [5:0] alu_control,   // which alu operation to perform
	input muxB_control, // multiplexer selects immediate or register
    input write_en,  // ALU SETS THE WRITE-EN LOGIC
	input [4:0] addressA, 
	input [4:0] addressB,
	input [BUS_DATA_WIDTH-1 : 0] writeBack,  /* comes from the writeback module */
	input [4:0] addressC,
	input [BUS_DATA_WIDTH-1 : 0] imm,
	input call_for_print,
	
	output [BUS_DATA_WIDTH-1 : 0] dataA, /* go to the ALU */
	output [BUS_DATA_WIDTH-1 : 0] dataB,
	output [5:0] out_alu_control
);

reg [BUS_DATA_WIDTH-1 : 0] rA, rB;

reg [5:0] _alu_control;

reg [BUS_DATA_WIDTH-1 : 0] mem[31:0]; 
// 32 * 64 register file

assign mem[0] = 0;

always @ (posedge clk) 
    if(fetch_en) begin
		_alu_control <= alu_control;
		if(write_en) begin
			$display(writeBack);
			mem[addressC] <= writeBack ;
		end
		rA <= mem[addressA];
		if(muxB_control) begin // imm
			rB <= imm;
		end else begin
			rB <= mem[addressB];
		end
	end
  
  
 always @ (posedge clk) 
	if(call_for_print) begin
		print_registers();
	end
	
assign dataA = rA;
assign dataB = rB;
assign out_alu_control = _alu_control;

function void print_registers;
    int i;
	for(i = 0; i < 32; i++) begin
		$display("Reg %x: %x ", i+1, mem[i]);
	end
	$finish;
endfunction

endmodule












