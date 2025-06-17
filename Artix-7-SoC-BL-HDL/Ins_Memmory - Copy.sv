module Ins_Memmory(
  input  logic         clk, 
  input  logic [31:0]  MEM_addr,
  output logic [31:0]  MEM_dout,
  input  logic         rMEM_en,

  // Write port - Bootloader writes
  input  logic         MEM_we,
  input  logic [31:0]  MEM_Waddr,
  input  logic [31:0]  MEM_Wdata,
  output logic [31:0]  bl_dout,
  input  logic         MemRead    // Write strobes for byte-wise writing
);
  
  reg [31:0] MEM [0:8000];

  initial begin
      $readmemh("firmware.hex", MEM);
  end

  wire [10:0] Raddr = MEM_addr[31:2];




  // Write Operation
  always_ff @(posedge clk) begin
     if (MEM_we) begin
        MEM[MEM_Waddr] <= MEM_Wdata[31:0];
     end
   end



  always_comb begin
     if (rMEM_en) begin
      MEM_dout = MEM[Raddr];
     end
     else if (MemRead) begin
      bl_dout = MEM[MEM_Waddr];
     end
  end

endmodule
