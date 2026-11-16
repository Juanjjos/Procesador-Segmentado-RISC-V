module IM(
  input  logic [31:0] Address,
  output logic [31:0] Instruction
);

  logic [31:0] IMemory [0:4095];

  initial begin
    $readmemh("program.mem", IMemory);
  end

  assign Instruction = IMemory[Address[13:2]];

endmodule
