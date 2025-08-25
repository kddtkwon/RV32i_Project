`timescale 1ns / 1ps

module CPU_RV32I (
    input  logic        clk,
    input  logic        reset,
    input  logic [31:0] instrCode,
    output logic [31:0] instrMemAddr,
    output logic        busWe,
    output logic [31:0] busAddr,
    output logic [31:0] busWData,
    input  logic [31:0] busRData,
    output logic [1:0]  memSize      
);
    logic       PCEn;
    logic       regFileWe;
    logic [3:0] aluControl;
    logic       aluSrcMuxSel;
    logic [2:0] RFWDSrcMuxSel;
    logic       branch;
    logic       jal;
    logic       jalr;
    logic       memUnsigned;  

    ControlUnit U_ControlUnit (
        .clk(clk),
        .reset(reset),
        .instrCode(instrCode),
        .PCEn(PCEn),
        .regFileWe(regFileWe),
        .aluControl(aluControl),
        .aluSrcMuxSel(aluSrcMuxSel),
        .busWe(busWe),
        .RFWDSrcMuxSel(RFWDSrcMuxSel),
        .branch(branch),
        .jal(jal),
        .jalr(jalr),
        .memSize(memSize),
        .memUnsigned(memUnsigned)
    );
    
    DataPath U_DataPath (
        .clk(clk),
        .reset(reset),
        .instrCode(instrCode),
        .instrMemAddr(instrMemAddr),
        .PCEn(PCEn),
        .regFileWe(regFileWe),
        .aluControl(aluControl),
        .aluSrcMuxSel(aluSrcMuxSel),
        .RFWDSrcMuxSel(RFWDSrcMuxSel),
        .branch(branch),
        .jal(jal),
        .jalr(jalr),
        .memSize(memSize),
        .memUnsigned(memUnsigned),
        .busAddr(busAddr),
        .busWData(busWData),
        .busRData(busRData)
    );
endmodule