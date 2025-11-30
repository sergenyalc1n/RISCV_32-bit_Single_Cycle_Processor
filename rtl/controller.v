`ifndef CONTROLLER_V
`define CONTROLLER_V

// Controller Module - RISC-V Single Cycle Processor
// Contains: maindec, aludec

module controller(
    input [6:0] op,
    input [2:0] funct3,
    input funct7b5,
    input Zero,
    output [1:0] ResultSrc,
    output MemWrite,
    output PCSrc,
    output ALUSrc,
    output RegWrite,
    output Jump,
    output [2:0] ImmSrc,
    output [2:0] ALUControl
);
    
    wire [1:0] ALUOp;
    wire Branch;
    
    maindec md(
        .op(op),
        .ResultSrc(ResultSrc),
        .MemWrite(MemWrite),
        .Branch(Branch),
        .ALUSrc(ALUSrc),
        .RegWrite(RegWrite),
        .Jump(Jump),
        .ImmSrc(ImmSrc),
        .ALUOp(ALUOp)
    );
    
    aludec ad(
        .opb5(op[5]),
        .funct3(funct3),
        .funct7b5(funct7b5),
        .ALUOp(ALUOp),
        .ALUControl(ALUControl)
    );
    
    assign PCSrc = (Branch & Zero) | Jump;
    
endmodule

module aludec(
    input opb5,
    input [2:0] funct3,
    input funct7b5,
    input [1:0] ALUOp,
    output reg [2:0] ALUControl
);
    
    wire RtypeSub;
    assign RtypeSub = funct7b5 & opb5; // TRUE for R-type subtract
    
    always @(*) begin
        case(ALUOp)
            2'b00: ALUControl = 3'b000; // addition
            2'b01: ALUControl = 3'b001; // subtraction
            default: begin
                case(funct3) // R-type or I-type ALU
                    3'b000: begin
                        if (RtypeSub)
                            ALUControl = 3'b001; // sub
                        else
                            ALUControl = 3'b000; // add, addi
                    end
                    3'b001: ALUControl = 3'b110; // SLL (eklenen kısım)
                    3'b010: ALUControl = 3'b101; // slt, slti
                    3'b110: ALUControl = 3'b011; // or, ori
                    3'b111: ALUControl = 3'b010; // and, andi
                    default: ALUControl = 3'b000; // Default to ADD for unknown function
                endcase
            end
        endcase
    end
    
endmodule

module maindec(
    input [6:0] op,
    output reg [1:0] ResultSrc,
    output reg MemWrite,
    output reg Branch,
    output reg ALUSrc,
    output reg RegWrite,
    output reg Jump,
    output reg [2:0] ImmSrc,
    output reg [1:0] ALUOp
);
    
    always @(*) begin
        // Default values to prevent 'x' propagation
        ResultSrc = 2'b00;
        MemWrite = 1'b0;
        Branch = 1'b0;
        ALUSrc = 1'b0;
        RegWrite = 1'b0;
        Jump = 1'b0;
        ImmSrc = 3'b000;
        ALUOp = 2'b00;
        
        case(op)
            7'b0000011: begin // lw
                RegWrite = 1'b1;
                ImmSrc = 3'b000;
                ALUSrc = 1'b1;
                MemWrite = 1'b0;
                ResultSrc = 2'b01;
                Branch = 1'b0;
                ALUOp = 2'b00;
                Jump = 1'b0;
            end
            7'b0100011: begin // sw
                RegWrite = 1'b0;
                ImmSrc = 3'b001;
                ALUSrc = 1'b1;
                MemWrite = 1'b1;
                ResultSrc = 2'b00;
                Branch = 1'b0;
                ALUOp = 2'b00;
                Jump = 1'b0;
            end
            7'b0110011: begin // R-type
                RegWrite = 1'b1;
                ImmSrc = 3'b000;
                ALUSrc = 1'b0;
                MemWrite = 1'b0;
                ResultSrc = 2'b00;
                Branch = 1'b0;
                ALUOp = 2'b10;
                Jump = 1'b0;
            end
            7'b1100011: begin // beq
                RegWrite = 1'b0;
                ImmSrc = 3'b010;
                ALUSrc = 1'b0;
                MemWrite = 1'b0;
                ResultSrc = 2'b00;
                Branch = 1'b1;
                ALUOp = 2'b01;
                Jump = 1'b0;
            end
            7'b0010011: begin // I-type ALU
                RegWrite = 1'b1;
                ImmSrc = 3'b000;
                ALUSrc = 1'b1;
                MemWrite = 1'b0;
                ResultSrc = 2'b00;
                Branch = 1'b0;
                ALUOp = 2'b10;
                Jump = 1'b0;
            end
            7'b1101111: begin // jal
                RegWrite = 1'b1;
                ImmSrc = 3'b011;
                ALUSrc = 1'b0;
                MemWrite = 1'b0;
                ResultSrc = 2'b10;
                Branch = 1'b0;
                ALUOp = 2'b00;
                Jump = 1'b1;
            end
            7'b0110111: begin // lui
                RegWrite = 1'b1;
                ImmSrc = 3'b100;  // U-tipi format
                ALUSrc = 1'b0;    // kullanılmıyor ama formatı görmek için değer atadım
                MemWrite = 1'b0;
                ResultSrc = 2'b11; // IMM sonucunu kullan
                Branch = 1'b0;
                ALUOp = 2'b00;    
                Jump = 1'b0;
            end

            default: begin
                // Default case already set at the beginning
            end
        endcase
    end
    
endmodule

`endif
