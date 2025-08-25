`timescale 1ns / 1ps

module MCU (
    input logic clk,
    input logic reset
);
    logic [31:0] instrCode;
    logic [31:0] instrMemAddr;
    logic        busWe;
    logic [31:0] busAddr;
    logic [31:0] busWData;
    logic [31:0] busRData;
    logic [1:0] memSize;

    ROM U_ROM (
        .addr(instrMemAddr),
        .data(instrCode)
    );

    CPU_RV32I U_CPU (
        .clk(clk),
        .reset(reset),
        .instrCode(instrCode),
        .instrMemAddr(instrMemAddr),
        .busWe(busWe),
        .busAddr(busAddr),
        .busWData(busWData),
        .busRData(busRData),
        .memSize(memSize)
    );

    RAM U_RAM (
        .clk(clk),
        .we(busWe),
        .addr(busAddr),
        .wData(busWData),
        .size(memSize),    // 기존 RAM 모듈을 수정했다면 이 연결 추가
        .rData(busRData)
    );
endmodule
