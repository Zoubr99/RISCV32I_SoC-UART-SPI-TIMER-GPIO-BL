module gpo 

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
        output logic [31:0]rd_data, // reading data

        // external signal 
        output logic [W-1:0] dout // the output to pass the data from a register within the core
                                      // to the outside world
    );


    logic [W-1:0] buf_reg;
    logic wr_en;

    //body of the core (slot)
    always_ff @(posedge clk, posedge reset) 
        if (reset) 
            buf_reg <= 0; 
        else 
            if (wr_en) 
                buf_reg <= wr_data[W-1:0];
    

    // decoding logic
    // wrapping circuit
    assign wr_en = cs && write; // && (addr = "00000" ); however since it is just an outpu no 
                                // need for assigning the register address  
    // slot read interface
    assign rd_data = 0;
    // external output
    assign dout = buf_reg;
        
endmodule