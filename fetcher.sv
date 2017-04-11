`include "Sysbus.defs"
`include "decode1.sv"
`include "alu.sv"
`include "data_memory.sv"
`include "writeback.sv"
`include "forwarding_unit_exe.sv"
`include "hazard_detection_unit.sv"
`include "adder.sv"

// many modules can be broken down further.. however not done now !!

module fetcher
#(
  BUS_DATA_WIDTH = 64
)
(
  input  clk,
  input  fetch_en,
  input  [BUS_DATA_WIDTH-1:0] data,
  input end_of_cycle,
  
  output [31:0] outIns
);
 
logic low = 1;
reg [31:0] ins, outIns;

// define all connecting wires here
logic r_decode_en;

always @ (posedge clk)
	if(fetch_en) begin
		if(low) begin
				ins <= data[31:0];
				low <= 0;
		end else begin
				ins <= data[63:32];
				low <= 1;
			end
		r_decode_en <= 1;
	end
	else begin
		r_decode_en <= 0;
	end
	
assign out_decode_en = r_decode_en;
	
assign outIns = ins;

wire wbRegWrite;
wire [4:0] wbDestReg;
wire [BUS_DATA_WIDTH-1 : 0] wbMemOrRegData;
wire idBranch;
wire idPCSrc;
wire idMemRead;
wire idMemWrite;
wire idRegWrite;
wire idMemOrReg;
wire [5:0] aluControl;
wire [BUS_DATA_WIDTH-1 : 0] idReadData1;
wire [BUS_DATA_WIDTH-1 : 0] idReadData2;
wire [4:0] idDestRegister;
wire [BUS_DATA_WIDTH-1 : 0] idImm;
wire [4:0] idRegisterRs;
wire [4:0] idRegisterRt;
wire [BUS_DATA_WIDTH-1 : 0] idPc;

decode1 d (
	.clk(clk),
	.pc(pc),
	.outIns(outIns),
	.decode_en(out_decode_en),
	.inRegWrite(wbRegWrite),    // regwrite signal comes from mem/wb stage, so do the below two signals
	.inDestReg(wbDestReg),
	.inMemOrRegData(wbMemOrRegData),
	.end_of_cycle(end_of_cycle),
	.outBranch(idBranch),
	.outPCSrc(idPCSrc),
	.outMemRead(idMemRead),
	.outMemWrite(idMemWrite),
	.outRegWrite(idRegWrite),
	.outMemOrReg(idMemOrReg),
	.outAluControl(aluControl),
	.outReadData1(idReadData1),
	.outReadData2(idReadData2),
	.outDestRegister(idDestRegister),
	.outImm(idImm),
	.outRegisterRs(idRegisterRs),
	.outRegisterRt(idRegisterRt),
	.outPc(idPc)
);

wire exMemRead;
wire [4:0] exRegisterRt;
wire ifPCWrite;
wire ifIfIdWrite;
wire idCtrlMux;

hazard_detection_unit hdu (
	.inMemReadId(exMemRead),
	.inRegisterRt(exRegisterRt),
	.outIns(outIns),
	.outPCWrite(ifPCWrite),
	.outIfIdWrite(ifIfIdWrite),
	.outCtrlMux(idCtrlMux)
);

wire [BUS_DATA_WIDTH-1 : 0] exResult;
wire [BUS_DATA_WIDTH-1 : 0] memResult;
wire fwdLogicA;
wire fwdLogicB;
wire [4:0] exDestReg;
wire exBranch;
wire exMemRead;
wire exMemWrite;
wire exMemOrReg;
wire exPCSrc;
wire exRegWrite;
wire exZero;

alu al (
	.clk(clk),
	.end_of_cycle(end_of_cycle),
	.inDataReg1(idReadData1),
	.inDataReg2(idReadData2),
	.inAluControl(aluControl),
	.inBranch(idBranch),
	.inMemRead(idMemRead),
	.inMemWrite(idMemWrite),
	.inMemOrReg(idMemOrReg),
	.inRegisterRs(idRegisterRs),
	.inRegisterRt(idRegisterRt),
	.inPCSrc(idPCSrc),
	.inRegWrite(idRegWrite),
	.inImm(idImm),
	.inDestReg(idDestReg),
	.inExResult(exResult),
	.inMemResult(memResult),
	.forwardingLogicA(fwdLogicA),
	.forwardingLogicB(fwdLogicB),
	.outDestReg(exDestReg),
	.outBranch(exBranch),
	.outMemRead(exMemRead),
	.outMemWrite(exMemWrite),
	.outMemOrReg(exMemOrReg),
	.outPCSrc(exPCSrc),
	.outRegWrite(exRegWrite),
	.outZero(exZero),
	.outRegisterRt(exRegisterRt),
	.outResult(exResult)
);

wire [BUS_DATA_WIDTH-1 : 0] ifBta;

adder add (
	.clk(clk),
	.inPc(idPc),
	.inImm(idImm),
	.outBta(ifBta)
);

wire [4:0] memDestReg;
wire memRegWrite;

forwarding_unit_exe funit (
	.inRegisterRsId(idRegisterRs),
	.inRegisterRtId(idRegisterRt),
	.inRegisterRdEx(exDestReg),
	.inRegisterRdMem(memDestReg),
	.inRegWriteEx(exRegWrite),
	.inRegWriteMem(memRegWrite),
	.outForwardA(fwdLogicA),
	.outForwardB(fwdLogicB)
);

wire [BUS_DATA_WIDTH-1 : 0] memReadData;
wire [BUS_DATA_WIDTH-1 : 0] memResult;
wire memMemOrReg;
wire memPcSrc;

data_memory dmem (
	.clk(clk),
	.inRegWrite(exRegWrite),
	.inDestReg(exDestReg),
	.inResult(exResult),
	.writeData(exWriteData),     // write data for stores
	.inMemOrReg(exMemOrReg),
	.inMemWrite(exMemWrite),
	.inPcSrc(exPCSrc),
	.inBranch(exBranch),
	.inZero(exZero),
	.inBta(ifBta),
	.readData(memReadData),   // using load instruction, read data
	.outDestReg(memDestReg),
	.outResult(memResult),
	.outMemOrReg(memMemOrReg),
	.outRegWrite(memRegWrite),
	.outPcSrc(memPcSrc),
	.outBta(ifBta)
);

wire [BUS_DATA_WIDTH-1 : 0] wbMemOrRegData;
wire [4:0] wbDestReg;
wire wbRegWrite;

writeback wb (
	// no clock
	.inMemOrReg(memMemOrReg),
	.inReadData(memReadData),
	.inALUData(memResult),
	.inDestReg(memDestReg),
	.inRegWrite(memRegWrite),
	.outMemOrRegData(wbMemOrRegData),
	.outDestReg(wbDestReg),
	.outRegWrite(wbRegWrite)
);

endmodule

