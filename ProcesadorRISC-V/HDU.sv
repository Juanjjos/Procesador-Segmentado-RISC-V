module HDU (
    input  logic [4:0] rs1_ID,
    input  logic [4:0] rs2_ID,
    input  logic [4:0] rd_EX,
    input  logic       MemRead_EX,    // 1 si la instruccion en EX es un load
    input  logic       NextPCSrc,     // salto tomado (desde BU)
    output logic       StallPC,       // congela el PC
    output logic       StallIF_ID,    // congela el registro IF/ID
    output logic       FlushIF_ID,    // inserta nop en IF/ID
    output logic       FlushID_EX     // inserta nop (burbuja) en ID/EX
);

    logic load_use;

    always_comb begin
        load_use = MemRead_EX && (rd_EX != 5'd0) &&
                   ((rd_EX == rs1_ID) || (rd_EX == rs2_ID));

        // Valores por defecto
        StallPC    = 1'b0;
        StallIF_ID = 1'b0;
        FlushIF_ID = 1'b0;
        FlushID_EX = 1'b0;

        if (NextPCSrc) begin
            FlushIF_ID = 1'b1;
            FlushID_EX = 1'b1;
        end else if (load_use) begin
            StallPC    = 1'b1;
            StallIF_ID = 1'b1;
            FlushID_EX = 1'b1;
        end
    end

endmodule