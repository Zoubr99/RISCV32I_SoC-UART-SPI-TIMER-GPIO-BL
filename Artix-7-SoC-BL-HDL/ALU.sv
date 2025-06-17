//  Module: ALU
//
module ALU
    (
        input logic [7:0] ALUc [3:0],
        input logic [31:0] aluSrcA,
        input logic [31:0] aluSrcB,
        output logic [31:0] ALUResult,
        output logic Zero
    );



        always_comb begin
		  
		  ALUResult = 32'b0;
		  Zero = 1'b0;
		  
        case(ALUc[0][2:0]) // func3

        3'b000:begin
        ALUResult =  (ALUc[0][7])? (aluSrcA + aluSrcB):
                     (ALUc[1][5] & ALUc[3][5]) ?  (aluSrcA - aluSrcB) : (aluSrcA + aluSrcB);
        Zero = (aluSrcA == aluSrcB); // if source reg 1  == source reg 2 set zero to 1, brnach to the (PC + immediate offset value), if (B-Type && Zero) were true.
        end

        3'b001:begin 
        ALUResult = aluSrcA << (ALUc[2][4:0]); // shifts the aluSrcA (logically) to the left by the shifting ammount
        Zero = (aluSrcA != aluSrcB); // if source reg 1  != source reg 2 set zero to 1, brnach to the (PC + immediate offset value), if (B-Type && Zero) were true.
        end

        3'b010: ALUResult = ($signed(aluSrcA) < $signed(aluSrcB)); // signed comparison
        
        3'b011: ALUResult = (aluSrcA < aluSrcB); // unsigned comparison

        3'b100:begin 
        ALUResult = (aluSrcA ^ aluSrcB); // XOR instruction
        Zero = ($signed(aluSrcA) < $signed(aluSrcB)); // if signed source reg 1  < signed source reg 2 set Zero to 1, brnach to the (PC + immediate offset value), if (B-Type && Zero) were true.
        end

        3'b101:begin 
        ALUResult = (ALUc[1][5])? ($signed(aluSrcA) >>> (ALUc[2][4:0])) : ($signed(aluSrcA) >> (ALUc[2][4:0])); // for logical or arithmetic right shift, by testing bit 5 of funct7 we determine which function to use, 1 for arithmetic shift (with sign expansion) and 0 for logical shift.
        Zero = ($signed(aluSrcA) >= $signed(aluSrcB)); // if signed source reg 1  >= signed source reg 2 set Zero to 1, brnach to the (PC + immediate offset value), if (B-Type && Zero) were true.
        end

        3'b110:begin
        ALUResult = (aluSrcA | aluSrcB); // OR instruction
        Zero = (aluSrcA < aluSrcB); // if source reg 1  < source reg 2 set Zero to 1, brnach to the (PC + immediate offset value), if (B-Type && Zero) were true.
        end

        3'b111:begin
        ALUResult = (aluSrcA & aluSrcB);	// AND instruction
        Zero = (aluSrcA >= aluSrcB); // if  source reg 1  >  source reg 2 set Zero to 1, brnach to the (PC + immediate offset value), if (B-Type && Zero) were true.
        end

        default: begin

        end

        endcase
        end
    
endmodule
