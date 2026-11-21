module FU (
    input  logic [4:0] rs1_EX,
    input  logic [4:0] rs2_EX,
    input  logic [4:0] rd_MEM,
    input  logic [4:0] rd_WB,
    input  logic       RUWr_MEM,
    input  logic       RUWr_WB,
    output logic [1:0] ForwardA,
    output logic [1:0] ForwardB
);

    // Selector encoding used by RISCV.sv: 00 = register,
    // 10 = EX/MEM forwarding, 11 = MEM/WB forwarding.
    always_comb begin
        // Operando A (rs1)
        if (RUWr_MEM && (rd_MEM != 5'd0) && (rd_MEM == rs1_EX))
            ForwardA = 2'b10;
        else if (RUWr_WB && (rd_WB != 5'd0) && (rd_WB == rs1_EX))
            ForwardA = 2'b11;
        else
            ForwardA = 2'b00;

        // Operando B (rs2)
        if (RUWr_MEM && (rd_MEM != 5'd0) && (rd_MEM == rs2_EX))
            ForwardB = 2'b10;
        else if (RUWr_WB && (rd_WB != 5'd0) && (rd_WB == rs2_EX))
            ForwardB = 2'b11;
        else
            ForwardB = 2'b00;
    end

endmodule