module BU (
    input  logic [31:0] RU_rs1,
    input  logic [31:0] RU_rs2,
    input  logic [4:0]  BrOp,
    output logic        NextPCSrc
);

    always_comb begin
        if (BrOp[4]) begin
            NextPCSrc = 1'b1;                                          // jal, jalr
        end else begin
            case (BrOp)
                5'b01000: NextPCSrc = (RU_rs1 == RU_rs2);                          // beq
                5'b01001: NextPCSrc = (RU_rs1 != RU_rs2);                          // bne
                5'b01100: NextPCSrc = ($signed(RU_rs1) <  $signed(RU_rs2));        // blt
                5'b01101: NextPCSrc = ($signed(RU_rs1) >= $signed(RU_rs2));        // bge
                5'b01110: NextPCSrc = (RU_rs1 <  RU_rs2);                          // bltu
                5'b01111: NextPCSrc = (RU_rs1 >= RU_rs2);                          // bgeu
                default:  NextPCSrc = 1'b0;                                        // 00XXX
            endcase
        end
    end

endmodule