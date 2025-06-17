module spi(

    // standard signals
    input logic clk,
    input logic reset,

    input logic [7:0] din, // data to be sent from uP to the SPI Core, transmission.
    output logic [7:0] dout, // data to be sent from the SPI Core to the uP, recieving.

    input logic [15:0] dvsr, // clock divider

    input logic start, // indicates start of transmission
    input logic cpol, // clock polarity to be used when generating clock signal
    input logic cpha, // clock phase to be used when generating clock signal

    output logic spi_done_tick, // indicates end of transmission
    output logic ready, // 

    // internal spi signals 
    output logic sclk,
    input logic miso,
    output logic mosi

);


// now we need a state machine with 4 diffrent states

typedef enum  { idle, cpha_delay, p0, p1 } state_type;
state_type reg_state, next_state;


// internal signals (regesterd signals and new signals)
logic reg_spi_clk, next_spi_clk;
logic [15:0] reg_count, next_count;
logic [2:0] reg_bitn, next_bitn;
logic [7:0] reg_serialo, next_serialo; // from master to slave
logic [7:0] reg_serialin, next_serialin; // from slave to master

logic ready_i, spi_done_tick_i;
logic p_clk;

    // Register Block (flip_flops)
    always_ff @(posedge clk, posedge reset) begin
        if(reset)begin
            reg_state <= idle;
            reg_serialin <= 0;
            reg_serialo <= 0;
            reg_bitn <= 0;
            reg_count <= 0;
            reg_spi_clk <= 0;
        end
        else begin
            reg_state <= next_state;
            reg_serialin <= next_serialin;
            reg_serialo <= next_serialo;
            reg_bitn <= next_bitn;
            reg_count <= next_count;
            reg_spi_clk <= next_spi_clk;
        end
    end

    always_comb 
    begin

        next_state = reg_state;
        next_serialin = reg_serialin;
        next_serialo = reg_serialo;
        next_bitn = reg_bitn;
        next_count = reg_count;

        ready_i = 0;
        spi_done_tick_i = 0;

        case (reg_state)
//****************************** idle state **********************************//
        idle: begin   
            ready_i = 1;
                if (start) begin
                    next_serialo = din;
                    next_count = 0;
                    next_bitn = 0;
                    if (cpha)
                        next_state = cpha_delay;                    
                    else
                        next_state = p0;
                end
        end

//****************************** phase 1 delay state **********************************//
        cpha_delay: begin
            if (reg_count == dvsr) begin
                next_state = p0;
                next_count = 0;
            end 
            else 
                next_count = reg_count + 1 ;
        end

//************************************ now p0 ****************************************//

        p0: begin
            if (reg_count == dvsr) begin
                next_state = p1;
                next_serialin = {reg_serialin[6:0], miso};
                next_count = 0;
            end
            else begin
                next_count = reg_count + 1;
            end
        end

//************************************ now p1 ****************************************//
        p1: begin
            if (reg_count == dvsr)
                if (reg_bitn == 7) begin
                spi_done_tick_i = 1;
                next_state = idle;
                end
                else begin
                next_serialo = {reg_serialo[6:0], 1'b0};
                next_state = p0;
                next_bitn = reg_bitn + 1;
                next_count = 0;
                end
            else 
                next_count = reg_count + 1;
        end



//***********************************************************************************//  
        endcase            
    end

assign ready = ready_i;
assign spi_done_tick = spi_done_tick_i;

assign p_clk = (next_state == p1 && ~cpha) || (next_state == p0 && cpha);

assign next_spi_clk = (cpol) ? ~p_clk : p_clk;

assign dout = reg_serialin;
assign mosi = reg_serialo[7];
assign sclk = reg_spi_clk;
    
endmodule