// RISC-V Single Cycle Processor - Top Module
// Controller ve Datapath ayrı dosyalarda tanımlı

`define WORD_SIZE 32

// Include controller and datapath modules
`include "../rtl/controller.v"
`include "../rtl/datapath.v"

module riscvsingle(
    input clk, reset,
    output [31:0] PC,
    input [31:0] Instr,
    output MemWrite,
    output [31:0] ALUResult, WriteData,
    input [31:0] ReadData
);
    
    wire ALUSrc, RegWrite, Jump, Zero, PCSrc;
    wire [1:0] ResultSrc;
    wire [2:0] ALUControl, ImmSrc;
    
    // Controller instance
    controller c(
        .op(Instr[6:0]),
        .funct3(Instr[14:12]),
        .funct7b5(Instr[30]),
        .Zero(Zero),
        .ResultSrc(ResultSrc),
        .MemWrite(MemWrite),
        .PCSrc(PCSrc),
        .ALUSrc(ALUSrc),
        .RegWrite(RegWrite),
        .Jump(Jump),
        .ImmSrc(ImmSrc),
        .ALUControl(ALUControl)
    );
    
    // Datapath instance
    datapath dp(
        .clk(clk),
        .reset(reset),
        .ResultSrc(ResultSrc),
        .PCSrc(PCSrc),
        .ALUSrc(ALUSrc),
        .RegWrite(RegWrite),
        .ImmSrc(ImmSrc),
        .ALUControl(ALUControl),
        .Zero(Zero),
        .PC(PC),
        .Instr(Instr),
        .ALUResult(ALUResult),
        .WriteData(WriteData),
        .ReadData(ReadData)
    );
    
endmodule
