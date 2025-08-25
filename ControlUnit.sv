`timescale 1ns / 1ps
`include "defines.sv"

module ControlUnit (
    input  logic        clk,
    input  logic        reset,
    input  logic [31:0] instrCode,
    output logic        PCEn,
    output logic        regFileWe,
    output logic [ 3:0] aluControl,
    output logic        aluSrcMuxSel,
    output logic        busWe,
    output logic [ 2:0] RFWDSrcMuxSel,
    output logic        branch,
    output logic        jal,
    output logic        jalr,
    output logic [ 1:0] memSize,      
    output logic        memUnsigned   // 추가: unsigned load 여부
);
    wire  [6:0] opcode = instrCode[6:0];
    wire  [3:0] operator = {instrCode[30], instrCode[14:12]};
    wire  [2:0] func3 = instrCode[14:12];
    logic [9:0] signals;
    assign {PCEn, regFileWe, aluSrcMuxSel, busWe, RFWDSrcMuxSel, branch, jal, jalr} = signals;
    
    typedef enum {
        FETCH,
        DECODE,
        R_EXE,
        I_EXE,
        B_EXE,
        LU_EXE,
        AU_EXE,
        J_EXE,
        JL_EXE,
        S_EXE,
        S_MEM,
        L_EXE,
        L_MEM,
        L_WB
    } state_e;

    state_e state, next_state;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            state <= FETCH;
        end else begin
            state <= next_state;
        end
    end
    
    always_comb begin
        next_state = state;
        case (state)
            FETCH:  next_state = DECODE;
            DECODE: begin
                case (opcode)
                    `OP_TYPE_R:  next_state = R_EXE;
                    `OP_TYPE_I:  next_state = I_EXE;
                    `OP_TYPE_B:  next_state = B_EXE;
                    `OP_TYPE_LU: next_state = LU_EXE;
                    `OP_TYPE_AU: next_state = AU_EXE;
                    `OP_TYPE_J:  next_state = J_EXE;
                    `OP_TYPE_JL: next_state = JL_EXE;
                    `OP_TYPE_S:  next_state = S_EXE;
                    `OP_TYPE_L:  next_state = L_EXE;
                endcase
            end
            R_EXE:  next_state = FETCH;
            I_EXE:  next_state = FETCH;
            B_EXE:  next_state = FETCH;
            LU_EXE: next_state = FETCH;
            AU_EXE: next_state = FETCH;
            J_EXE:  next_state = FETCH;
            JL_EXE: next_state = FETCH;
            S_EXE:  next_state = S_MEM;
            S_MEM:  next_state = FETCH;
            L_EXE:  next_state = L_MEM;
            L_MEM:  next_state = L_WB;
            L_WB:   next_state = FETCH;
        endcase
    end
    
    always_comb begin
        signals = 10'b0;
        aluControl = `ADD;
        memSize = 2'b10;     
        memUnsigned = 1'b0;  
        
        case (state)
            FETCH: begin
                signals = 10'b1_0_0_0_000_0_0_0;
            end
            DECODE: begin
                signals = 10'b0_0_0_0_000_0_0_0;
            end
            R_EXE: begin
                signals = 10'b0_1_0_0_000_0_0_0;
                aluControl = operator;
            end
            I_EXE: begin
                signals = 10'b0_1_1_0_000_0_0_0;
                if (operator == 4'b1101) aluControl = operator;
                else aluControl = {1'b0, operator[2:0]};
            end
            B_EXE: begin
                signals = 10'b0_0_0_0_000_1_0_0;
                aluControl = operator;
            end
            LU_EXE: begin
                signals = 10'b0_1_0_0_010_0_0_0;
            end
            AU_EXE: begin
                signals = 10'b0_1_0_0_011_0_0_0;
            end
            J_EXE: begin
                signals = 10'b0_1_0_0_100_0_1_0;
            end
            JL_EXE: begin
                signals = 10'b0_1_0_0_100_0_1_1;
            end
            S_EXE: begin
                signals = 10'b0_0_1_0_000_0_0_0;
                case (func3)
                    3'b000: memSize = 2'b00; 
                    3'b001: memSize = 2'b01; 
                    3'b010: memSize = 2'b10; 
                    default: memSize = 2'b10;
                endcase
            end
            S_MEM: begin
                signals = 10'b0_0_1_1_000_0_0_0;
                case (func3)
                    3'b000: memSize = 2'b00; 
                    3'b001: memSize = 2'b01; 
                    3'b010: memSize = 2'b10; 
                    default: memSize = 2'b10; 
                endcase
            end
            L_EXE: begin
                signals = 10'b0_0_1_0_001_0_0_0;
                case (func3)
                    3'b000: begin memSize = 2'b00; memUnsigned = 1'b0; end 
                    3'b001: begin memSize = 2'b01; memUnsigned = 1'b0; end   
                    3'b010: begin memSize = 2'b10; memUnsigned = 1'b0; end 
                    3'b100: begin memSize = 2'b00; memUnsigned = 1'b1; end 
                    3'b101: begin memSize = 2'b01; memUnsigned = 1'b1; end 
                    default: begin memSize = 2'b10; memUnsigned = 1'b0; end
                endcase
            end
            L_MEM: begin
                signals = 10'b0_0_1_0_001_0_0_0;
                case (func3)
                    3'b000: begin memSize = 2'b00; memUnsigned = 1'b0; end 
                    3'b001: begin memSize = 2'b01; memUnsigned = 1'b0; end   
                    3'b010: begin memSize = 2'b10; memUnsigned = 1'b0; end 
                    3'b100: begin memSize = 2'b00; memUnsigned = 1'b1; end 
                    3'b101: begin memSize = 2'b01; memUnsigned = 1'b1; end 
                    default: begin memSize = 2'b10; memUnsigned = 1'b0; end
                endcase
            end
            L_WB: begin
                signals = 10'b0_1_1_0_001_0_0_0;
                case (func3)
                    3'b000: begin memSize = 2'b00; memUnsigned = 1'b0; end 
                    3'b001: begin memSize = 2'b01; memUnsigned = 1'b0; end   
                    3'b010: begin memSize = 2'b10; memUnsigned = 1'b0; end 
                    3'b100: begin memSize = 2'b00; memUnsigned = 1'b1; end 
                    3'b101: begin memSize = 2'b01; memUnsigned = 1'b1; end 
                    default: begin memSize = 2'b10; memUnsigned = 1'b0; end 
                endcase
            end
        endcase
    end
endmodule