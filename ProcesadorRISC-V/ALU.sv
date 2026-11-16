module ALU (
    input  logic [31:0] A,
    input  logic [31:0] B,
    input  logic [3:0]  ALUOp,
    output logic [31:0] ALURes
);

    always_comb begin
        case (ALUOp)
            4'b0000: ALURes = A + B;                                   // add / addi
            4'b1000: ALURes = A - B;                                   // sub
            4'b0001: ALURes = A << B[4:0];                             // sll
            4'b0010: ALURes = ($signed(A) < $signed(B)) ? 32'd1 : 32'd0; // slt
            4'b0011: ALURes = (A < B) ? 32'd1 : 32'd0;                 // sltu
            4'b0100: ALURes = A ^ B;                                   // xor
            4'b0101: ALURes = A >> B[4:0];                             // srl
            4'b1101: ALURes = $signed(A) >>> B[4:0];                   // sra
            4'b0110: ALURes = A | B;                                   // or
            4'b0111: ALURes = A & B;                                   // and
            default: ALURes = 32'd0;
        endcase
    end

endmodule