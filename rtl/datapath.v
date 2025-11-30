`ifndef DATAPATH_V
`define DATAPATH_V

// Datapath Module - RISC-V Single Cycle Processor
// Contains: datapath, regfile, alu, and all supporting modules

module datapath(
    input clk, reset,
    input [1:0] ResultSrc,
    input PCSrc, ALUSrc,
    input RegWrite,
    input [2:0] ImmSrc,
    input [2:0] ALUControl,
    output Zero,
    output [31:0] PC,
    input [31:0] Instr,
    output [31:0] ALUResult, WriteData,
    input [31:0] ReadData
);
    
    wire [31:0] PCNext, PCPlus4, PCTarget;
    wire [31:0] ImmExt;
    wire [31:0] SrcA, SrcB;
    wire [31:0] Result;
    wire Cout;
    
    flopr #(32) pcreg(
        .clk(clk),
        .reset(reset),
        .d(PCNext),
        .q(PC)
    );
    
    adder pcadd4(
        .a(PC),
        .b(32'd4),
        .y(PCPlus4)
    );
    
    adder pcaddbranch(
        .a(PC),
        .b(ImmExt),
        .y(PCTarget)
    );
    
    mux2 #(32) pcmux(
        .d0(PCPlus4),
        .d1(PCTarget),
        .s(PCSrc),
        .y(PCNext)
    );
    
    // register file logic
    regfile rf(
        .clk(clk),
        .we3(RegWrite),
        .a1(Instr[19:15]),
        .a2(Instr[24:20]),
        .a3(Instr[11:7]),
        .wd3(Result),
        .rd1(SrcA),
        .rd2(WriteData)
    );
    
    extend ext(
        .instr(Instr[31:7]),
        .immsrc(ImmSrc),
        .immext(ImmExt)
    );
    
    // ALU logic
    mux2 #(32) srcbmux(
        .d0(WriteData),
        .d1(ImmExt),
        .s(ALUSrc),
        .y(SrcB)
    );
    
    alu alu(
        .a(SrcA),
        .b(SrcB),
        .select(ALUControl),
        .out(ALUResult),
        .zero(Zero),
        .Cout(Cout) 
    );
    
    mux3 #(32) resultmux(
        .d0(ALUResult),
        .d1(ReadData),
        .d2(PCPlus4),
        .d3(ImmExt),
        .s(ResultSrc),
        .y(Result)
    );
    
endmodule


//regfile
module regfile(
    input clk,
    input we3,
    input [4:0] a1, a2, a3,
    input [31:0] wd3,
    output [31:0] rd1, rd2
);
    // Registers
    reg [31:0] registers[31:0];
    
    // Initialize all registers to 0
    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1)
            registers[i] = 32'h0;
        
        registers[0] = 32'h0;         // x0 is hardwired to 0
    end
    
    // Read 
    assign rd1 = (a1 == 5'b0) ? 32'b0 : registers[a1]; // x0 is hardwired to 0
    assign rd2 = (a2 == 5'b0) ? 32'b0 : registers[a2]; // x0 is hardwired to 0
    
    // Write  
    always @(posedge clk) begin
        if (we3 && (a3 != 5'b0)) begin
            registers[a3] <= wd3;
        end
    end
endmodule


module alu #(parameter N = 32)(
    output [N-1:0] out,
    output Cout,
    output zero,  
    input [N-1:0] a, b,
    input [2:0] select
);
    wire slt_xnor_to_and, slt_xor_to_and, slt_not_to_and, slt_and_to_xor, slt_xor_to_zero;
    wire [N-1:0] slt_zero_extender, add_not_to_mux, add_mux_to_sum, add_sum;
    wire [N-1:0] or_or, and_and, sll_sll ;     //SLL KOMUTUNU ALUYA EKLEDIM
    wire Cout_internal;

    // add-sub kısmı
    assign add_not_to_mux = ~b;
    mux_2x1 mux2(.out(add_mux_to_sum), .a(b), .b(add_not_to_mux), .select(select[0]));
    adder_32 ad(.out(add_sum), .Cout(Cout_internal), .a(a), .b(add_mux_to_sum), .Cin(select[0]));
    //add sum kısmı bitti

    //slt kısmı
    assign slt_xnor_to_and = ~(a[N-1]^b[N-1]^select[0]);
    assign slt_xor_to_and = a[N-1]^add_sum[N-1];
    assign slt_not_to_and = ~select[1];
    assign slt_and_to_xor = slt_xnor_to_and & slt_xor_to_and & slt_not_to_and;
    assign slt_xor_to_zero = slt_and_to_xor ^ add_sum[N-1];
    zero_extender ze(.in(slt_xor_to_zero), .out(slt_zero_extender));
    // slt kısmı bitti

    // or ve and bitwise islemi
    assign or_or = a | b;
    assign and_and = a & b;

    //sll komutu
    assign sll_sll = a << b[4:0]; //riscV  mimarisinde ilk 5 bite bakar kaydırma işlemlerinde

    // Ensure we have actual values for all inputs to mux8
    wire [N-1:0] in4 = {N{1'b0}}; // Default to 0 for unused inputs

    wire [N-1:0] in7 = {N{1'b0}};

    // mux koyma sonucları
    mux_8x1 mux8(
        .out(out), 
        .in0(add_sum), 
        .in1(add_sum), 
        .in2(and_and), 
        .in3(or_or), 
        .in4(in4),     // Add explicit input
        .in5(slt_zero_extender), 
        .in6(sll_sll),     // sll komutunu buraya koydum
        .in7(in7),     // Add explicit input
        .select(select)
    );

    // Output the carry
    assign Cout = Cout_internal;

    // Generate Zero flag
    assign zero = (out == {N{1'b0}});
endmodule


module full_adder (
    input A,
    input B,
    input Cin,
    output Sum,
    output Cout
);
    assign Sum = A ^ B ^ Cin;
    assign Cout = (A & B) | (B & Cin) | (A & Cin);
endmodule

module adder_32 #(parameter N=32) (
    output [N-1:0] out,
    output Cout,
    input [N-1:0] a, b,
    input Cin
);
    wire [N:0] carry; // 
    
    // Initialize first carry value to Cin
    assign carry[0] = Cin;
    
    genvar i;
 
    generate
        for (i = 0; i < N; i = i + 1) begin : full_adder_block
            full_adder fa (
                .A(a[i]),
                .B(b[i]),
                .Cin(carry[i]),
                .Sum(out[i]),
                .Cout(carry[i+1])
            );
        end
    endgenerate
    
    // Final carry value becomes Cout
    assign Cout = carry[N];
endmodule

//mux2x1 
module mux_2x1 #(parameter N = 32) (
    output [N-1:0] out,
    input [N-1:0] a, b,
    input select
);
    assign out = select ? b : a; // select 1 ise b, değilse a
endmodule

//8x1 mux 
module mux_8x1 #(parameter N = 32) (
    output reg [N-1:0] out,
    input [N-1:0] in0, in1, in2, in3, in4, in5, in6, in7,
    input [2:0] select
);
    always @(*) begin
        case (select)
            3'b000: out = in0;
            3'b001: out = in1;
            3'b010: out = in2;
            3'b011: out = in3;
            3'b100: out = in4;
            3'b101: out = in5;
            3'b110: out = in6;
            3'b111: out = in7;
            default: out = {N{1'b0}}; // Default to 0 for 'x' inputs
        endcase
    end
endmodule

//zero extender
module zero_extender #(parameter in_width= 1, out_width=32) (
    input [in_width-1:0] in,
    output [out_width-1:0] out
);
    assign out = { {out_width-in_width{1'b0}}, in };
endmodule


module adder(
    input [31:0] a, b, 
    output [31:0] y
);
    assign y = a + b;
endmodule

module extend(
    input [31:7] instr,
    input [2:0] immsrc,
    output reg [31:0] immext
);
    
    always @(*) begin
        case(immsrc)
            // I-type
            3'b000: immext = {{20{instr[31]}}, instr[31:20]};
            // S-type (stores)
            3'b001: immext = {{20{instr[31]}}, instr[31:25], instr[11:7]};
            // B-type (branches)
            3'b010: immext = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
            // J-type (jal)
            3'b011: immext = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};
            // U-type (lui) - YENİ EKLENNEN
            3'b100: immext = {instr[31:12], 12'b0};
            default: immext = 32'b0; // Default to 0 for undefined immsrc
        endcase
    end
    
endmodule

module flopr #(parameter WIDTH = 8)(
    input clk, reset,
    input [WIDTH-1:0] d,
    output reg [WIDTH-1:0] q
);
    
    always @(posedge clk or posedge reset) begin
        if (reset)
            q <= 0;
        else
            q <= d;
    end
    
endmodule

module mux2 #(parameter WIDTH = 8)(
    input [WIDTH-1:0] d0, d1,
    input s,
    output [WIDTH-1:0] y
);
    
    assign y = s ? d1 : d0;
    
endmodule

module mux3 #(parameter WIDTH = 8)(
    input [WIDTH-1:0] d0, d1, d2, d3,
    input [1:0] s,
    output [WIDTH-1:0] y
);
    
    assign y = (s == 2'b00) ? d0 :
               (s == 2'b01) ? d1 :
               (s == 2'b10) ? d2 : d3;  // Son ifade için d3 değerini doğrudan kullanın
    
endmodule

`endif
