

module SoC #(parameter BRG_BASE = 32'hc000_0000)

    (
    
            input logic CLK,
            input logic RESET,
            //output logic tb_inst,
            input logic [15:0] SW,
            output logic  [15:0] LEDS,
    
            input logic  rx, 
            output logic TXD,
            output logic acl_sclk,
            output logic acl_mosi,
            input  logic acl_miso,
            output logic acl_ss_n,
            output logic ground 

    
    );
    
            wire clk;
            wire resetn;
        
        
            wire [31:0] inter_MEMaddr;
            wire [31:0] inter_MEMdout;
            wire inter_rMEMenable;
            wire [31:0] inter_MEM_Wdata;
            wire inter_wMEM_en; 


            wire inteer_tb_i;


            // Basic bus 
            wire b_mmio_cs; 
            wire b_wr;      
            wire b_rd;     
            wire [20:0] b_addr;       
            wire [31:0] b_wr_data;    
            wire [31:0] b_rd_data;
            
            reg logic_low = 0;   
            assign ground = logic_low;
           
        CPU cpu(
            .CLK(clk),
            .RESET(resetn),
            .tb_i(inteer_tb_i),


            .IO_A(inter_MEMaddr),
            .IOReadS(inter_rMEMenable),
            .IOWriteS(inter_wMEM_en),
            .IO_write(inter_MEM_Wdata),
            .IO_dout(inter_MEMdout)
            
        );

    
        // instantiate bridge
        mcs_bridge #(.BRG_BASE(BRG_BASE))
        bridge_unit (
        .io_address(inter_MEMaddr),
        .io_read_data(inter_MEMdout),
        .io_read_strobe(inter_rMEMenable),
        .io_write_data(inter_MEM_Wdata),
        .io_write_strobe(inter_wMEM_en),
        
        //mmio bit signals
        .b_video_cs(),
        .b_mmio_cs(b_mmio_cs), 
        .b_wr(b_wr),
        .b_rd(b_rd),
        .b_addr(b_addr),
        .b_wr_data(b_wr_data),
        .b_rd_data(b_rd_data)                 
        );
    
    
    
    
   // instantiated i/o subsystem
   mmio_sys #(.N_SW(16),.N_LED(16)) mmio_unit (
   .clk(clk),
   .reset(reset_sys),
   .mmio_cs(b_mmio_cs),
   .mmio_wr(b_wr),
   .mmio_rd(b_rd),
   .mmio_addr(b_addr), 
   .mmio_wr_data(b_wr_data),
   .mmio_rd_data(b_rd_data),
   .sw(SW),
   .led(LEDS),
   .rx(rx),
   .tx(TXD),
   .acl_sclk(acl_sclk),
   .acl_mosi(acl_mosi),
   .acl_miso(acl_miso),
   .acl_ss(acl_ss_n)       
  );           


      clk_divider #(.SLOW(1))
      clk_divider (
  
          .CLK(CLK),
          .RESET(RESET),
          .clk(clk),
          .resetn(resetn)
  
      );
       
		 



				//assign inter_MEMdout = sw;
				//assign led = inter_MEM_Wdata;


				//assign tb_inst = inteer_tb_i;
    
    
    endmodule