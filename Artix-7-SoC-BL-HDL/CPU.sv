module CPU(

    input logic CLK,
    input logic RESET,
    output logic tb_i,

    
    output logic [31:0] IO_A,
    output logic [1:0] IOReadS,
    output logic IOWriteS,

    output logic [31:0] IO_write,
    input logic [31:0] IO_dout
);

        

    
    
        wire clk;
        wire resetn;
    
     
    
        wire [31:0] inter_MEMaddr;
        wire [31:0] inter_MEMdout;
        wire        inter_rMEMenable;

        wire [7:0]  inter_ALUc [3:0];
        wire [31:0] inter_alu1;
        wire [31:0] inter_alu2;
        wire [31:0] inter_aluOut;
        wire        inter_Zero;

        wire [31:0] inter_A1;
        wire [31:0] inter_A2;
        wire [31:0] inter_A3;
        wire [31:0] inter_RD1;
        wire [31:0] inter_RD2;
        wire [31:0] inter_WD3;
        wire inter_rMEM_en_reg;
        wire inter_ereg_Write;

        wire        inter_MemWrite;     
        wire [2:0]  inter_MemSize;
        wire [1:0]  inter_MemRead; // 00: byte, 01: halfword, 10: word 
        wire [31:0] inter_A_Ram;
        wire [31:0] inter_WriteData;
        logic [31:0] inter_ReadData;

        wire [31:0] inter_RAM_WriteData;
        wire [31:0] inter_RAM_dout;

        wire [6:0] inter_states;

        wire isIO = (inter_A_Ram[31:24] == 8'b1100_0000); // SoC
        wire isRAM = !isIO;

        
    Ins_Memmory rom 
    (
        .clk(CLK),
        .MEM_addr(inter_MEMaddr),
        .MEM_dout(inter_MEMdout),
        .rMEM_en(inter_rMEMenable) 
    );





    Control_unit cu
    (
        .clk(CLK),
        .resetn(RESET),

        .MEM_addr(inter_MEMaddr),
        .MEM_dout(inter_MEMdout),
        .rMEM_en(inter_rMEMenable),

        .RD1(inter_RD1),
        .RD2(inter_RD2),
        .A1(inter_A1),
        .A2(inter_A2),
        .A3(inter_A3),   
        .WD3(inter_WD3),
        .rMEM_en_reg(inter_rMEM_en_reg),
        .eRegWrite(inter_ereg_Write),   

        .ALUc(inter_ALUc),
        .aluSrcA(inter_alu1),
        .aluSrcB(inter_alu2),
        .ALUResult(inter_aluOut),
        .Zero(inter_Zero),

        .MemWrite(inter_MemWrite),
        .MemRead(inter_MemRead),
        .MemSize(inter_MemSize), // 00: byte, 01: halfword, 10: word 
        .A_Ram(inter_A_Ram),
        .WriteData(inter_WriteData),
        .ReadData(inter_ReadData),

        .states(inter_states),
        
        .tb_instruction(tb_i)
    );

    ALU alu
    (
        .ALUc(inter_ALUc),
        .aluSrcA(inter_alu1),
        .aluSrcB(inter_alu2),
        .ALUResult(inter_aluOut),
        .Zero(inter_Zero)
    );

    RAM ram(
        .clk(CLK),
        .resetn(RESET),
        .MemWrite(isRAM & inter_MemWrite),
    
        .MemRead(inter_MemRead),
        .MemSize(inter_MemSize), // 00: byte, 01: halfword, 10: word
    
        .A_Ram(inter_A_Ram),
        .WriteData(inter_RAM_WriteData),
        .ReadData(inter_RAM_dout)
    );

    RegisterFile regf
    (
        .clk(CLK),
        .resetn(RESET),
         
        .rMEM_en_reg(inter_rMEM_en_reg),
        .eRegWrite(inter_ereg_Write),
        .A1(inter_A1),
        .A2(inter_A2),
        .A3(inter_A3),
        .states(inter_states),      
        .RD1(inter_RD1),
        .RD2(inter_RD2),
        .WD3(inter_WD3)
    );


    assign inter_ReadData = isRAM ? inter_RAM_dout : IO_dout;    
    //ssign inter_WriteData = isRAM ? inter_RAM_WriteData : IO_write; 
    assign inter_RAM_WriteData = isRAM? inter_WriteData : 0;
    assign IO_write = isIO ? inter_WriteData : 0;
    assign IO_A = inter_A_Ram;
    assign IOReadS = isIO & inter_MemRead;
    assign IOWriteS = isIO & inter_MemWrite;
    

endmodule