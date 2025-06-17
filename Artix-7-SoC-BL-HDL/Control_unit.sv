
module Control_unit( // declaring the inputs and outputs
  input logic clk,
  input logic resetn,
  input logic [31:0] MEM_dout,

  output logic [31:0] MEM_addr,
  output logic rMEM_en,

  input reg [31:0] RD1,
  input reg [31:0] RD2,
  output logic [4:0] A1,
  output logic [4:0] A2,
  output logic [4:0] A3,
  output reg [31:0] WD3,
  output logic rMEM_en_reg,
  output logic  eRegWrite,


  output logic [7:0] ALUc [3:0],
  output logic [31:0] aluSrcA,
  output logic [31:0] aluSrcB,
  input logic [31:0] ALUResult,
  input logic Zero,

  output logic MemWrite,
  output logic MemRead,
  output logic [2:0] MemSize,
  output logic [31:0] A_Ram,
  output logic [31:0] WriteData,
  input logic [31:0] ReadData,

  output logic [6:0] states,


  output logic [31:0] tb_instruction
);

// declaring a 5 bit register
//reg [31:0] MEM [0:255]; // BRAM
reg [31:0] PC = 0; // Program Counter
reg [31:0] C_INST; // current instruction

reg [6:0] opCode;

always_comb begin
 opCode = C_INST[6:0];
end


 // RISCV instructions Decoder
//*********************************************************************************//
//*********************************************************************************//

  // p.130 Volume I: RISC-V Unprivileged ISA V20191213
   // The 10 RISC-V instructions
  wire ALUreg  =  (opCode  == 7'b0110011); // rd <- rs1 OP rs2
  wire ALUimm  =  (opCode == 7'b0010011); // rd <- rs1 OP Iimm
  wire isBranch  =  (opCode == 7'b1100011); // if(rs1 OP rs2) PC<-PC+Bimm
  wire JALR    =  (opCode == 7'b1100111); // rd <- PC+4; PC<-rs1+Iimm
  wire JAL     =  (opCode == 7'b1101111); // rd <- PC+4; PC<-PC+Jimm
  wire AUIPC   =  (opCode == 7'b0010111); // rd <- PC + Uimm
  wire LUI     =  (opCode == 7'b0110111); // rd <- Uimm   
  wire Load    =  (opCode == 7'b0000011); // rd <- mem[rs1+Iimm]
  wire Store   =  (opCode == 7'b0100011); // mem[rs1+Simm] <- rs2
  wire SYSTEM  =  (opCode == 7'b1110011); // special
  
   /*
   wire [31:0] I_imm={{21{C_INST[31]}}, C_INST[30:20]};
   wire [31:0] S_imm={{21{C_INST[31]}}, C_INST[30:25],C_INST[11:7]};
   wire [31:0] B_imm={{20{C_INST[31]}}, C_INST[7],C_INST[30:25],C_INST[11:8],1'b0};
   wire [31:0] U_imm={    C_INST[31],   C_INST[30:12], {12{1'b0}}};
   wire [31:0] J_imm={{12{C_INST[31]}}, C_INST[19:12],C_INST[20],C_INST[30:21],1'b0};
  */
  wire [31:0] U_imm={    C_INST[31],   C_INST[30:12], {12{1'b0}}};
  wire [31:0] I_imm={{21{C_INST[31]}}, C_INST[30:20]};
  wire [31:0] S_imm={{21{C_INST[31]}}, C_INST[30:25],C_INST[11:7]};
  wire [31:0] B_imm={{20{C_INST[31]}}, C_INST[7],C_INST[30:25],C_INST[11:8],1'b0};
  wire [31:0] J_imm={{12{C_INST[31]}}, C_INST[19:12],C_INST[20],C_INST[30:21],1'b0};



// Source and destination registers
 assign A1 = C_INST[19:15]; // source reg 1 
 assign A2 = C_INST[24:20]; // source reg 2
 assign A3  = C_INST[11:7]; // destenation reg


// function codes
 wire [2:0] funct3 = C_INST[14:12]; // function to be performed on src 1 and 2 regs
 wire [6:0] funct7 = C_INST[31:25];

//*********************************************************************************//
//*********************************************************************************//

 logic [31:0] RegWriteResult;
 logic        RegWrite; 
 //wire [1:0]  ResultSrc;
 logic [2:0]  ImmSrc;
 logic        ALUSrc;
 //wire        MemWrite;
 logic [2:0]  ResultSrc;
 logic        Branch;
 logic [1:0]  ALUOp;
 logic        Jump;

//*********************************************************************************//
//*********************************************************************************//

 always_comb begin
   // Default values
   //RegWrite  = 0;
   ImmSrc    = 3'b000;
   ALUSrc    = 0;
   //MemWrite  = 0;
   ResultSrc = 3'b000;
   Branch    = 0;
   ALUOp     = 2'b00;
   Jump      = 0;

   case (opCode)
       7'b0000011: begin  // Load
          // RegWrite  = 1;
           ImmSrc    = 3'b000;
           ALUSrc    = 1;
          // MemWrite  = 0;
           ResultSrc = 3'b001;
           Branch    = 0;
           ALUOp     = 2'b00;
           Jump      = 0;
           MemSize   = funct3; // Use funct3 for memory size
        //   MemRead   = 1;
       end

       7'b0100011: begin  // S-Type - Store
          // RegWrite  = 0;
           ImmSrc    = 3'b001;
           ALUSrc    = 1;
          // MemWrite  = 1;
           ResultSrc = 3'bxxx; // Don't care
           Branch    = 0;
           ALUOp     = 2'b00;
           Jump      = 0;
           MemSize   = funct3; // Use funct3 for memory size
        //   MemRead   = 0;
       end

       7'b0110011: begin  // R-type (ALU operations)
          // RegWrite  = 1;
           ImmSrc    = 3'bxxx; // Don't care
           ALUSrc    = 0;
          // MemWrite  = 0;
           ResultSrc = 3'b000;
           Branch    = 0;
           ALUOp     = 2'b10;
           Jump      = 0;
           MemSize   = 3'b000;
        //   MemRead   = 0;
       end

       7'b1100011: begin  // B-Type - Branches
          // RegWrite  = 0;
           ImmSrc    = 3'b010;
           ALUSrc    = 0;
          // MemWrite  = 0;
           ResultSrc = 3'bxxx; // Don't care
           Branch    = 1;
           ALUOp     = 2'b01;
           Jump      = 0;
           MemSize   = 3'b000;
        //   MemRead   = 0;
       end

       7'b0010011: begin  // I-Type - ALU Immediate
          // RegWrite  = 1;
           ImmSrc    = 3'b000;
           ALUSrc    = 1;
          // MemWrite  = 0;
           ResultSrc = 3'b000;
           Branch    = 0;
           ALUOp     = 2'b10;
           Jump      = 0;
           MemSize   = 3'b000;
        //   MemRead   = 0;
       end

       7'b0010111: begin  // I-Type - ALU Immediate
        // RegWrite  = 1;
         ImmSrc    = 3'b000;
         ALUSrc    = 1;
        // MemWrite  = 0;
         ResultSrc = 3'b000;
         Branch    = 0;
         ALUOp     = 2'b10;
         Jump      = 0;
         MemSize   = 3'b000;
      //   MemRead   = 0;
     end

     7'b0110111: begin  // I-Type - LUI Immediate
      // RegWrite  = 1;
       ImmSrc    = 3'b100;
       ALUSrc    = 1'b0;
      // MemWrite  = 0;
       ResultSrc = 3'b011;
       Branch    = 0;
       ALUOp     = 2'b10;
       Jump      = 0;
       MemSize   = 3'b000;
    //   MemRead   = 0;
   end

       7'b1101111: begin  // J-Type - Jumps JAL
          // RegWrite  = 1;
           ImmSrc    = 3'b011;
           ALUSrc    = 1'bx; // Don't care
          // MemWrite  = 0;
           ResultSrc = 3'b010;
           Branch    = 0;
           ALUOp     = 2'bxx; // Don't care
           Jump      = 1;
           MemSize   = 3'b000;
        //   MemRead   = 0;
       end

       7'b1100111: begin  // J-Type - Jumps JALR
        // RegWrite  = 1;
         ImmSrc    = 3'b000;
         ALUSrc    = 1'b1; // Don't care
        // MemWrite  = 0;
         ResultSrc = 3'b010;
         Branch    = 0;
         ALUOp     = 2'bxx; // Don't care
         Jump      = 0;
         MemSize   = 3'b000;
      //   MemRead   = 0;
     end



       default: begin
           // Default case ensures stability
          // RegWrite  = 0;
           ImmSrc    = 3'b000;
           ALUSrc    = 0;
          // MemWrite  = 0;
           ResultSrc = 3'b101;
           Branch    = 0;
           ALUOp     = 2'b00;
           Jump      = 0;
           MemSize   = 3'b000;
        //   MemRead   = 0;
       end
   endcase
 end

 assign PCSrc = (Branch & Zero) | Jump; // Zero is set by the Branching comparison in the ALU, and Branch is set when it is B-Type operation
                                        // Jump is set when it is J-Type operation

//*********************************************************************************//
//*********************************************************************************//

 // PCNext and immediate logic

 logic [31:0] ImmExt;

 always_comb begin
   case (ImmSrc)
       3'b000: ImmExt = I_imm; // I-type
       3'b001: ImmExt = S_imm; // S-type
       3'b010: ImmExt = B_imm; // B-type
       3'b011: ImmExt = J_imm; // J-type
       3'b100: ImmExt = U_imm; // U-type
       default: ImmExt = 32'b0;
   endcase
 end

 wire [31:0] PCTarget = PC + ImmExt;
 wire [31:0] PCplus4 = PC + 4;


//*********************************************************************************//
//*********************************************************************************//

 // ALU inputs, stage decoding

 wire [31:0] aluSrc1 = RD1;
 wire [31:0] aluSrc2 = ALUSrc ? ImmExt : RD2;

 assign aluSrcA = aluSrc1;
 assign aluSrcB = aluSrc2;

//*********************************************************************************//
//*********************************************************************************//

 // PCNext and immediate logic

 wire [31:0] aluPlus = aluSrc1 + aluSrc2;

 wire [31:0] PCNext = PCSrc? PCTarget: // (PC + immed)
 JALR ?  {aluPlus[31:1], 1'b0}: // (rs1 + immed) --> aluIn2 = isALUreg | isBranch ? rs2 : Iimm; , therfore aluPlus = rs1 + Iimm since it is JALR it is Iimm
 PCplus4;



//*********************************************************************************//
//*********************************************************************************//
 
 // Data Memmory loading to reg, stage decoding

 logic [31:0] Default = 32'b0;

 assign RegWriteResult = (ResultSrc == 3'b000) ? ALUResult :
                         (ResultSrc == 3'b001) ? ReadData :
                         (ResultSrc == 3'b010) ? PCplus4 :
                         (ResultSrc == 3'b011) ? U_imm :
                         (ResultSrc == 3'b100) ? PCTarget :
                         (ResultSrc == 3'b101) ? Default : 32'b0; // Default case, can be adjusted as needed

//*********************************************************************************//
//*********************************************************************************//



 wire [4:0] shamt = ALUreg ? RD2[4:0] : C_INST[24:20]; // shift amount

 logic [7:0] ALUControl[3:0];

 
 
 always_comb begin

 case (ALUOp)
   2'b00: ALUControl[0] = {5'b10000, 3'b000}; // ADD - store and load addresses
   2'b01: ALUControl[0] = {5'b00000, funct3}; // Branch
   2'b10: ALUControl[0] = {5'b00000, funct3}; // funct3 must be 3 bits
   default: ALUControl[0] = {5'b00000, 3'b000};
 endcase
 ALUControl[1] = {1'b0, funct7};
 ALUControl[2] = {3'b000, shamt};
 ALUControl[3] = {1'b0, opCode};
 ALUc = ALUControl;

 end
                       
                       

//*********************************************************************************//
//*********************************************************************************//



 assign  A_Ram = ALUResult;




 //*********************************************************************************//
//*********************************************************************************//

 localparam FETCH_INSTR = 0; // first state
 localparam WAIT_INSTR = 1;
 localparam FETCH_REGS = 2; // second state
 localparam EXECUTE = 3; // third state
 localparam LOAD = 4;
 localparam WAIT_DATA = 5;
 localparam STORE = 6;




 reg [6:0] state = FETCH_INSTR; // startsd at fetching  instructions

 //assign RegWrite = (state == EXECUTE );

 assign RegWrite = (state == EXECUTE && !isBranch && !Store && !Load) || (state == WAIT_DATA);
//*********************************************************************************//
//*********************************************************************************//


  always_ff @(posedge clk) begin
     //if(!resetn) begin
     //PC <= 0;
     //C_INST <= 32'b0000000_00000_00000_000_00000_0000000; // NOP
     //end


     //else
     begin
        if (RegWrite && A3 != 0) begin // these signals are not set as they need they need an ALU into the module
        WD3 <= RegWriteResult;
        end

        case(state)

              FETCH_INSTR: begin
               // C_INST <= MEM[PC[31:2]]; // assign the instruction in which the program counter is currently pointing towards
                state <=  WAIT_INSTR; // go to the next state
              end

              WAIT_INSTR: begin
                C_INST <= MEM_dout;
                state <= FETCH_REGS;
              end

              FETCH_REGS: begin
                state <= EXECUTE; // jump to the next state
              end

              EXECUTE: 
              begin // this part will enable the writing back enable signal
                if(C_INST[6:0] != 7'b1110011) begin
                  PC <= PCNext; // increase the program counter (based on instruction type) ie go to the next instruction in RAM
                end
                  state <= Load  ? LOAD  : 
                          Store ? STORE : 
                          FETCH_INSTR; 
                end

                LOAD: begin
                  state <= WAIT_DATA;
                end

                WAIT_DATA: begin
                  state <= FETCH_INSTR;
                end

                STORE: begin
                  //WriteData <= RD2;
                  state <= FETCH_INSTR;
                end
 
            endcase

     end

   end

//*********************************************************************************//
//*********************************************************************************//


   assign tb_instruction = C_INST;
   assign MEM_addr = PC;

   assign rMEM_en_reg = (state == EXECUTE);
   assign eRegWrite = (state == FETCH_INSTR && !Store && !isBranch );

   assign rMEM_en = (state == FETCH_INSTR);
   assign MemRead = (state == LOAD);

   wire c010 = (ALUResult[31:24] == 8'b11000000 )? 1 : 0;
  // assign LEDS = isSYSTEM ? 31 : {PC[0],isALUreg,isALUimm,isStore,isLoad};
   
   assign MemWrite = (state == STORE);
   assign WriteData = RD2;

   assign states = state;
   
endmodule