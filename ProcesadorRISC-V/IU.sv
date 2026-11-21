// Imms corresponds to instruction bits Inst[31:7].
module IU (
    input  logic [24:0] Imms,
    input  logic [2:0]  ImmSrc,
    output logic [31:0] ImmExt
);

    always_comb begin
        case (ImmSrc)
            3'b000: ImmExt = {{20{Imms[24]}}, Imms[24:13]};
            3'b001: ImmExt = {{20{Imms[24]}}, Imms[24:18], Imms[4:0]};
            3'b101: ImmExt = {{19{Imms[24]}}, Imms[24], Imms[0],
                              Imms[23:18], Imms[4:1], 1'b0};
            3'b010: ImmExt = {Imms[24:5], 12'b0};
            3'b110: ImmExt = {{12{Imms[24]}}, Imms[12:5], Imms[13],
                              Imms[23:14], 1'b0};
            default: ImmExt = 32'b0;
        endcase
    end

endmodule
