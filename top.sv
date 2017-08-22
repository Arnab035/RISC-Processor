module top
#(
  BUS_DATA_WIDTH = 64,
  BUS_TAG_WIDTH = 13
)
(
  input  clk,
         reset,

  // 64-bit addresses of the program entry point and initial stack pointer
  input  [63:0] entry,
  input  [63:0] stackptr,
  input  [63:0] satp,
  
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

`include "Sysbus.defs"

  logic [63:0] pc, npc;

  /* stall for icache/dcache */

  always_comb begin
    if(ic_stall || dc_stall || hdu_stall) begin
      npc = pc;
    end else begin
      if(dc_pcsrc && wback_flush)
        npc = wback_epc;
      else if(dc_pcsrc)
        npc = dc_addrjump;
      else if(wback_flush)
        npc = wback_epc;
      else
        npc = pc + 4;
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

  logic ic_miss, ic_stall;
  logic [BUS_DATA_WIDTH-1 : 0] ic_pc;
  logic [31:0] ic_data;

  logic [63:0] dmembus_req, dmembus_resp;
  logic dmembus_reqcyc, dmembus_respack, dmembus_respcyc, dmembus_reqack;
  logic [12:0] dmembus_reqtag, dmembus_resptag;

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
    .dbus_req(dmembus_req),
    .dbus_reqcyc(dmembus_reqcyc),
    .dbus_reqtag(dmembus_reqtag),
    .dbus_respack(dmembus_respack),
    .dbus_respcyc(dmembus_respcyc),
    .dbus_resp(dmembus_resp),
    .dbus_resptag(dmembus_resptag),
    .bus_req(bus_req),
    .bus_reqcyc(bus_reqcyc),
    .bus_reqtag(bus_reqtag),
    .bus_respack(bus_respack),
    .bus_respcyc(bus_respcyc),
    .bus_resp(bus_resp),
    .bus_resptag(bus_resptag),
    .bus_reqack(bus_reqack)
  );

  instructionCache ich(
    .clk(clk),
    .reset(reset),
    .inData(ft_data),
    .in_stall_from_dcache(dc_stall),
    .in_stall_from_hazardunit(hdu_stall),
    .pc(pc),
    .in_out_offset(ft_out_offset),
    .inFlushFromEcall(wback_flush),
    .inFlushFromJump(dc_flushjump),
    .outInstr(ic_data),
    .outMiss(ic_miss),
    .outStall(ic_stall),
    .outPc(ic_pc)
  );

  logic [63:0] ftbus_req, ftbus_resp;
  logic ftbus_reqcyc, ftbus_respack, ftbus_respcyc, ftbus_reqack;
  logic [12:0] ftbus_reqtag, ftbus_resptag;
  logic [9:0] ft_out_offset;

  logic [511:0] ft_data;
  logic ft_do_invalidate;
  logic [63:0] ft_invalid_phys_addr;

  fetcher ft(
    .clk(clk),
    .pc(pc),
    .reset(reset),
    .bus_req(ftbus_req),
    .bus_reqcyc(ftbus_reqcyc),
    .bus_reqtag(ftbus_reqtag),
    .bus_reqack(ftbus_reqack),
    .bus_resp(ftbus_resp),
    .bus_respcyc(ftbus_respcyc),
    .bus_resptag(ftbus_resptag),
    .bus_respack(ftbus_respack),
    .inMiss(ic_miss),
    .out_do_invalidate(ft_do_invalidate),
    .out_invalid_phys_addr(ft_invalid_phys_addr),
    .out_data(ft_data),
    .out_offset(ft_out_offset)
  );
  
  
  logic hdu_stall;

  hazarddetectionunit hdu(
    .clk(clk),
    .inMemReadEx(dec_memread),
    .inFlushFromJump(dc_flushjump),
    .in_stall_from_dcache(dc_stall),
    .in_stall_from_icache(ic_stall),
    .inDestRegisterEx(dec_destregister),
    .inIns(ic_data),
    .outStall(hdu_stall)
  );
  
  
  logic dec_branch, dec_pcsrc, dec_memread, dec_memwrite, dec_regwrite, dec_memorreg, dec_jalr, dec_jump;
  logic [5:0] dec_alucontrol;
  logic [BUS_DATA_WIDTH-1:0] dec_readdata1, dec_readdata2, dec_imm, dec_pc;
  logic [4:0] dec_registerrs, dec_registerrt, dec_destregister;
  logic [2:0] dec_loadtype, dec_branchtype;
  logic [1:0] dec_storetype;
  logic dec_ecall, dec_stall;

  logic [63:0] dec_mem10, dec_mem11, dec_mem12, dec_mem13, dec_mem14, dec_mem15, dec_mem16, dec_mem17, dec_epc;
  
  decode1 dc(
    .clk(clk),
    .pc(ic_pc),
    .reset(reset),
    .in_stall_from_hazardunit(hdu_stall),
    .inStackPtr(stackptr),
    .in_stall_from_dcache(dc_stall),
    .in_stall_from_icache(ic_stall),
    .inFlushFromEcall(wback_flush),
    .outIns(ic_data),
    .inRegWrite(wback_regwrite),
    .inDestRegister(wback_destregister),
    .inRegData(wback_regdata),
    .inRegWriteFromEcall(wback_regwritefromecall),
    .inDestRegisterFromEcall(wback_destregisterfromecall),
    .inRegDataFromEcall(wback_regdatafromecall),
    .inFlushFromJump(dc_flushjump),
    .outBranch(dec_branch),
    .outPCSrc(dec_pcsrc),
    .outMemRead(dec_memread),
    .outMemWrite(dec_memwrite),
    .outRegWrite(dec_regwrite),
    .outMemOrReg(dec_memorreg),
    .outJalr(dec_jalr),
    .outJump(dec_jump),
    .outStall(dec_stall),
    .outAluControl(dec_alucontrol),
    .outReadData1(dec_readdata1),
    .outReadData2(dec_readdata2),
    .outImm(dec_imm),
    .outPc(dec_pc),
    .outRegisterRs(dec_registerrs),
    .outRegisterRt(dec_registerrt),
    .outDestRegister(dec_destregister),
    .outLoadType(dec_loadtype),
    .outStoreType(dec_storetype),
    .outBranchType(dec_branchtype),
    .outEcall(dec_ecall),
    .outEpc(dec_epc),
    .outMem10(dec_mem10),
    .outMem11(dec_mem11),
    .outMem12(dec_mem12),
    .outMem13(dec_mem13),
    .outMem14(dec_mem14),
    .outMem15(dec_mem15),
    .outMem16(dec_mem16),
    .outMem17(dec_mem17)  
);


logic [1:0] fwd_forwarda, fwd_forwardb;

forwardingunit fw(
    .inRegisterRs(dec_registerrs),
    .inRegisterRt(dec_registerrt),
    .inDestRegisterEx(alu_destregister),
    .inDestRegisterMem(dc_destregister),
    .inRegWriteEx(alu_regwrite),
    .inRegWriteMem(dc_regwrite),
    .outForwardA(fwd_forwarda),
    .outForwardB(fwd_forwardb)
);

logic [4:0] alu_destregister, alu_registerrt;
logic alu_branch,alu_memread, alu_memwrite, alu_memorreg,alu_pcsrc, alu_regwrite, alu_zero, alu_jump, alu_ecall;
logic [BUS_DATA_WIDTH-1 : 0] alu_addrjump, alu_result, alu_datareg2, alu_epc, alu_pc;
logic [2:0] alu_loadtype;
logic [1:0] alu_storetype;


alu al(
    .clk(clk),
    .inPc(dec_pc),
    .inEpc(dec_epc),
    .inDataReg1(dec_readdata1),
    .inDataReg2(dec_readdata2),
    .inAluControl(dec_alucontrol),
    .inBranch(dec_branch),
    .inMemRead(dec_memread),
    .inMemWrite(dec_memwrite),
    .inMemOrReg(dec_memorreg),
    .inPCSrc(dec_pcsrc),
    .inRegWrite(dec_regwrite),
    .inJump(dec_jump),
    .inJalr(dec_jalr),
    .inImm(dec_imm),
    .inEcall(dec_ecall),
    .inDestRegister(dec_destregister),
    .inRegisterRt(dec_registerrt),
    .inBranchType(dec_branchtype),
    .inLoadType(dec_loadtype),
    .inStoreType(dec_storetype),
    .inForwardA(fwd_forwarda),
    .inForwardB(fwd_forwardb),
    .inResultEx(alu_result),
    .inResultMem(wback_regdata),
    .inFlushFromEcall(wback_flush),
    .inFlushFromJump(dc_flushjump),
    .in_stall_from_dcache(dc_stall),
    .in_stall_from_icache(ic_stall),
    .outStoreType(alu_storetype),
    .outLoadType(alu_loadtype),
    .outDestRegister(alu_destregister),
    .outRegisterRt(alu_registerrt),
    .outBranch(alu_branch),
    .outMemRead(alu_memread),
    .outMemWrite(alu_memwrite),
    .outMemOrReg(alu_memorreg),
    .outJump(alu_jump),
    .outPCSrc(alu_pcsrc),
    .outRegWrite(alu_regwrite),
    .outZero(alu_zero),
    .outAddrJump(alu_addrjump),
    .outResult(alu_result),
    .outDataReg2(alu_datareg2),
    .outEcall(alu_ecall),
    .outEpc(alu_epc),
    .outPc(alu_pc)
);

logic dc_miss, dc_dopendingwrite, dc_pcsrc, dc_memorreg, dc_regwrite, dc_memwrite, dc_ecall, dc_stall, dc_flushjump, dc_flushecall, dc_memread, dc_jump;
logic [63:0] dc_addresspendingwrite, dc_addrjump, dc_readdata, dc_result, dc_address, dc_epc, dc_pc;
logic [4:0] dc_destregister;
logic [511:0] dc_datawriteback;
logic [63 : 0] dc_data_for_pending_write_64;

datacache dch(
    .clk(clk),
    .inData(dmem_data),
    .in_out_offset(dmem_offset),
    .in_out_offset_write(dmem_offset_write),
    .inFlushFromEcall(wback_flush),
    .inDestRegister(alu_destregister),
    .inRegisterRt(alu_registerrt),
    .inMemReadWb(dc_memread),
    .inDestRegisterWb(dc_destregister),
    .inReadDataWb(dc_readdata),
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
    .inJump(alu_jump),
    .inStoreType(alu_storetype),
    .inLoadType(alu_loadtype),
    .in_do_invalidate(dmem_do_invalidate),
    .in_invalid_phys_addr(dmem_invalid_phys_addr),
    .in_do_invalidate_2(ft_do_invalidate),
    .in_invalid_phys_addr_2(ft_invalid_phys_addr),
    .inEcall(alu_ecall),
    .in_stall_from_icache(ic_stall),
    .inEpc(alu_epc),
    .inPc(alu_pc),
    .outPc(dc_pc),
    .outJump(dc_jump),
    .outMiss(dc_miss),
    .outStall(dc_stall),
    .outDoPendingWrite(dc_dopendingwrite),        // will go to wb
    .outAddressPendingWrite(dc_addresspendingwrite),
    .outDataWriteBack(dc_datawriteback),
    .outPCSrc(dc_pcsrc),
    .outAddrJump(dc_addrjump),
    .outReadData(dc_readdata),
    .outResult(dc_result),
    .outDestRegister(dc_destregister),
    .outMemOrReg(dc_memorreg),
    .outRegWrite(dc_regwrite),
    .outMemWrite(dc_memwrite),
    .outAddress(dc_address),
    .outEcall(dc_ecall),
    .outFlushJump(dc_flushjump),
    .outEpc(dc_epc),
    .outMemRead(dc_memread),
    .outSizePendingWrite(dcSizePendingWrite),
    .out_data_for_pending_write(dc_data_for_pending_write_64)
   );


logic [511:0] dmem_data; 
logic [9:0] dmem_offset, dmem_offset_write;
logic dmem_do_invalidate;
logic [63:0] dmem_invalid_phys_addr;

datamemory dmem(
    .clk(clk),
    .bus_respcyc(dmembus_respcyc),
    .bus_resp(dmembus_resp),
    .bus_resptag(dmembus_resptag),
    .bus_reqack(dmembus_reqack),
    .bus_reqcyc(dmembus_reqcyc),
    .bus_req(dmembus_req),
    .bus_reqtag(dmembus_reqtag),
    .bus_respack(dmembus_respack),
    .inMiss(dc_miss),
    .inMemWrite(dc_memwrite),
    .inDataWriteBack(dc_datawriteback),
    .inAddress(dc_address),
    .out_write_offset(dmem_offset_write),
    .out_offset(dmem_offset),
    .out_data(dmem_data),
    .out_do_invalidate(dmem_do_invalidate),
    .out_invalid_phys_addr(dmem_invalid_phys_addr)
);

logic [BUS_DATA_WIDTH-1:0] wback_regdata, wback_ecallvalue, wback_epc, wback_regdatafromecall;
logic [4:0] wback_destregister, wback_destregisterfromecall;
logic wback_regwrite, wback_flush, wback_regwritefromecall;

writeback wb(
  .inMemOrReg(dc_memorreg),
  .inReadData(dc_readdata),     
  .inResult(dc_result),
  .inJump(dc_jump),
  .inPc(dc_pc), 
  .inDoPendingWrite(dc_dopendingwrite),
  .inDataPendingWrite(dc_datapendingwrite),
  .inAddressPendingWrite(dc_addresspendingwrite),    
  .inDestRegister(dc_destregister),
  .inRegWrite(dc_regwrite),
  .inMem10(dec_mem10),
  .inMem11(dec_mem11),
  .inMem12(dec_mem12),
  .inMem13(dec_mem13),
  .inMem14(dec_mem14),
  .inMem15(dec_mem15),
  .inMem16(dec_mem16),
  .inMem17(dec_mem17),
  .in_data_for_pending_write(dc_data_for_pending_write_64),
  .inSizePendingWrite(dcSizePendingWrite),
  .inEpc(dc_epc),
  .in_stall_from_icache(ic_stall),
  .in_stall_from_dcache(dc_stall),
  .clk(clk),
  .inEcall(dc_ecall),
  .outRegData(wback_regdata),
  .outDestRegister(wback_destregister),
  .outRegWrite(wback_regwrite),
  .outFlush(wback_flush),
  .outEpc(wback_epc),
  .outRegDataFromEcall(wback_regdatafromecall),
  .outRegWriteFromEcall(wback_regwritefromecall),
  .outDestRegisterFromEcall(wback_destregisterfromecall) 
);


endmodule
