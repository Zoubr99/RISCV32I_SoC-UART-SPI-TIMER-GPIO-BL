// baud rate generater (divisor) 
// divided by (dvsr+1)

module baud_gen
   (
    // standard signals
    input  logic clk,
    input  logic reset,

    // diviser input (the number to be devided by)
    input  logic [10:0] dvsr,

    //output signal into the UART tx and rx 
    output logic tick
   );

   // internal signals declaration
   logic [10:0] r_reg;
   logic [10:0] r_next;

   // body
   // this is acting just like a simple state machine
   always_ff @(posedge clk, posedge reset)
      if (reset)
         r_reg <= 0;
      else
         r_reg <= r_next; // on each clock edge assign the ouput of the comb logic into the register

   // next-state logic
   assign r_next = (r_reg==dvsr) ? 0 : r_reg + 1; // output of the comb logic is either (latched state +1) or 0
                                                  // depending on the dvsr input if r_reg == dvsr set comb logic output accordingly
   // output logic                                 
   assign tick = (r_reg==1);
endmodule