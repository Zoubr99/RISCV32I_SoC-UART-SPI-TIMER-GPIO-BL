module RAM (
    input logic clk,
    input logic resetn,
    input logic MemWrite,
    input logic MemRead,
    input logic [2:0] MemSize, // 00: byte, 01: halfword, 10: word
    input logic [31:0] A_Ram,
    input logic [31:0] WriteData,
    output logic [31:0] ReadData
);

/*
    logic [7:0] Memmory [0:150000]; // 1KB memory spacey

    always_ff @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            begin
                $readmemh("testing_code_C_F.hex",Memmory);
            end
        end else if (MemWrite) begin
            case (MemSize)
                3'b000: Memmory[A_Ram] <= WriteData[7:0]; // Byte write
                3'b001: begin // Halfword write
                    Memmory[A_Ram]     <= WriteData[7:0];
                    Memmory[A_Ram + 1] <= WriteData[15:8];
                end
                3'b010: begin // Word write
                    Memmory[A_Ram]     <= WriteData[7:0];
                    Memmory[A_Ram + 1] <= WriteData[15:8];
                    Memmory[A_Ram + 2] <= WriteData[23:16];
                    Memmory[A_Ram + 3] <= WriteData[31:24];
                end
            endcase
        end
    end

    always_ff @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            ReadData <= 32'b0;
        end else begin
            if (MemRead) begin
                case (MemSize)
                    3'b000: ReadData <= {24'b0, Memmory[A_Ram]}; // Byte
                    3'b001: ReadData <= {16'b0, Memmory[A_Ram + 1], Memmory[A_Ram]}; // Halfword
                    3'b010: ReadData <= {Memmory[A_Ram + 3], Memmory[A_Ram + 2], Memmory[A_Ram + 1], Memmory[A_Ram]}; // Word
                    default: ReadData <= 32'b0; // Safe default
                endcase
            end else begin
                ReadData <= 32'b0; // Always set to 0 when not reading
            end
        end
    end





*/


 logic [31:0] Memory [0:8000]; // 150000 words (32-bit each)

    
  initial begin
  $readmemh("bootloader_t189.hex",Memory);
  end
    

    logic [31:0] read_word;
    logic [17:0] word_addr;
    logic [1:0]  byte_offset;
    logic [1:0] mem_sze;

    assign word_addr   = A_Ram[31:2];   // Word address
    assign byte_offset = A_Ram[1:0];    // Offset within the 32-bit word
    assign mem_sze = MemSize[1:0];

    // Read Operation
    always_ff @(posedge clk) begin
        if (MemRead) begin
            read_word = Memory[word_addr];

            case (mem_sze)
                2'b00: begin // Byte
                    case (byte_offset)
                        2'b00: ReadData <= {24'b0, read_word[7:0]};
                        2'b01: ReadData <= {24'b0, read_word[15:8]};
                        2'b10: ReadData <= {24'b0, read_word[23:16]};
                        2'b11: ReadData <= {24'b0, read_word[31:24]};
                    endcase
                end

                2'b01: begin // Halfword
                    if (byte_offset[1] == 1'b0) begin
                        ReadData <= (byte_offset[0] == 1'b0) ?
                            {16'b0, read_word[15:0]} :
                            {16'b0, read_word[31:16]};
                    end else begin
                        ReadData <= 32'b0; // Unaligned halfword access returns 0
                    end
                end

                2'b10: begin // Word
                    if (byte_offset == 2'b00)
                        ReadData <= read_word;
                    else
                        ReadData <= 32'b0; // Unaligned word access returns 0
                end

                default: ReadData <= 32'b0;
            endcase
        end
    end
    
    

    // Write Operation
    always_ff @(posedge clk) begin
        //if (!resetn) begin
            //$readmemh("testing_code_c6.hex",Memory);
        //end else
         if (MemWrite) begin
            case (mem_sze)
                2'b00: begin // Byte
                    case (byte_offset)
                        2'b00: Memory[word_addr][7:0]   <= WriteData[7:0];
                        2'b01: Memory[word_addr][15:8]  <= WriteData[7:0];
                        2'b10: Memory[word_addr][23:16] <= WriteData[7:0];
                        2'b11: Memory[word_addr][31:24] <= WriteData[7:0];
                    endcase
                end

                2'b01: begin // Halfword
                    if (byte_offset[1] == 1'b0) begin
                        if (byte_offset[0] == 1'b0)
                            Memory[word_addr][15:0] <= WriteData[15:0];
                        else
                            Memory[word_addr][31:16] <= WriteData[15:0];
                    end
                end

                2'b10: begin // Word
                    if (byte_offset == 2'b00)
                        Memory[word_addr] <= WriteData;
                end
            endcase
        end
    end




endmodule
