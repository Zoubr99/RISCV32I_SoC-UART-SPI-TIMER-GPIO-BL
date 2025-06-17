module uart_tx // uart transmitter
   #(
    parameter DBIT = 8,     // # data bits
              SB_TICK = 16  // # 16 ticks for 1 stop bit
   )
   
   (
    // standard core signals
    input  logic clk,
    input  logic reset,

    // inputs into the uart transmitter core
    input  logic tx_start,
    input  logic s_tick,
    input  logic [7:0] din,

    // outputs frome the uart transmitter core
    output logic tx_done_tick, // to the cpu core 
    output logic tx // to the outside world
   );

   // fsm state type 
   typedef enum {idle, start, data, stop} state_type; // basic uart protocol transmission states

   // idle : idle state , nothing going on, waiting for the rx (start bit ) to go low
   // start : start bit smapling state
   // data : the data bits sampling state
   // stop : stop bit state

   // signal declaration
   state_type state_reg, state_next;
   logic [3:0] s_reg, s_next; // ticks counter
   logic [2:0] n_reg, n_next; // (number of bits) received during transmission
   logic [7:0] b_reg, b_next; // received bits registers
   logic tx_reg, tx_next; // 

   // body
   // FSMD state & data registers
   always_ff @(posedge clk, posedge reset)
      if (reset) begin
         state_reg <= idle;
         s_reg <= 0;
         n_reg <= 0;
         b_reg <= 0;
         tx_reg <= 1'b1;
      end
      else begin
         state_reg <= state_next;
         s_reg <= s_next;
         n_reg <= n_next;
         b_reg <= b_next;
         tx_reg <= tx_next;
      end

   // FSMD next-state logic & functional units
   always_comb
   begin
      state_next = state_reg;
      tx_done_tick = 1'b0;
      s_next = s_reg;
      n_next = n_reg;
      b_next = b_reg;
      tx_next = tx_reg ;
      case (state_reg) // this will be the latched state (idle)
         idle: begin
            tx_next = 1'b1; // during idle state the tx is set to 0
            if (tx_start) begin // as soon as a signal from the cpu is present
               state_next = start; // set the next state to be the transmission start state
               s_next = 0; // not used yet
               b_next = din;
            end
         end
         start: begin
            tx_next = 1'b0; // set the tx to be 0 indicating start of transmitting
            if (s_tick) // keep increasing the s_reg every s_tick till it raeches the 15 
               if (s_reg==15) begin // when s_reg is 15 
                  state_next = data; // set the next state to be data transmitting state
                  s_next = 0; // set the s_next to be zero
                  n_next = 0;
               end
               else
                  s_next = s_reg + 1;
         end
         data: begin // data sampling and storing state
            tx_next = b_reg[0]; // keep sampling the least sig bit into the tx internal reg
            if (s_tick)
               if (s_reg==15) begin // same thing 15 ticks for each bit to get to the mid
                  s_next = 0; // reset the ticks counter
                  b_next = b_reg >> 1; // shift the b_reg bits to the right 1 bit, so it could be sampled into the tx signal
                  if (n_reg==(DBIT-1)) // keep increasing the bits counter untill all bits been shifted and sampled
                     state_next = stop ; // after the smapling has finished jump into the next state (stop bit state)
                  else
                     n_next = n_reg + 1; 
               end
               else
                  s_next = s_reg + 1;
         end
         stop: begin
            tx_next = 1'b1; // set the tx line to be 1 to indicate a stop bit
            if (s_tick)
               if (s_reg==(SB_TICK-1)) begin // in the stop bits since uart stop bit can be configured as (1 - 1.5 - 2) bits, ticks number will be configurable
                  state_next = idle; // when the number of ticks reach the specefied ticks (16 | 24 | 32), transmission is finished -> go abck to idle state
                  tx_done_tick = 1'b1; // set this signal 1 to indicate end of transmission before going idle
               end
               else
                 s_next = s_reg + 1;
         end
      endcase
   end
   // output
   assign tx = tx_reg; // assign the tx internal register to the tx pin (output to the outside world)
endmodule