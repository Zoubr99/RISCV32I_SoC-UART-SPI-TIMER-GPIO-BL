module mmio_controller 

        // mmio_controller core (memmory mapped io) -> this core is interface between the Basic Bus and the IO cores

    (   // Standard signals
        input logic clk, 
        input logic reset,

        //inputs from the uC basic bus into the mmio controller
        // left side of the mmio controller ip core
        input  logic mmio_cs,
        input  logic mmio_wr,
        input  logic mmio_rd,
        input  logic [20:0] mmio_addr, // 11 LSB used; 2^6 slot/2^5 reg each 
        input  logic [31:0] mmio_wr_data,
        // reading output
        output logic [31:0] mmio_rd_data,


        // slot interface
        // outputs from the mmio controller core to the slots - right side of the mmio controller ip core
        // 64 means there are 64 slots
        output logic [63:0] slot_cs_array,
        output logic [63:0] slot_mem_rd_array,
        output logic [63:0] slot_mem_wr_array,
        output logic [4:0]  slot_reg_addr_array [63:0],
        input  logic  [31:0] slot_rd_data_array [63:0], 
        output logic [31:0] slot_wr_data_array [63:0]
    );

   // internal signals
   logic [5:0] slot_addr; // dividing the addr into 2 seperate signals (slot addr and reg addr)
   logic [4:0] reg_addr;

   // body
   assign slot_addr = mmio_addr[10:5]; // bits 10:5 indicate which core (slot) to be enabled
   assign reg_addr  = mmio_addr[4:0]; // bits 4:0 indicate which register withing the enabled slot to be written to or read from

   // address decoding
   always_comb
   begin
      slot_cs_array = 0; // assign slot sc to 0 always as it is a combinational logic
      if (mmio_cs)
         slot_cs_array[slot_addr] = 1; // if cs of the mmio core is 1 then enable the slot indicated by (slot_addr)
   end
   
   // broadcast to all slots 
   // generating 64 mmio output signals in case any extra coress were added the mmio controller will be pre configured
   generate
      genvar i;
      for (i=0; i<5; i=i+1) 
      begin:  slot_signal_gen
         assign slot_mem_rd_array[i] = mmio_rd;
         assign slot_mem_wr_array[i] = mmio_wr;
         assign slot_wr_data_array[i] = mmio_wr_data;
         assign slot_reg_addr_array[i] = reg_addr;
      end
   endgenerate

   // reading op
   // mux for read data 
   assign mmio_rd_data = slot_rd_data_array[slot_addr];   // basically a multiplexer mmio_rd_data <- slot_rd_data_array[slot_addr]

endmodule