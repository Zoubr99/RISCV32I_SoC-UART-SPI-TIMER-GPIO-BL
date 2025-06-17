//  * Reg map;

//    * 00: read (32 LSB of counter)    //
//    * 01: read (16 MSB of counter)    //
//    * 10: control register:           // where:
                                        //      bit 0: go/pause               
                                        //      bit 1: clear (no memory, just used to generate a 1-clock pulse)


// 48-bit counter

module timer 

    #(parameter W = 8)

    (   // Standard signal 
        input logic clk, 
        input logic reset,

        //Slot interface - standard for all the cores
        //wrapping circuit signals
        input logic cs, // chip select
        input logic read, // reading signal
        input logic write, // writing signal
        input logic [4:0] addr, // address of the register within the core 2^5 = 32 regs
                                // in which to write to or read from

        input logic [31:0]wr_data, // writing data 
        output logic [31:0]rd_data // reading data
    );


    // internal signals
    logic [47:0] count_reg; // holds the counting 
    logic cntrl_reg; // holds the controling bits 
    logic wr_en, clear, go;


    // a basic counter
    always_ff @(posedge clk, posedge reset)
         if (reset)
            count_reg <= 0;
         else 
            if (clear)
                count_reg <= 0;
            else if (go)
                count_reg <= count_reg + 1;


    // wrapping circuit
    always_ff @(posedge clk, posedge reset)
        if (reset) 
            cntrl_reg <= 0;
        else 
            if (wr_en) 
                cntrl_reg <= wr_data[0]; // 32 bit word, only take the LSB
    
    // decoding logic
    assign wr_en = write && cs && (addr[1:0] == 2'b10); // take the least 2 SB of the addr
                                                       // sets wr_en if write and cs and the adress to 
                                                       // to be writting to is the 3rd register withing the core

    assign clear = wr_en && wr_data[1]; // takes the above addressing and adds the bit address to write to bit 1 and not 0         
    assign go = cntrl_reg; // just renaming cntr_reg to go "1 bit" 

    // slot read interface 
    assign rd_data = (addr[0]== 0)? count_reg[31:0]:  // if the first register did not rich 1, read bits of first register
                                    {16'h0000, count_reg[47:32]}; // if the first register was full only read and multiplex the first 16 bits of the
                                                                  // second register
        
 
endmodule