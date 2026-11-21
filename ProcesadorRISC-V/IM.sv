module IM #(
    parameter INIT_FILE = "program.mem"
) (
    input  logic [31:0] Address,
    output logic [31:0] Instruction
);

    logic [31:0] IMemory [0:4095];

    initial begin
        for (int i = 0; i < 4096; i++) begin
            IMemory[i] = 32'h00000013;
        end
        $readmemh(INIT_FILE, IMemory);
    end

    // 16 KiB of byte-addressable instruction space.
    always_comb begin
        Instruction = IMemory[Address[13:2]];
    end

endmodule
