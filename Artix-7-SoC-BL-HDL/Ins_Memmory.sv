module Ins_Memmory(
    input logic clk, 
    input logic [31:0] MEM_addr,
    output logic [31:0] MEM_dout,
    input logic rMEM_en
  //input logic [31:0] MEM_Wdata,
);
    
   reg [31:0] MEM [0:8000];
	//reg [31:0] MEM [0:1500];


/*
 
  Note: it is better to first create a  R-Type program
  Note: to test the basic Cpu we will first need to generate a raw assembly code using systemverilog

    add x0, x0, x0       // Clear x0 (NOP, since x0 is always 0)
    add x1, x0, x0       // Initialize x1 to 0
    addi x1, x1, 1       // Increment x1 by 1 (x1 = 1)
    addi x1, x1, 1       // Increment x1 by 1 (x1 = 2)
    addi x1, x1, 1       // Increment x1 by 1 (x1 = 3)
    addi x1, x1, 1       // Increment x1 by 1 (x1 = 4)
    ebreak               // Trigger a breakpoint


initial begin
  // ───────────── R-TYPE ─────────────
  MEM[0] = 32'b0000000_00011_00010_000_00001_0110011; // ADD x1, x2, x3
  MEM[1] = 32'b0100000_00110_00101_000_00100_0110011; // SUB x4, x5, x6

  // ───────────── I-TYPE ─────────────
  MEM[2] = 32'b000000010100_00010_000_00101_0010011; // ADDI x5, x2, 20
//MEM[2] = 32'b000000010100_00000_000_00101_0010011; // ADDI x5, x0, 20
  MEM[3] = 32'b000000001010_00011_111_00110_0010011; // ANDI x6, x3, 10
  MEM[4] = 32'b000000010000_00100_010_00111_0000011; // LW x7, 16(x4)
  MEM[5] = 32'b000000000100_00101_000_01000_1100111; // JALR x8, x5, 4

  // ───────────── S-TYPE ─────────────
  MEM[6] = 32'b0000000_01001_00110_010_00100_0100011; // SW x9, 4(x6)
  MEM[7] = 32'b0000000_01010_00111_001_00100_0100011; // SH x10, 4(x7)

  // ───────────── B-TYPE ─────────────
  MEM[8] = 32'b000000_00101_00001_000_00010_1100011; // BEQ x1, x5, +4
  MEM[9] = 32'b000000_01000_00011_001_00010_1100011; // BNE x3, x8, +4

  // ───────────── U-TYPE ─────────────
  MEM[10] = 32'b00000000000000000001_01001_0110111; // LUI x9, 0x1000
  MEM[11] = 32'b00000000000000000010_01010_0010111; // AUIPC x10, 0x2000

  // ───────────── J-TYPE ─────────────
  // JAL x11, +12 → offset = 0x00C
  // encoded as imm[20|10:1|11|19:12]
  MEM[12] = 32'b00000011110000000000_01011_1101111;  // JAL x11, 12
  //            00000111100000000000

  // Optional: HALT custom opcode or NOP (ADDI x0, x0, 0)
  MEM[13] = 32'b000000000000_00000_000_00000_0010011; // NOP
end


*/
/*
initial begin
  // UART base = 0xC0000020
  MEM[0]  = 32'b000000000000_00000_000_01000_0110111; // lui t0, 0xC0000
  MEM[1]  = 32'b000000000100_01000_000_01000_0010011; // addi t0, t0, 0x20

  // GPO base = 0xC0000100
  MEM[2]  = 32'b000000010000_00000_000_01000_0110111; // lui t8, 0xC0001

  // li t1, 651 ? UART DVSR
  MEM[3]  = 32'b001010001011_00000_000_01001_0010011; // addi t1, x0, 651
  MEM[4]  = 32'b0000001_01001_01000_010_00100_0100011; // sw t1, 4(t0)

  // Send 'B' (ACK) to UART
  MEM[5]  = 32'b0000000001000010_00000_01111_0010011; // addi t7, x0, 0x42
  MEM[6]  = 32'b0000010_01111_01000_010_00100_0100011; // sw t7, 8(t0)

  // li t2, 0xC8 ? start of RAM
  MEM[7]  = 32'b000000001100_00000_000_01010_0010011; // addi t2, x0, 0xC8

  // li t3, 4084 ? byte count
  MEM[8]  = 32'b100000111100_00000_000_01011_0010011; // addi t3, x0, 4084

  // li t6, 0 ? LED toggle register
  MEM[9]  = 32'b000000000000_00000_000_01110_0010011; // addi t6, x0, 0

  // receive_loop:
  MEM[10] = 32'b000000000000_01000_000_01100_00000011; // lb t4, 0(t0)
  MEM[11] = 32'b000010000000_01100_111_01100_0010011; // andi t4, t4, 0x100
  MEM[12] = 32'b111111100000_01100_001_00000_1100011; // bne t4, x0, -2

  // lb t5, 0(t0)
  MEM[13] = 32'b000000000000_01000_000_01101_00000011; // lb t5, 0(t0)
  MEM[14] = 32'b000011111111_01101_111_01101_0010011; // andi t5, t5, 0xFF
  MEM[15] = 32'b0000000_01101_01010_000_00000_0100011; // sb t5, 0(t2)
  MEM[16] = 32'b000000000001_01010_000_01010_0010011; // addi t2, t2, 1

  // LED toggle
  MEM[17] = 32'b000000000001_01110_000_01110_0010011; // addi t6, t6, 1
  MEM[18] = 32'b0000000_01110_11000_010_00000_0100011; // sw t6, 0(t8)

  // Clear FIFO
  MEM[19] = 32'b000000000000_00000_000_01111_0010011; // addi t7, x0, 0
  MEM[20] = 32'b0000011_01111_01000_010_01100_0100011; // sw t7, 12(t0)

  // Decrement counter
  MEM[21] = 32'b111111111111_01011_000_01011_0010011; // addi t3, t3, -1
  MEM[22] = 32'b111111000000_01011_001_00000_1100011; // bne t3, x0, -10

  // Send 'D' = 0x44 (done)
  MEM[23] = 32'b0000000001000100_00000_01111_0010011; // addi t7, x0, 0x44
  MEM[24] = 32'b0000010_01111_01000_010_00100_0100011; // sw t7, 8(t0)

  // Jump to app at 0xC8
  MEM[25] = 32'b000000001100_00000_000_01001_0010011; // addi t1, x0, 0xC8
  MEM[26] = 32'b000000000000_01001_000_00000_1100111; // jalr x0, 0(t1)
end

*/


  initial begin
  $readmemh("bootloader_t189.hex",MEM);
  end

   wire [29:0] Word_addr = MEM_addr[31:2];

  always_latch begin 
    if (rMEM_en) begin
        MEM_dout = MEM[Word_addr];
    end
	 
  end


endmodule
