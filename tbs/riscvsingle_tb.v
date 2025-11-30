`timescale 1ns/1ps
`include "../rtl/riscvsingle.v"

module riscvsingle_tb;
    // Signals
    reg clk;
    reg reset;
    wire [31:0] pc, instr, aluResult, writeData, readData;
    wire memWrite;
    
    // Parameters
    parameter CLK_PERIOD = 10;
    parameter MEM_SIZE = 1024;
    
    // DUT instantiation
    riscvsingle dut(
        .clk(clk),
        .reset(reset),
        .PC(pc),
        .Instr(instr),
        .MemWrite(memWrite),
        .ALUResult(aluResult),
        .WriteData(writeData),
        .ReadData(readData)
    );
    
    // Memory
    reg [31:0] memory [0:MEM_SIZE-1];
    
    // Instruction memory read
    assign instr = memory[pc[31:2]];
    
    // Data memory read
    assign readData = memory[aluResult[31:2]];
    
    // Data memory write
    always @(posedge clk) begin
        if (memWrite) begin
            memory[aluResult[31:2]] <= writeData;
        end
    end
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Register monitoring
    wire [31:0] x1_val  = dut.dp.rf.registers[1];    // i
    wire [31:0] x2_val  = dut.dp.rf.registers[2];    // j
    wire [31:0] x5_val  = dut.dp.rf.registers[5];    // mask
    wire [31:0] x6_val  = dut.dp.rf.registers[6];    // t1 (adres)
    wire [31:0] x7_val  = dut.dp.rf.registers[7];    // t2 (array[i])
    wire [31:0] x27_val = dut.dp.rf.registers[27];   // sayaç (counter)
    wire [31:0] x28_val = dut.dp.rf.registers[28];   // t3 (and sonucu)
    wire [31:0] x29_val = dut.dp.rf.registers[29];   // t4 (offset)
    wire [31:0] x30_val = dut.dp.rf.registers[30];   // t5 (COUNT adresi)
    wire [31:0] x31_val = dut.dp.rf.registers[31];   // t6
    
    // Initialize memory with program
    integer i;
    initial begin
        // Clear all memory
        for (i = 0; i < MEM_SIZE; i = i + 1) begin
            memory[i] = 32'h00000000;
        end

        // INSTRUCTS - Popcount programı
        memory[0]  = 32'h10000513;  // addi a0, zero, 256    ; ARRAY adresi
        memory[1]  = 32'h15000593;  // addi a1, zero, 336    ; COUNT adresi
        memory[2]  = 32'h01400613;  // addi a2, zero, 20     ; eleman sayısı
        memory[3]  = 32'h02000693;  // addi a3, zero, 32     ; bit sayısı
        memory[4]  = 32'h00200713;  // addi a4, zero, 2
        memory[5]  = 32'h00100793;  // addi a5, zero, 1
        memory[6]  = 32'h00000093;  // addi x1, zero, 0      ; i = 0
        memory[7]  = 32'h04c08663;  // beq  x1, a2, end
        memory[8]  = 32'h00e092b3;  // sll  x5, x1, a4       ; offset = i * 4
        memory[9]  = 32'h00550333;  // add  x6, a0, x5       ; adres = ARRAY + offset
        memory[10] = 32'h00032383;  // lw   x7, 0(x6)        ; x7 = array[i]
        memory[11] = 32'h00000113;  // addi x2, zero, 0      ; j = 0
        memory[12] = 32'h00100293;  // addi x5, zero, 1      ; mask = 1
        memory[13] = 32'h00000d93;  // addi x27, zero, 0     ; count = 0
        memory[14] = 32'h00d10e63;  // beq  x2, a3, store
        memory[15] = 32'h0053fe33;  // and  x28, x7, x5      ; bit = value & mask
        memory[16] = 32'h000e0463;  // beq  x28, zero, skip
        memory[17] = 32'h001d8d93;  // addi x27, x27, 1      ; count++
        memory[18] = 32'h00f292b3;  // sll  x5, x5, a5       ; mask <<= 1
        memory[19] = 32'h00110113;  // addi x2, x2, 1        ; j++
        memory[20] = 32'hfe9ff06f;  // jal  zero, inner_loop
        memory[21] = 32'h00e09eb3;  // sll  x29, x1, a4      ; offset = i * 4
        memory[22] = 32'h01d58f33;  // add  x30, a1, x29     ; adres = COUNT + offset
        memory[23] = 32'h01bf2023;  // sw   x27, 0(x30)      ; COUNT[i] = count
        memory[24] = 32'h00108093;  // addi x1, x1, 1        ; i++
        memory[25] = 32'hfb9ff06f;  // jal  zero, outer_loop
        
        // ARRAY data at 0x100 (word address 64)
        memory[64] = 32'h00000000;  // 0 ones
        memory[65] = 32'h00000001;  // 1 ones
        memory[66] = 32'h00000200;  // 1 ones
        memory[67] = 32'h00400000;  // 1 ones
        memory[68] = 32'h80000000;  // 1 ones
        memory[69] = 32'h51C06460;  // 10 ones
        memory[70] = 32'hDEC287D9;  // 18 ones
        memory[71] = 32'h6C896594;  // 14 ones
        memory[72] = 32'h99999999;  // 16 ones
        memory[73] = 32'hFFFFFFFF;  // 32 ones
        memory[74] = 32'h7FFFFFFF;  // 31 ones
        memory[75] = 32'hFFFFFFFE;  // 31 ones
        memory[76] = 32'hC7B52169;  // 16 ones
        memory[77] = 32'h8CEFF731;  // 20 ones
        memory[78] = 32'hA550921E;  // 13 ones
        memory[79] = 32'h0DB01F33;  // 15 ones
        memory[80] = 32'h24BB7B48;  // 16 ones
        memory[81] = 32'h98513914;  // 12 ones
        memory[82] = 32'hCD76ED30;  // 18 ones
        memory[83] = 32'hC0000003;  // 4 ones
        
        // COUNT array at 0x150 (word address 84)
        for (i = 84; i < 104; i = i + 1) begin
            memory[i] = 32'h00000000;
        end
    end
    
    // Expected results
    integer expected[0:19];
    initial begin
        expected[0]  = 0;
        expected[1]  = 1;
        expected[2]  = 1;
        expected[3]  = 1;
        expected[4]  = 1;
        expected[5]  = 10;
        expected[6]  = 18;
        expected[7]  = 14;
        expected[8]  = 16;
        expected[9]  = 32;
        expected[10] = 31;
        expected[11] = 31;
        expected[12] = 16;
        expected[13] = 20;
        expected[14] = 13;
        expected[15] = 15;
        expected[16] = 16;
        expected[17] = 12;
        expected[18] = 18;
        expected[19] = 4;
    end
    
    // Cycle counting
    integer cycle_count = 0;
    integer element_cycles[0:19];
    integer current_element = 0;
    integer start_cycle = 0;
    integer total_cycles = 0;
    reg counting_started = 0;
    reg [31:0] element_cycles_reg [0:19];
    
    // Monitor execution
    always @(posedge clk) begin
        if (!reset) begin
            cycle_count = cycle_count + 1;
            
            // Start counting when first element processing begins
            if (!counting_started && x1_val == 0 && pc == 32'h20) begin
                counting_started = 1;
                start_cycle = cycle_count;
                $display("Bit counting started at cycle %d", cycle_count);
            end
            
            // Monitor writes to COUNT array
            if (memWrite && aluResult >= 32'h150 && aluResult < 32'h1A0) begin
                element_cycles[current_element] = cycle_count - start_cycle;
                element_cycles_reg[current_element] = element_cycles[current_element];
                $display("Element %2d processed: %2d ones found in %4d cycles", 
                         current_element, writeData, element_cycles[current_element]);
                
                current_element = current_element + 1;
                start_cycle = cycle_count;
                
                if (current_element >= 20) begin
                    total_cycles = cycle_count - element_cycles[0];
                end
            end
        end
    end
    
    // Test control
    initial begin
        // VCD dump for GTKWave
        $dumpfile("riscvsingle_tb.vcd");
        $dumpvars(0, riscvsingle_tb);
        for (i = 84; i < 104; i = i + 1)
            $dumpvars(0, memory[i]);
        for (i = 0; i < 20; i = i + 1)
            $dumpvars(0, element_cycles_reg[i]); 

        // Reset
        reset = 1;
        #(CLK_PERIOD * 2);
        reset = 0;
        
        // Wait for completion
        wait(current_element >= 20);
        #(CLK_PERIOD * 10);
        
        // Display results
        $display("\n========== SONUCLAR ==========");
        $display("Toplam cevrim sayisi: %d", total_cycles);
        $display("\nEleman bazli sonuclar:");
        $display("Index | ARRAY      | Beklenen | Hesaplanan | Cevrim | Durum");
        $display("------|------------|----------|------------|--------|------");
        
        for (i = 0; i < 20; i = i + 1) begin
            $display("%5d | 0x%08X | %8d | %10d | %6d | %s",
                i,
                memory[64 + i],
                expected[i],
                memory[84 + i],
                element_cycles[i],
                (memory[84 + i] == expected[i]) ? "PASS" : "FAIL"
            );
        end
        
        // Special cases
        $display("\n========== OZEL DURUMLAR ==========");
        $display("0xFFFFFFFF (index 9) : %d cevrim", element_cycles[9]);
        $display("0x80000000 (index 4) : %d cevrim", element_cycles[4]);
        $display("0xC7B52169 (index 12): %d cevrim", element_cycles[12]);
        
        $display("\nTest tamamlandi!");
        $finish;
    end
    
endmodule

// Simülasyon komutları:
// 1. Derleme:   iverilog -o riscvsingle_tb.vvp riscvsingle_tb.v
// 2. Çalıştır:  vvp riscvsingle_tb.vvp
// 3. Dalga:     gtkwave riscvsingle_tb.vcd
