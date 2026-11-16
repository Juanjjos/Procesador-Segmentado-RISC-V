module RU (
  input  logic clk,
  input  logic rst,
  input  logic [4:0]rs1,
  input  logic [4:0]rs2,
  input  logic [4:0]rd,
  input  logic [31:0]DataWr,
  input  logic RUWr,
  output logic [31:0]RU_rs1,
  output logic [31:0]RU_rs2
);

  // Banco de registros
  logic [31:0] registers [0:31];

  assign RU_rs1 = (rs1 == 5'd0) ? 32'd0 : registers[rs1];
  assign RU_rs2 = (rs2 == 5'd0) ? 32'd0 : registers[rs2];

  always_ff @(posedge clk) begin
    if (rst) begin
      
      // Inicialización de los registros
      for (int i = 0; i < 32; i++) begin
        registers[i] <= 32'd0;
      end
      
    end else begin
      
      // Validación de escritura
      if (RUWr && (rd != 5'd0)) begin
        registers[rd] <= DataWr;
      end
      
    end
  end

endmodule
