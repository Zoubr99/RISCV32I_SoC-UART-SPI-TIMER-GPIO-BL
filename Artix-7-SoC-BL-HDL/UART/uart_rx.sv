module uart_rx // uart reciever core
   #(
    parameter DBIT = 8,     // # data bits
              SB_TICK = 16  // # ticks for stop bits
   )

   (
   // standard core signals
    input  logic clk,
    input  logic reset,

    // inputs into the uart reciever core
    input  logic rx, // input from the outside world
    input  logic s_tick, // baud reg ticks

    // outputs frome the uart reciever core
    output logic rx_done_tick,
    output logic [7:0] dout
   );

   // fsm state type 
   typedef enum {idle, start, data, stop} state_type; // basic uart protocol transmission states

   // idle : idle state , nothing going on, waiting for the rx (start bit ) to go low
   // start : start bit smapling state
   // data : the data bits sampling state
   // stop : stop bit state

   // internal signals declaration
   state_type state_reg, state_next;
   logic [3:0] s_reg, s_next; // ticks counter
   logic [2:0] n_reg, n_next; // (number of bits) received during transmission
   logic [7:0] b_reg, b_next; // received bits registers

   // body
   // FSMD state & data registers
   always_ff @(posedge clk, posedge reset)
      if (reset) begin
         state_reg <= idle;
         s_reg <= 0;
         n_reg <= 0;
         b_reg <= 0;
      end
      else begin
         state_reg <= state_next;
         s_reg <= s_next;
         n_reg <= n_next;
         b_reg <= b_next;
      end

   // FSMD next-state logic
   always_comb
   begin
      state_next = state_reg;
      rx_done_tick = 1'b0;
      s_next = s_reg;
      n_next = n_reg;
      b_next = b_reg;
      case (state_reg) // this will be the latched state (idle)
         idle:
            if (~rx) begin // the ~rx here plays as the starting bit in UART transmission protocol, rx = 0 means trans started
               state_next = start; // since rx went 0 means transmission started therfore go to the next state
               s_next = 0;
            end
         start:
            if (s_tick) // during UART transmission there is a oversampling process that helps reduce sampling errors
               if (s_reg==7) begin // start bit will be sampled in the mid (1 bit is 16 ticks, therefore this would be 7 ticks)
                  state_next = data; // at the 7th tick set the next state to be the data bits sampling state
                  s_next = 0; // set the s next to 
                  n_next = 0; // start bit is just 1 bit thefore this reg is not used
               end
               else
                  s_next = s_reg + 1; // this keeps increasing till it reaches 7
         data:
            if (s_tick)// in the prev state the we stopped at the mid of the start bit, (7 bits since the rx gone 0)
               if (s_reg==15) begin // to get to the mid of the next bit  16 ticks would be needed.
                  s_next = 0; // on the 15th tick set the ticks counter to 0
                  b_next = {rx, b_reg[7:1]}; // sample the bit by "or"ing rx with b_reg {rx[0] + ( b_reg[01111111] - [1] )= b_next[01111111]}
                  if (n_reg==(DBIT-1)) // (DBIT-1) is the number of data bits the uart transmission is set to
                     state_next = stop ; // after sampling all the bits (DBIT-1) set the next state to be moved to (stop bit)
                  else
                     n_next = n_reg + 1; // keep increasing untill the count raches the number of bits specified by the (DBIT-1)
               end
               else
                  s_next = s_reg + 1; // ticks would keep increasing till it reaches 15 
         stop: // last state (stop bit)
            if (s_tick)
               if (s_reg==(SB_TICK-1)) begin // in the stop bits since uart stop bit can be configured as (1 - 1.5 - 2) bits, ticks number will be configurable
                  state_next = idle; // when the number of ticks reach the specefied ticks (16 | 24 | 32), transmission is finished -> go abck to idle state
                  rx_done_tick =1'b1; // set this signal 1 to indicate end of transmission before going idle
               end
               else
                  s_next = s_reg + 1;
      endcase
   end
   // output
   assign dout = b_reg; // asssign the bits sampled and stored inside the b_reg to be stored in the dout signal (output)
endmodule