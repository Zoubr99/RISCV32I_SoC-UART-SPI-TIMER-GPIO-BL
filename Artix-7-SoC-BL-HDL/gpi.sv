module gpi 

    #( parameter W = 8) // number of input bits 8 switches

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
        output logic [31:0]rd_data, // reading data

        // external signal 
        input logic [W-1:0] din // the input to pass the data from outside world
                                    // to a register within the core
    );


    // internal register 
    logic [W-1:0] rd_data_reg;

    // body of the core (slot)
    always_ff @(posedge clk, posedge reset)
        if (reset) 
            rd_data_reg <= 0;
        else 
            rd_data_reg <= din;

    assign rd_data[W-1:0] = rd_data_reg; // assign the first 8 bits to the data reg 
    assign rd_data[31:W] = 0; // assign the rest of the bits to 0
              
endmodule