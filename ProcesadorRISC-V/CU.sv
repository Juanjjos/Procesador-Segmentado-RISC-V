module CU(
  input  logic [6:0] OpCode,
  input  logic [2:0] Funct3,
  input  logic [6:0] Funct7,
  output logic [2:0] ImmSrc,
  output logic       ALUASrc,
  output logic       ALUBSrc,
  output logic [3:0] ALUOp,
  output logic [4:0] BUOp,
  output logic       DMRd,
  output logic       DMWr,
  output logic [2:0] DMCtrl,
  output logic [1:0] RUDataWrSrc,
  output logic       RUWr
);

  always_comb begin
    case (OpCode)
      7'b0110011: begin // Tipo R
        ImmSrc = 3'b000;
        ALUASrc = 1'b0;
        ALUBSrc = 1'b0;
        ALUOp = {Funct7[5], Funct3};
        BUOp = {2'b00, Funct3};
        DMRd = 1'b0;
        DMWr = 1'b0;
        DMCtrl = Funct3;
        RUDataWrSrc = 2'b00;
        RUWr = 1'b1;
      end

      7'b0010011: begin // Tipo I
        ImmSrc = 3'b000;
        ALUASrc = 1'b0;
        ALUBSrc = 1'b1;
        // Desplazamientos (Funct3 = 101) importa Funct7[5], sino es 0
        ALUOp = (Funct3 == 3'b101) ? {Funct7[5], Funct3} : {1'b0, Funct3};
        BUOp = {2'b00, Funct3};
        DMRd = 1'b0;
        DMWr = 1'b0;
        DMCtrl = Funct3;
        RUDataWrSrc = 2'b00;
        RUWr = 1'b1;
      end

      7'b0000011: begin // Loads (Tipo I)
        ImmSrc = 3'b000;
        ALUASrc = 1'b0;
        ALUBSrc = 1'b1;
        ALUOp = 4'b0000; // (rs1 + offset)
        BUOp = {2'b00, Funct3};
        DMRd = 1'b1;
        DMWr = 1'b0;
        DMCtrl = Funct3;
        RUDataWrSrc = 2'b01;
        RUWr = 1'b1;
      end

      7'b0100011: begin // Stores (Tipo S)
        ImmSrc = 3'b001;
        ALUASrc = 1'b0;
        ALUBSrc = 1'b1;
        ALUOp = 4'b0000; // (rs1 + offset)
        BUOp = {2'b00, Funct3};
        DMRd = 1'b0;
        DMWr = 1'b1;
        DMCtrl = Funct3;
        RUDataWrSrc = 2'b00;
        RUWr = 1'b0;
      end

      7'b1100011: begin // Branches (Tipo B)
        ImmSrc = 3'b101;
        ALUASrc = 1'b1; // PC
        ALUBSrc = 1'b1; // Imm
        ALUOp = 4'b0000; 
        BUOp = {2'b01, Funct3};
        DMRd = 1'b0;
        DMWr = 1'b0;
        DMCtrl = Funct3;
        RUDataWrSrc = 2'b00;
        RUWr = 1'b0;
      end

      7'b0110111: begin // lui (Tipo U)
        ImmSrc = 3'b010;
        ALUASrc = 1'b0; // x0 
        ALUBSrc = 1'b1; // Imm Extendido
        ALUOp = 4'b0000; // 0 + Imm
        BUOp = {2'b00, Funct3};
        DMRd = 1'b0;
        DMWr = 1'b0;
        DMCtrl = Funct3;
        RUDataWrSrc = 2'b00;
        RUWr = 1'b1;
      end

      7'b0010111: begin // auipc (Tipo U)
        ImmSrc = 3'b010;
        ALUASrc = 1'b1; // PC
        ALUBSrc = 1'b1; // Imm Extendido
        ALUOp = 4'b0000; // PC + Imm
        BUOp = {2'b00, Funct3};
        DMRd = 1'b0;
        DMWr = 1'b0;
        DMCtrl = Funct3;
        RUDataWrSrc = 2'b00;
        RUWr = 1'b1;
      end

      7'b1101111: begin // jal (Tipo J)
        ImmSrc = 3'b110;
        ALUASrc = 1'b1; // PC
        ALUBSrc = 1'b1; // Imm Extendido
        ALUOp = 4'b0000; // PC + Imm
        BUOp = 5'b10000;
        DMRd = 1'b0;
        DMWr = 1'b0;
        DMCtrl = 3'b000;
        RUDataWrSrc = 2'b10; 
        RUWr = 1'b1;
      end

      7'b1100111: begin // jalr (Tipo I)
        ImmSrc = 3'b000; 
        ALUASrc = 1'b0; // rs1
        ALUBSrc = 1'b1; // Imm
        ALUOp = 4'b0000; // rs1 + Imm
        BUOp = 5'b10000;
        DMRd = 1'b0;
        DMWr = 1'b0;
        DMCtrl = 3'b000;
        RUDataWrSrc = 2'b10;
        RUWr = 1'b1;
      end
    endcase
  end
endmodule
