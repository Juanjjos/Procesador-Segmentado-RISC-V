module RISCV #(
    parameter IM_INIT_FILE = "program.mem"
) (
    input  logic       clk,
    input  logic       rst,
    input  logic [9:0] SW,
    input  logic [3:0] KEY,
    output logic [9:0] LEDR,
    output logic [6:0] HEX0,
    output logic [6:0] HEX1,
    output logic [6:0] HEX2,
    output logic [6:0] HEX3,
    output logic [6:0] HEX4,
    output logic [6:0] HEX5
);

    localparam logic [31:0] NOP      = 32'h00000013;
    localparam logic [6:0]  OP_JALR  = 7'b1100111;

    // -----------------------------------------------------------------
    // IF: Program counter and instruction memory
    // -----------------------------------------------------------------
    logic [31:0] PC;
    logic [31:0] PCInc_if;
    logic [31:0] Instruction_if;
    logic [31:0] NextPC;

    assign PCInc_if = PC + 32'd4;

    IM #(
        .INIT_FILE(IM_INIT_FILE)
    ) IMInst (
        .Address(PC),
        .Instruction(Instruction_if)
    );

    // IF/ID pipeline register
    logic [31:0] Inst_de;
    logic [31:0] PC_de;
    logic [31:0] PCInc_de;

    // -----------------------------------------------------------------
    // ID: Control decoding
    // -----------------------------------------------------------------
    logic [2:0] ImmSrc_de;
    logic       ALUASrc_de;
    logic       ALUBSrc_de;
    logic [3:0] ALUOp_de;
    logic [4:0] BUOp_de;
    logic       DMRd_de;
    logic       DMWr_de;
    logic [2:0] DMCtrl_de;
    logic [1:0] RUDataWrSrc_de;
    logic       RUWr_de;

    logic [31:0] RU_rs1_de;
    logic [31:0] RU_rs2_de;
    logic [31:0] RUrs1_de;
    logic [31:0] RUrs2_de;
    logic [31:0] RUDataWr_wb;
    logic       RUWr_wb;
    logic [4:0] rd_wb;

    logic [31:0] ALURes_me;
    logic       RUWr_me;
    logic [4:0] rd_me;

    logic [31:0] ImmExt_de;

    CU CUInst (
        .OpCode(Inst_de[6:0]),
        .Funct3(Inst_de[14:12]),
        .Funct7(Inst_de[31:25]),
        .ImmSrc(ImmSrc_de),
        .ALUASrc(ALUASrc_de),
        .ALUBSrc(ALUBSrc_de),
        .ALUOp(ALUOp_de),
        .BUOp(BUOp_de),
        .DMRd(DMRd_de),
        .DMWr(DMWr_de),
        .DMCtrl(DMCtrl_de),
        .RUDataWrSrc(RUDataWrSrc_de),
        .RUWr(RUWr_de)
    );

    RU RUInst (
        .clk(clk),
        .rst(rst),
        .rs1(Inst_de[19:15]),
        .rs2(Inst_de[24:20]),
        .rd(rd_wb),
        .DataWr(RUDataWr_wb),
        .RUWr(RUWr_wb),
        .RU_rs1(RU_rs1_de),
        .RU_rs2(RU_rs2_de)
    );

    IU IUInst (
        .Imms(Inst_de[31:7]),
        .ImmSrc(ImmSrc_de),
        .ImmExt(ImmExt_de)
    );

    // Write-first bypass for an instruction being decoded while an older
    assign RUrs1_de = (RUWr_wb && (rd_wb != 5'd0) &&
                       (rd_wb == Inst_de[19:15]))
                      ? RUDataWr_wb : RU_rs1_de;
    assign RUrs2_de = (RUWr_wb && (rd_wb != 5'd0) &&
                       (rd_wb == Inst_de[24:20]))
                      ? RUDataWr_wb : RU_rs2_de;


    logic [4:0] rs1_ID_HDU;
    logic [4:0] rs2_ID_HDU;

    always_comb begin
        rs1_ID_HDU = 5'd0;
        rs2_ID_HDU = 5'd0;

        case (Inst_de[6:0])
            7'b0110011: begin // R-type: rs1 and rs2
                rs1_ID_HDU = Inst_de[19:15];
                rs2_ID_HDU = Inst_de[24:20];
            end

            7'b0010011, // Immediate ALU operations
            7'b0000011, // Loads
            7'b1100111: // JALR
                rs1_ID_HDU = Inst_de[19:15];

            7'b0100011, // Stores
            7'b1100011: begin // Conditional branches
                rs1_ID_HDU = Inst_de[19:15];
                rs2_ID_HDU = Inst_de[24:20];
            end

            default: begin // LUI, AUIPC, JAL and instructions without sources
                rs1_ID_HDU = 5'd0;
                rs2_ID_HDU = 5'd0;
            end
        endcase
    end

    // -----------------------------------------------------------------
    // ID/EX pipeline register.
    // -----------------------------------------------------------------
    logic       ALUASrc_ex;
    logic       ALUBSrc_ex;
    logic [3:0] ALUOp_ex;
    logic [4:0] BUOp_ex;
    logic       DMRd_ex;
    logic       DMWr_ex;
    logic [2:0] DMCtrl_ex;
    logic [1:0] RUDataWrSrc_ex;
    logic       RUWr_ex;
    logic [31:0] ImmExt_ex;
    logic [31:0] PC_ex;
    logic [31:0] PCInc_ex;
    logic [31:0] RUrs1_ex;
    logic [31:0] RUrs2_ex;
    logic [4:0] rs1_ex;
    logic [4:0] rs2_ex;
    logic [4:0] rd_ex;
    logic [6:0] OpCode_ex;

    // -----------------------------------------------------------------
    // EX: Hazard detection, branch decision, forwarding and ALU.
    // -----------------------------------------------------------------
    logic StallPC;
    logic StallIF_ID;
    logic FlushIF_ID;
    logic FlushID_EX;
    logic NextPCSrc_ex;

    HDU HDUInst (
        .rs1_ID(rs1_ID_HDU),
        .rs2_ID(rs2_ID_HDU),
        .rd_EX(rd_ex),
        .MemRead_EX(DMRd_ex),
        .NextPCSrc(NextPCSrc_ex),
        .StallPC(StallPC),
        .StallIF_ID(StallIF_ID),
        .FlushIF_ID(FlushIF_ID),
        .FlushID_EX(FlushID_EX)
    );

    logic [1:0] FUASrc;
    logic [1:0] FUBSrc;
    logic [31:0] FUA;
    logic [31:0] FUB;
    logic [31:0] ALUA;
    logic [31:0] ALUB;
    logic [31:0] ALURes_ex;

    BU BUInst (
        .RU_rs1(FUA),
        .RU_rs2(FUB),
        .BrOp(BUOp_ex),
        .NextPCSrc(NextPCSrc_ex)
    );

    // Forwarding multiplexers. FU selector values:
    // 00 = register value, 10 = EX/MEM value, 11 = MEM/WB value.
    assign FUA = FUASrc[1] ? (FUASrc[0] ? RUDataWr_wb : ALURes_me) : RUrs1_ex;
    assign FUB = FUBSrc[1] ? (FUBSrc[0] ? RUDataWr_wb : ALURes_me) : RUrs2_ex;

    // CU polarity is preserved in CU.sv. The EX-stage select signals were
    // inverted when captured so these expressions follow the requested form.
    assign ALUA = ALUASrc_ex ? FUA : PC_ex;
    assign ALUB = ALUBSrc_ex ? FUB : ImmExt_ex;

    ALU ALUInst (
        .A(ALUA),
        .B(ALUB),
        .ALUOp(ALUOp_ex),
        .ALURes(ALURes_ex)
    );

    // -----------------------------------------------------------------
    // EX/MEM pipeline register.
    // -----------------------------------------------------------------
    logic [31:0] PCInc_me;
    logic [31:0] StoreData_me;
    logic       DMWr_me;
    logic [2:0] DMCtrl_me;
    logic [1:0] RUDataWrSrc_me;
    logic [31:0] ALUResult_me_next;

    assign ALUResult_me_next = (RUDataWrSrc_ex == 2'b10)
                               ? PCInc_ex : ALURes_ex;

    // -----------------------------------------------------------------
    // FU: resolve RAW data dependencies from EX/MEM and MEM/WB.
    // -----------------------------------------------------------------
    FU FUInst (
        .rs1_EX(rs1_ex),
        .rs2_EX(rs2_ex),
        .rd_MEM(rd_me),
        .rd_WB(rd_wb),
        .RUWr_MEM(RUWr_me),
        .RUWr_WB(RUWr_wb),
        .ForwardA(FUASrc),
        .ForwardB(FUBSrc)
    );

    // -----------------------------------------------------------------
    // MEM: data memory and memory-mapped
    // -----------------------------------------------------------------
    logic [31:0] DataRd_me;

    DMIO DMIOInst (
        .clk(clk),
        .rst(rst),
        .Address(ALURes_me),
        .DataWr(StoreData_me),
        .DMWr(DMWr_me),
        .DMCtrl(DMCtrl_me),
        .SW(SW),
        .KEY(KEY),
        .DataRd(DataRd_me),
        .LEDR(LEDR),
        .HEX0(HEX0),
        .HEX1(HEX1),
        .HEX2(HEX2),
        .HEX3(HEX3),
        .HEX4(HEX4),
        .HEX5(HEX5)
    );

    // -----------------------------------------------------------------
    // MEM/WB pipeline register and final write-back multiplexer
    // -----------------------------------------------------------------
    logic [31:0] ALURes_wb;
    logic [31:0] DataRd_wb;
    logic [31:0] PCInc_wb;
    logic [1:0] RUDataWrSrc_wb;
    assign RUDataWr_wb = RUDataWrSrc_wb[1] ? PCInc_wb :
                         (RUDataWrSrc_wb[0] ? DataRd_wb : ALURes_wb);

    // -----------------------------------------------------------------
    // Pipeline registers and program counter update
    // -----------------------------------------------------------------
    assign NextPC = NextPCSrc_ex
                    ? ((OpCode_ex == OP_JALR)
                       ? (ALURes_ex & 32'hFFFFFFFE) : ALURes_ex)
                    : PCInc_if;

    always_ff @(posedge clk) begin
        if (rst) begin
            PC <= 32'd0;
        end else if (!StallPC) begin
            PC <= NextPC;
        end
    end

    // IF/ID: flush after a taken branch/jump, hold during a load-use stall.
    always_ff @(posedge clk) begin
        if (rst) begin
            Inst_de  <= NOP;
            PC_de    <= 32'd0;
            PCInc_de <= 32'd0;
        end else if (FlushIF_ID) begin
            Inst_de  <= NOP;
            PC_de    <= 32'd0;
            PCInc_de <= 32'd0;
        end else if (!StallIF_ID) begin
            Inst_de  <= Instruction_if;
            PC_de    <= PC;
            PCInc_de <= PCInc_if;
        end
    end

    // ID/EX: insert a bubble on a load-use hazard or a taken control transfer.
    always_ff @(posedge clk) begin
        if (rst || FlushID_EX) begin
            ALUASrc_ex      <= 1'b0;
            ALUBSrc_ex      <= 1'b0;
            ALUOp_ex        <= 4'b0000;
            BUOp_ex         <= 5'b00000;
            DMRd_ex         <= 1'b0;
            DMWr_ex         <= 1'b0;
            DMCtrl_ex       <= 3'b010;
            RUDataWrSrc_ex  <= 2'b00;
            RUWr_ex         <= 1'b0;
            ImmExt_ex       <= 32'd0;
            PC_ex           <= 32'd0;
            PCInc_ex        <= 32'd0;
            RUrs1_ex        <= 32'd0;
            RUrs2_ex        <= 32'd0;
            rs1_ex          <= 5'd0;
            rs2_ex          <= 5'd0;
            rd_ex           <= 5'd0;
            OpCode_ex       <= 7'd0;
        end else begin
            // Invert CU source-control polarity for the specified mux form.
            ALUASrc_ex      <= ~ALUASrc_de;
            ALUBSrc_ex      <= ~ALUBSrc_de;
            ALUOp_ex        <= ALUOp_de;
            BUOp_ex         <= BUOp_de;
            DMRd_ex         <= DMRd_de;
            DMWr_ex         <= DMWr_de;
            DMCtrl_ex       <= DMCtrl_de;
            RUDataWrSrc_ex  <= RUDataWrSrc_de;
            RUWr_ex         <= RUWr_de;
            ImmExt_ex       <= ImmExt_de;
            PC_ex           <= PC_de;
            PCInc_ex        <= PCInc_de;
            RUrs1_ex        <= RUrs1_de;
            RUrs2_ex        <= RUrs2_de;
            rs1_ex          <= Inst_de[19:15];
            rs2_ex          <= Inst_de[24:20];
            rd_ex           <= Inst_de[11:7];
            OpCode_ex       <= Inst_de[6:0];
        end
    end

    // EX/MEM: carry results and memory/register-write controls forward.
    always_ff @(posedge clk) begin
        if (rst) begin
            ALURes_me       <= 32'd0;
            PCInc_me        <= 32'd0;
            StoreData_me    <= 32'd0;
            DMWr_me         <= 1'b0;
            DMCtrl_me       <= 3'b010;
            RUDataWrSrc_me  <= 2'b00;
            RUWr_me         <= 1'b0;
            rd_me           <= 5'd0;
        end else begin
            ALURes_me       <= ALUResult_me_next;
            PCInc_me        <= PCInc_ex;
            StoreData_me    <= FUB;
            DMWr_me         <= DMWr_ex;
            DMCtrl_me       <= DMCtrl_ex;
            RUDataWrSrc_me  <= RUDataWrSrc_ex;
            RUWr_me         <= RUWr_ex;
            rd_me           <= rd_ex;
        end
    end

    // MEM/WB: latch memory output and the remaining write-back information.
    always_ff @(posedge clk) begin
        if (rst) begin
            ALURes_wb       <= 32'd0;
            DataRd_wb       <= 32'd0;
            PCInc_wb        <= 32'd0;
            RUDataWrSrc_wb  <= 2'b00;
            RUWr_wb         <= 1'b0;
            rd_wb           <= 5'd0;
        end else begin
            ALURes_wb       <= ALURes_me;
            DataRd_wb       <= DataRd_me;
            PCInc_wb        <= PCInc_me;
            RUDataWrSrc_wb  <= RUDataWrSrc_me;
            RUWr_wb         <= RUWr_me;
            rd_wb           <= rd_me;
        end
    end

endmodule
