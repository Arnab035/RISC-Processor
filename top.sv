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

  logic [63:0] pc, npc;


  always_comb begin
    if(dmem_pcsrc == 0) begin
      npc = pc + 4;
    end else begin
      npc = dmem_addrjump;
    end
  end

  always @ (posedge clk)
    if (reset) begin
      pc <= entry;
    end else begin
      pc <= npc;
    end

  initial begin
    $display("Initializing top, entry point = 0x%x", entry);
  end

  logic [63:0] ftbus_req, ftbus_resp;
  logic ftbus_reqcyc, ftbus_respack, ftbus_respcyc;
  logic [12:0] ftbus_reqtag, ftbus_resptag;

  logic [63:0] dbus_req, dbus_resp;
  logic dbus_reqcyc, dbus_respack, dbus_respcyc;
  logic [12:0] dbus_reqtag, dbus_resptag;

  arbiter ab(
    .clk(clk),
    .reset(reset),
    .ibus_req(ftbus_req),
    .ibus_reqcyc(ftbus_reqcyc),
    .ibus_reqtag(ftbus_reqtag),
    .ibus_respack(ftbus_respack),
    .ibus_respcyc(ftbus_respcyc),
    .ibus_resp(ftbus_resp),
    .ibus_resptag(ftbus_resptag),
    .dbus_req(dbus_req),
    .dbus_reqcyc(dbus_reqcyc),
    .dbus_reqtag(dbus_reqtag),
    .dbus_respack(dbus_respack),
    .dbus_respcyc(dbus_respcyc),
    .dbus_resp(dbus_resp),
    .dbus_resptag(dbus_resptag),
    .bus_req(bus_req),
    .bus_reqcyc(bus_reqcyc),
    .bus_reqtag(bus_reqtag),
    .bus_respack(bus_respack),
    .bus_respcyc(bus_respcyc),
    .bus_resp(bus_resp),
    .bus_resptag(bus_resptag),
    .bus_reqack(bus_reqack)
  );

  logic [BUS_DATA_WIDTH-1:0] ft_addr;
  logic [31:0] ft_pr_data;

  fetcher ft(
    .clk(clk),
    .pc(pc),
    .bus_req(ftbus_req),
    .bus_reqcyc(ftbus_reqcyc),
    .bus_reqtag(ftbus_reqtag),
    .bus_resp(ftbus_resp),
    .bus_respcyc(ftbus_respcyc),
    .bus_resptag(ftbus_resptag),
    .bus_respack(ftbus_respack),
    .out_addr(ft_addr),
    .out_pr_data(ft_pr_data)
  );

  logic dec_branch, dec_pcsrc, dec_memread, dec_memwrite, dec_regwrite, dec_memorreg;
  logic [5:0] dec_alucontrol;
  logic [BUS_DATA_WIDTH-1:0] dec_readdata1, dec_readdata2, dec_imm, dec_pc;
  logic [4:0] dec_registerrs, dec_registerrt, dec_destregister;

  decode1 dc(
    .clk(clk),
    .pc(ft_addr),
    .outIns(ft_pr_data),
    .outBranch(dec_branch),
    .outPCSrc(dec_pcsrc),
    .outMemRead(dec_memread),
    .outMemWrite(dec_memwrite),
    .outRegWrite(dec_regwrite),
    .outMemOrReg(dec_memorreg),
    .outAluControl(dec_alucontrol),
    .outReadData1(dec_readdata1),
    .outReadData2(dec_readdata2),
    .outImm(dec_imm),
    .outPc(dec_pc),
    .outRegisterRs(dec_registerrs),
    .outRegisterRt(dec_registerrt),
    .outDestRegister(dec_destregister)
);

logic [1:0] fwd_forwarda, fwd_forwardb;

forwardingunit fw(
    .inRegisterRs(dec_registerrs),
    .inRegisterRt(dec_registerrt),
    .inDestRegisterEx(alu_destregister),
    .inDestRegisterMem(dmem_destregister),
    .inRegWriteEx(alu_regwrite),
    .inRegWriteMem(dmem_regwrite),
    .outForwardA(fwd_forwarda),
    .outForwardB(fwd_forwardb)
);

logic [4:0] alu_destregister;
logic alu_branch,alu_memread, alu_memwrite, alu_memorreg,alu_pcsrc, alu_regwrite, alu_zero;
logic [BUS_DATA_WIDTH-1 : 0] alu_addrjump, alu_result, alu_datareg2;

alu al(
    .clk(clk),
    .inPc(dec_pc),
    .inDataReg1(dec_readdata1),
    .inDataReg2(dec_readdata2),
    .inAluControl(dec_alucontrol),
    .inBranch(dec_branch),
    .inMemRead(dec_memread),
    .inMemWrite(dec_memwrite),
    .inMemOrReg(dec_memorreg),
    .inPCSrc(dec_pcsrc),
    .inRegWrite(dec_regwrite),
    .inImm(dec_imm),
    .inDestRegister(dec_destregister),
    .outDestRegister(alu_destregister),
    .outBranch(alu_branch),
    .outMemRead(alu_memread),
    .outMemWrite(alu_memwrite),
    .outMemOrReg(alu_memorreg),
    .outPCSrc(alu_pcsrc),
    .outRegWrite(alu_regwrite),
    .outZero(alu_zero),
    .outAddrJump(alu_addrjump),
    .outResult(alu_result),
    .outDataReg2(alu_datareg2)
);


logic [BUS_DATA_WIDTH-1:0] dmem_addrjump, dmem_readdata;
logic [4:0] dmem_destregister;
logic dmem_memorreg;
logic dmem_regwrite, dmem_pcsrc;

datamemory dm(
    .clk(clk),
    .inDestRegister(alu_destregister),
    .inBranch(alu_branch),
    .inMemRead(alu_memread),
    .inMemWrite(alu_memwrite),
    .inMemOrReg(alu_memorreg),
    .inPCSrc(alu_pcsrc),
    .inRegWrite(alu_regwrite),
    .inZero(alu_zero),
    .inAddrJump(alu_addrjump),
    .inResult(alu_result),
    .inDataReg2(alu_datareg2),
    .bus_respcyc(dbus_respcyc),
    .bus_resp(dbus_resp),
    .bus_resptag(dbus_resptag),
    .bus_reqcyc(dbus_reqcyc),
    .bus_req(dbus_req),
    .bus_reqtag(dbus_reqtag),
    .bus_respack(dbus_respack),
    .outPCSrc(dmem_pcsrc),
    .outAddrJump(dmem_addrjump),
    .outReadData(dmem_readdata),
    .outResult(dmem_result),
    .outDestRegister(dmem_destregister),
    .outMemOrReg(dmem_memorreg),
    .outRegWrite(dmem_regwrite)
  );

logic [BUS_DATA_WIDTH-1:0] wback_regdata;
logic [4:0] wback_destregister;
logic wback_regwrite;

writeback wb(
  .inMemOrReg(dmem_memorreg),
  .inReadData(dmem_readdata),
  .inResult(dmem_result),
  .inDestRegister(dmem_destregister),
  .inRegWrite(dmem_regwrite),
  .outRegData(wback_regdata),
  .outDestRegister(wback_destregister),
  .outRegWrite(wmack_regwrite)
);

endmodule