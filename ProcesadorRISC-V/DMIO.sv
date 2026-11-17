module DMIO (
    input  logic        clk,
    input  logic        rst,
    input  logic [31:0] Address,
    input  logic [31:0] DataWr,
    input  logic        DMWr,
    input  logic [2:0]  DMCtrl,
    // Entradas fisicas
    input  logic [9:0]  SW,
    input  logic [3:0]  KEY,
    // Salida de datos hacia el procesador
    output logic [31:0] DataRd,
    // Salidas fisicas
    output logic [9:0]  LEDR,
    output logic [6:0]  HEX0,
    output logic [6:0]  HEX1,
    output logic [6:0]  HEX2,
    output logic [6:0]  HEX3,
    output logic [6:0]  HEX4,
    output logic [6:0]  HEX5
);

    // Almacenamiento 
    logic [31:0] ram [0:1023];          // 4 KB
    logic [9:0]  led_reg;
    logic [31:0] hex03_reg;
    logic [31:0] hex45_reg;

    initial begin
        for (int i = 0; i < 1024; i++) ram[i] = 32'd0;
    end

    //  Decodificacion de direcciones 
    logic        ram_sel, io_sel;
    logic [9:0]  ram_idx;
    logic [5:0]  io_idx;
    logic [1:0]  offset;

    assign ram_sel = (Address[31:12] == 20'h00000);
    assign io_sel  = (Address[31:8]  == 24'h100000);
    assign ram_idx = Address[11:2];
    assign io_idx  = Address[7:2];
    assign offset  = Address[1:0];

    //  Lectura de la palabra completa 
    logic [31:0] rd_word;

    always_comb begin
        rd_word = 32'd0;
        if (ram_sel) begin
            rd_word = ram[ram_idx];
        end else if (io_sel) begin
            case (io_idx)
                6'd0:    rd_word = {22'd0, led_reg};
                6'd1:    rd_word = hex03_reg;
                6'd2:    rd_word = hex45_reg;
                6'd3:    rd_word = {22'd0, SW};
                6'd4:    rd_word = {28'd0, ~KEY};   // KEY es activo en bajo
                default: rd_word = 32'd0;
            endcase
        end
    end

    //  Formateo de lectura (lb, lh, lw, lbu, lhu) 
    logic [7:0]  rd_byte;
    logic [15:0] rd_half;

    always_comb begin
        case (offset)
            2'd0:    rd_byte = rd_word[7:0];
            2'd1:    rd_byte = rd_word[15:8];
            2'd2:    rd_byte = rd_word[23:16];
            default: rd_byte = rd_word[31:24];
        endcase
        rd_half = offset[1] ? rd_word[31:16] : rd_word[15:0];
    end

    always_comb begin
        case (DMCtrl)
            3'b000:  DataRd = {{24{rd_byte[7]}},  rd_byte};   // lb
            3'b001:  DataRd = {{16{rd_half[15]}}, rd_half};   // lh
            3'b010:  DataRd = rd_word;                        // lw
            3'b100:  DataRd = {24'd0, rd_byte};               // lbu
            3'b101:  DataRd = {16'd0, rd_half};               // lhu
            default: DataRd = rd_word;
        endcase
    end

    //  Formateo de escritura (sb, sh, sw) 
    // Lectura-modificacion-escritura sobre la palabra actual
    logic [31:0] wr_word;

    always_comb begin
        wr_word = rd_word;
        case (DMCtrl[1:0])
            2'b00: begin                                       // sb
                case (offset)
                    2'd0:    wr_word[7:0]   = DataWr[7:0];
                    2'd1:    wr_word[15:8]  = DataWr[7:0];
                    2'd2:    wr_word[23:16] = DataWr[7:0];
                    default: wr_word[31:24] = DataWr[7:0];
                endcase
            end
            2'b01: begin                                       // sh
                if (offset[1]) wr_word[31:16] = DataWr[15:0];
                else           wr_word[15:0]  = DataWr[15:0];
            end
            default: wr_word = DataWr;                         // sw
        endcase
    end

    //  Escritura sincrona 
    always_ff @(posedge clk) begin
        if (rst) begin
            led_reg   <= 10'd0;
            hex03_reg <= 32'h7F7F7F7F;     // displays apagados (activo en bajo)
            hex45_reg <= 32'h00007F7F;
        end else if (DMWr) begin
            if (ram_sel) begin
                ram[ram_idx] <= wr_word;
            end else if (io_sel) begin
                case (io_idx)
                    6'd0:    led_reg   <= wr_word[9:0];
                    6'd1:    hex03_reg <= wr_word;
                    6'd2:    hex45_reg <= wr_word;
                    default: ;                                 // SW/KEY son solo lectura
                endcase
            end
        end
    end

    //  Salidas fisicas 
    assign LEDR = led_reg;
    assign HEX0 = hex03_reg[6:0];
    assign HEX1 = hex03_reg[14:8];
    assign HEX2 = hex03_reg[22:16];
    assign HEX3 = hex03_reg[30:24];
    assign HEX4 = hex45_reg[6:0];
    assign HEX5 = hex45_reg[14:8];

endmodule