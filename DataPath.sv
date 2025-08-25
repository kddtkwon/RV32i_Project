`timescale 1ns / 1ps
`include "defines.sv"

module DataPath (
    input  logic        clk,
    input  logic        reset,
    // instruction memory side port
    input  logic [31:0] instrCode,
    output logic [31:0] instrMemAddr,
    // control unit side port
    input  logic        PCEn,
    input  logic        regFileWe,
    input  logic [ 3:0] aluControl,
    input  logic        aluSrcMuxSel,
    input  logic [ 2:0] RFWDSrcMuxSel,
    input  logic        branch,
    input  logic        jal,
    input  logic        jalr,
    input  logic [ 1:0] memSize,      // 추가: 메모리 크기 제어
    input  logic        memUnsigned,  // 추가: unsigned load 여부
    // data memory side port
    output logic [31:0] busAddr,
    output logic [31:0] busWData,
    input  logic [31:0] busRData
);

    logic [31:0] aluResult,ExeReg_aluResult;
    logic [31:0] RFData1, RFData2, DecReg_RFData1, DecReg_RFData2, ExeReg_RFData2;
    logic [31:0] PCSrcData, PCOutData, PC_Imm_AdderSrcMuxOut;
    logic [31:0] aluSrcMuxOut, immExt,DecReg_immExt, RFWDSrcMuxOut;
    logic [31:0] PC_4_AdderResult, PC_Imm_AdderResult, PCSrcMuxOut, ExeReg_PCSrcMuxOut;
    logic [31:0] MemAccReg_busRData, memDataProcessed;
    logic [1:0] ExeReg_memSize, MemAccReg_memSize;
    logic ExeReg_memUnsigned, MemAccReg_memUnsigned;
    logic [1:0] ExeReg_addrLowBits, MemAccReg_addrLowBits;
    logic PCSrcMuxSel;
    logic btaken;

    assign instrMemAddr = PCOutData;
    assign busAddr = ExeReg_aluResult;
    assign busWData = ExeReg_RFData2;

    RegisterFile U_RegFile (
        .clk(clk),
        .we (regFileWe),
        .RA1(instrCode[19:15]),
        .RA2(instrCode[24:20]),
        .WA (instrCode[11:7]),
        .WD (RFWDSrcMuxOut),
        .RD1(RFData1),
        .RD2(RFData2)
    );

    register U_DecReg_RFRD1 (
        .clk  (clk),
        .reset(reset),
        .d    (RFData1),
        .q    (DecReg_RFData1)
    );
    register U_DecReg_RFRD2 (
        .clk  (clk),
        .reset(reset),
        .d    (RFData2),
        .q    (DecReg_RFData2)
    );
    register U_ExeReg_RFRD2 (
        .clk  (clk),
        .reset(reset),
        .d    (DecReg_RFData2),
        .q    (ExeReg_RFData2)
    );
    
    // 메모리 크기 및 부호 정보를 파이프라인 레지스터로 전달
    register_2bit U_ExeReg_memSize (
        .clk  (clk),
        .reset(reset),
        .d    (memSize),
        .q    (ExeReg_memSize)
    );
    register_1bit U_ExeReg_memUnsigned (
        .clk  (clk),
        .reset(reset),
        .d    (memUnsigned),
        .q    (ExeReg_memUnsigned)
    );
    // 주소의 하위 2비트도 파이프라인으로 전달
    register_2bit U_ExeReg_addrLowBits (
        .clk  (clk),
        .reset(reset),
        .d    (aluResult[1:0]),
        .q    (ExeReg_addrLowBits)
    );
    register_2bit U_MemAccReg_memSize (
        .clk  (clk),
        .reset(reset),
        .d    (ExeReg_memSize),
        .q    (MemAccReg_memSize)
    );
    register_1bit U_MemAccReg_memUnsigned (
        .clk  (clk),
        .reset(reset),
        .d    (ExeReg_memUnsigned),
        .q    (MemAccReg_memUnsigned)
    );
    register_2bit U_MemAccReg_addrLowBits (
        .clk  (clk),
        .reset(reset),
        .d    (ExeReg_addrLowBits),
        .q    (MemAccReg_addrLowBits)
    );
    
    mux_2x1 U_AluSrcMux (
        .sel(aluSrcMuxSel),
        .x0 (DecReg_RFData2),
        .x1 (DecReg_immExt),
        .y  (aluSrcMuxOut)
    );
    register U_MemAccReg_ReadData (
        .clk  (clk),
        .reset(reset),
        .d    (busRData),
        .q    (MemAccReg_busRData)
    );

    // Load 데이터 처리 로직 (메모리에서 읽은 데이터를 적절히 확장)
    always_comb begin
        case (MemAccReg_memSize)
            2'b00: begin // byte
                case (MemAccReg_addrLowBits)
                    2'b00: memDataProcessed = MemAccReg_memUnsigned ? {24'b0, MemAccReg_busRData[7:0]} : {{24{MemAccReg_busRData[7]}}, MemAccReg_busRData[7:0]};
                    2'b01: memDataProcessed = MemAccReg_memUnsigned ? {24'b0, MemAccReg_busRData[15:8]} : {{24{MemAccReg_busRData[15]}}, MemAccReg_busRData[15:8]};
                    2'b10: memDataProcessed = MemAccReg_memUnsigned ? {24'b0, MemAccReg_busRData[23:16]} : {{24{MemAccReg_busRData[23]}}, MemAccReg_busRData[23:16]};
                    2'b11: memDataProcessed = MemAccReg_memUnsigned ? {24'b0, MemAccReg_busRData[31:24]} : {{24{MemAccReg_busRData[31]}}, MemAccReg_busRData[31:24]};
                endcase
            end
            2'b01: begin // halfword
                case (MemAccReg_addrLowBits[1])
                    1'b0: memDataProcessed = MemAccReg_memUnsigned ? {16'b0, MemAccReg_busRData[15:0]} : {{16{MemAccReg_busRData[15]}}, MemAccReg_busRData[15:0]};
                    1'b1: memDataProcessed = MemAccReg_memUnsigned ? {16'b0, MemAccReg_busRData[31:16]} : {{16{MemAccReg_busRData[31]}}, MemAccReg_busRData[31:16]};
                endcase
            end
            2'b10: memDataProcessed = MemAccReg_busRData; // word
            default: memDataProcessed = MemAccReg_busRData; // 안전장치
        endcase
    end

    mux_5x1 U_RFWDSrcMux (
        .sel(RFWDSrcMuxSel),
        .x0 (aluResult),
        .x1 (memDataProcessed),  // 수정: 처리된 메모리 데이터 사용
        .x2 (DecReg_immExt),
        .x3 (PC_Imm_AdderResult),
        .x4 (PC_4_AdderResult),
        .y  (RFWDSrcMuxOut)
    );

    alu U_ALU (
        .aluControl(aluControl),
        .a         (DecReg_RFData1),
        .b         (aluSrcMuxOut),
        .result    (aluResult),
        .btaken    (btaken)
    );
    register U_DExeReg_ALU (
        .clk  (clk),
        .reset(reset),
        .d    (aluResult),
        .q    (ExeReg_aluResult)
    );
    immExtend U_ImmExtend (
        .instrCode(instrCode),
        .immExt   (immExt)
    );
    register U_DecReg_ImmExtend (
        .clk  (clk),
        .reset(reset),
        .d    (immExt),
        .q    (DecReg_immExt)
    );
    mux_2x1 U_PC_Imm_AdderSrcMux (
        .sel(jalr),
        .x0 (PCOutData),
        .x1 (DecReg_RFData1),
        .y  (PC_Imm_AdderSrcMuxOut)
    );

    adder U_PC_Imm_Adder (
        .a(DecReg_immExt),
        .b(PC_Imm_AdderSrcMuxOut),
        .y(PC_Imm_AdderResult)
    );

    adder U_PC_4_Adder (
        .a(32'd4),
        .b(PCOutData),
        .y(PC_4_AdderResult)
    );

    assign PCSrcMuxSel = jal | jalr | (btaken & branch);

    mux_2x1 U_PCSrcMux (
        .sel(PCSrcMuxSel),
        .x0 (PC_4_AdderResult),
        .x1 (PC_Imm_AdderResult),
        .y  (PCSrcMuxOut)
    );
    register U_ExeReg_PCSrcMux (
        .clk  (clk),
        .reset(reset),
        .d    (PCSrcMuxOut),
        .q    (ExeReg_PCSrcMuxOut)
    );

    registerEn U_PC (
        .clk  (clk),
        .reset(reset),
        .en   (PCEn),
        .d    (ExeReg_PCSrcMuxOut),
        .q    (PCOutData)
    );

endmodule



module alu (
    input  logic [ 3:0] aluControl,
    input  logic [31:0] a,
    input  logic [31:0] b,
    output logic [31:0] result,
    output logic        btaken
);

    always_comb begin
        result = 32'bx;
        case (aluControl)
            `ADD:  result = a + b;
            `SUB:  result = a - b;
            `SLL:  result = a << b;
            `SRL:  result = a >> b;
            `SRA:  result = $signed(a) >>> b;
            `SLT:  result = ($signed(a) < $signed(b)) ? 1 : 0;
            `SLTU: result = (a < b) ? 1 : 0;
            `XOR:  result = a ^ b;
            `OR:   result = a | b;
            `AND:  result = a & b;
        endcase
    end

    always_comb begin : branch
        btaken = 1'b0;
        case (aluControl[2:0])
            `BEQ:  btaken = (a == b);
            `BNE:  btaken = (a != b);
            `BLT:  btaken = ($signed(a) < $signed(b));
            `BGE:  btaken = ($signed(a) >= $signed(b));
            `BLTU: btaken = (a < b);
            `BGEU: btaken = (a >= b);
        endcase
    end
endmodule

module RegisterFile (
    input  logic        clk,
    input  logic        we,
    input  logic [ 4:0] RA1,
    input  logic [ 4:0] RA2,
    input  logic [ 4:0] WA,
    input  logic [31:0] WD,
    output logic [31:0] RD1,
    output logic [31:0] RD2
);
    logic [31:0] mem[0:2**5-1];

    
    initial begin  // for simulation test
        for (int i = 0; i < 32; i++) begin
            mem[i] = 10 + i;
        end
    end
    
    

    always_ff @(posedge clk) begin
        if (we) mem[WA] <= WD;
    end

    assign RD1 = (RA1 != 0) ? mem[RA1] : 32'b0;
    assign RD2 = (RA2 != 0) ? mem[RA2] : 32'b0;
endmodule

module register (
    input  logic        clk,
    input  logic        reset,
    input  logic [31:0] d,
    output logic [31:0] q
);
    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            q <= 0;
        end else begin
            q <= d;
        end
    end
endmodule
module registerEn (
    input  logic        clk,
    input  logic        reset,
    input  logic        en,
    input  logic [31:0] d,
    output logic [31:0] q
);
    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            q <= 0;
        end else begin
            if (en) q <= d;
        end
    end
endmodule
module adder (
    input  logic [31:0] a,
    input  logic [31:0] b,
    output logic [31:0] y
);
    assign y = a + b;
endmodule

module mux_2x1 (
    input  logic        sel,
    input  logic [31:0] x0,
    input  logic [31:0] x1,
    output logic [31:0] y
);
    always_comb begin
        y = 32'bx;
        case (sel)
            1'b0: y = x0;
            1'b1: y = x1;
        endcase
    end
endmodule

module mux_5x1 (
    input  logic [ 2:0] sel,
    input  logic [31:0] x0,
    input  logic [31:0] x1,
    input  logic [31:0] x2,
    input  logic [31:0] x3,
    input  logic [31:0] x4,
    output logic [31:0] y
);
    always_comb begin
        y = 32'bx;
        case (sel)
            3'b000: y = x0;
            3'b001: y = x1;
            3'b010: y = x2;
            3'b011: y = x3;
            3'b100: y = x4;
        endcase
    end
endmodule

module immExtend (
    input  logic [31:0] instrCode,
    output logic [31:0] immExt
);
    wire [6:0] opcode = instrCode[6:0];
    wire [2:0] func3 = instrCode[14:12];

    always_comb begin
        immExt = 32'bx;
        case (opcode)
            `OP_TYPE_R: immExt = 32'bx;  // R-Type
            `OP_TYPE_L: immExt = {{20{instrCode[31]}}, instrCode[31:20]};
            `OP_TYPE_S:
            immExt = {
                {20{instrCode[31]}}, instrCode[31:25], instrCode[11:7]
            };  // S-Type
            `OP_TYPE_I: begin
                case (func3)
                    3'b001:  immExt = {27'b0, instrCode[24:20]};  // SLLI
                    3'b101:  immExt = {27'b0, instrCode[24:20]};  // SRLI, SRAI
                    3'b011:  immExt = {20'b0, instrCode[31:20]};  // SLTIU
                    default: immExt = {{20{instrCode[31]}}, instrCode[31:20]};
                endcase
            end
            `OP_TYPE_B:
            immExt = {
                {20{instrCode[31]}},
                instrCode[7],
                instrCode[30:25],
                instrCode[11:8],
                1'b0
            };
            `OP_TYPE_LU: immExt = {instrCode[31:12], 12'b0};
            `OP_TYPE_AU: immExt = {instrCode[31:12], 12'b0};
            `OP_TYPE_J:
            immExt = {
                {12{instrCode[31]}},
                instrCode[19:12],
                instrCode[20],
                instrCode[30:21],
                1'b0
            };
            `OP_TYPE_JL: immExt = {{20{instrCode[31]}}, instrCode[31:20]};
        endcase
    end
endmodule
module register_2bit (
    input  logic       clk,
    input  logic       reset,
    input  logic [1:0] d,
    output logic [1:0] q
);
    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            q <= 2'b0;
        end else begin
            q <= d;
        end
    end
endmodule

module register_1bit (
    input  logic clk,
    input  logic reset,
    input  logic d,
    output logic q
);
    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            q <= 1'b0;
        end else begin
            q <= d;
        end
    end
endmodule