/*
RV32I 5-stage pipelined CPU supporting R/I-type, load/store,
branch (BEQ, BNE, BLT, BGE), and jump (JAL) instructions.
Includes a control unit for decoding and immediate generation (I/S/B/J formats).

Implements hazard handling with:
- Load-use stall detection
- Forwarding (EX/MEM and MEM/WB to EX)
- Write-through (WB -> ID) bypass
Control hazards handled using a 2-bit branch predictor (16-entry table) with
misprediction recovery via pipeline flush and PC correction.

Branch condition is evaluated in EX stage using forwarded values.
Supported branch types: BEQ (funct3=000), BNE (001), BLT (100), BGE (101).
*/

module cpu (
    input         clk,
    input         rst,
    output [31:0] instr_addr,
    input  [31:0] instr_in,
    output [31:0] data_addr,
    output [31:0] data_wd,
    input  [31:0] data_rd,
    output        data_we,
    output        mem_req
);
    reg  [31:0] pc;
    wire [31:0] pc_plus4;
    assign pc_plus4   = pc + 32'd4;
    assign instr_addr = pc;

    // ---- IF/ID pipeline registers ----
    reg [31:0] if_id_pc;
    reg [31:0] if_id_instr;
    reg        if_id_valid;

    // ---- Decode fields ----
    wire [6:0] opcode;
    wire [4:0] rs1_dec, rs2_dec, rd_dec;
    wire [2:0] funct3;
    wire [6:0] funct7;
    assign opcode  = if_id_instr[6:0];
    assign rs1_dec = if_id_instr[19:15];
    assign rs2_dec = if_id_instr[24:20];
    assign rd_dec  = if_id_instr[11:7];
    assign funct3  = if_id_instr[14:12];
    assign funct7  = if_id_instr[31:25];

    // ---- Immediate generation ----
    wire [31:0] imm_i, imm_s, imm_b, imm_j;
    assign imm_i = {{20{if_id_instr[31]}}, if_id_instr[31:20]};
    assign imm_s = {{20{if_id_instr[31]}}, if_id_instr[31:25], if_id_instr[11:7]};
    assign imm_b = {{20{if_id_instr[31]}}, if_id_instr[7], if_id_instr[30:25], if_id_instr[11:8], 1'b0};
    assign imm_j = {{12{if_id_instr[31]}}, if_id_instr[19:12], if_id_instr[20], if_id_instr[30:21], 1'b0};

    // ---- Control unit ----
    wire       cu_reg_write, cu_mem_read, cu_mem_write;
    wire       cu_alu_src, cu_branch, cu_jump;
    wire [1:0] cu_imm_src;
    wire [3:0] cu_alu_op;
    wire [2:0] cu_branch_type;

    control_unit cu (
        .opcode     (opcode),
        .funct3     (funct3),
        .funct7     (funct7),
        .reg_write  (cu_reg_write),
        .mem_read   (cu_mem_read),
        .mem_write  (cu_mem_write),
        .alu_src    (cu_alu_src),
        .imm_src    (cu_imm_src),
        .branch     (cu_branch),
        .jump       (cu_jump),
        .alu_op     (cu_alu_op),
        .branch_type(cu_branch_type)
    );

    // ---- Immediate mux ----
    reg [31:0] id_imm;
    always @(*) begin
        case (cu_imm_src)
            2'b00: id_imm = imm_i;
            2'b01: id_imm = imm_s;
            2'b10: id_imm = imm_b;
            2'b11: id_imm = imm_j;
            default: id_imm = 32'd0;
        endcase
    end

    // ---- ID/EX pipeline registers ----
    reg [31:0] id_ex_pc;
    reg [31:0] id_ex_rs1_val, id_ex_rs2_val;
    reg [31:0] id_ex_imm;
    reg        id_ex_reg_write, id_ex_mem_read, id_ex_mem_write;
    reg        id_ex_alu_src, id_ex_branch, id_ex_jump;
    reg [3:0]  id_ex_alu_op;
    reg [4:0]  id_ex_rd;
    reg [4:0]  id_ex_rs1, id_ex_rs2;
    reg        id_ex_valid;
    reg        id_ex_predict_taken;
    reg [2:0]  id_ex_branch_type;

    // ---- Load-use hazard stall ----
    wire stall;
    assign stall = id_ex_mem_read &&
                   ((id_ex_rd == rs1_dec) || (id_ex_rd == rs2_dec)) &&
                   (id_ex_rd != 5'd0) && if_id_valid;

    // ---- EX/MEM pipeline registers ----
    reg [31:0] ex_mem_pc;
    reg [31:0] ex_mem_alu_result;
    reg [31:0] ex_mem_write_data;
    reg        ex_mem_reg_write, ex_mem_mem_read, ex_mem_mem_write;
    reg [4:0]  ex_mem_rd;
    reg        ex_mem_branch;
    reg        ex_mem_branch_cond;
    reg [31:0] ex_mem_branch_target;
    reg        ex_mem_predict_taken;
    reg        ex_mem_valid;
    reg        ex_mem_jump;
    reg [31:0] ex_mem_pc_plus4;

    // ---- Branch resolution ----
    wire actual_taken;
    wire mispredicted;
    wire [31:0] correct_pc;
    assign actual_taken = ex_mem_branch & ex_mem_branch_cond & ex_mem_valid;
    assign mispredicted = ex_mem_branch & ex_mem_valid &
                          (actual_taken != ex_mem_predict_taken);
    assign correct_pc   = actual_taken ? ex_mem_branch_target
                                       : (ex_mem_pc + 32'd4);

    // ---- MEM/WB pipeline registers ----
    reg [31:0] mem_wb_alu_result;
    reg [31:0] mem_wb_read_data;
    reg        mem_wb_reg_write;
    reg        mem_wb_mem_read;
    reg [4:0]  mem_wb_rd;
    reg        mem_wb_jump;
    reg [31:0] mem_wb_pc_plus4;

    // ---- Writeback data mux ----
    reg [31:0] wb_data;
    always @(*) begin
        if (mem_wb_jump)
            wb_data = mem_wb_pc_plus4;
        else if (mem_wb_mem_read)
            wb_data = mem_wb_read_data;
        else
            wb_data = mem_wb_alu_result;
    end

    // ---- Branch predictor ----
    wire predict_taken;
    predictor pred (
        .clk          (clk),
        .rst          (rst),
        .pc_in        (pc),
        .update_en    (ex_mem_branch & ex_mem_valid),
        .pc_update    (ex_mem_pc),
        .actual_taken (actual_taken),
        .predict_taken(predict_taken)
    );

    // ---- Register file ----
    wire [31:0] rf_rd1, rf_rd2;
    reg_file rf (
        .clk(clk), .rst(rst),
        .we3(mem_wb_reg_write),
        .a1(rs1_dec), .a2(rs2_dec), .a3(mem_wb_rd),
        .wd3(wb_data),
        .rd1(rf_rd1), .rd2(rf_rd2)
    );

    // ---- Write-through (WB -> ID bypass) ----
    wire [31:0] id_rs1_val;
    wire [31:0] id_rs2_val;

    assign id_rs1_val = (mem_wb_reg_write && (mem_wb_rd != 5'd0) &&
                         (mem_wb_rd == rs1_dec))
                        ? wb_data : rf_rd1;

    assign id_rs2_val = (mem_wb_reg_write && (mem_wb_rd != 5'd0) &&
                         (mem_wb_rd == rs2_dec))
                        ? wb_data : rf_rd2;

    // ---- Forwarding unit ----
    wire [1:0] forward_a, forward_b;

    forwarding_unit fwd (
        .id_ex_rs1       (id_ex_rs1),
        .id_ex_rs2       (id_ex_rs2),
        .ex_mem_rd       (ex_mem_rd),
        .ex_mem_reg_write(ex_mem_reg_write),
        .ex_mem_valid    (ex_mem_valid),
        .mem_wb_rd       (mem_wb_rd),
        .mem_wb_reg_write(mem_wb_reg_write),
        .forward_a       (forward_a),
        .forward_b       (forward_b)
    );

    // ---- Forwarding muxes (EX stage) ----
    reg [31:0] fwd_rs1_val;
    always @(*) begin
        case (forward_a)
            2'b10:   fwd_rs1_val = ex_mem_alu_result;
            2'b01:   fwd_rs1_val = wb_data;
            default: fwd_rs1_val = id_ex_rs1_val;
        endcase
    end

    reg [31:0] fwd_rs2_val;
    always @(*) begin
        case (forward_b)
            2'b10:   fwd_rs2_val = ex_mem_alu_result;
            2'b01:   fwd_rs2_val = wb_data;
            default: fwd_rs2_val = id_ex_rs2_val;
        endcase
    end

    // ---- ALU ----
    wire [31:0] alu_b_in;
    wire [31:0] alu_result;
    assign alu_b_in = id_ex_alu_src ? id_ex_imm : fwd_rs2_val;

    alu alu_unit (
        .a(fwd_rs1_val),
        .b(alu_b_in),
        .alu_op(id_ex_alu_op),
        .result(alu_result)
    );

    // ---- Branch condition evaluation (EX stage) ----
    // Evaluates the branch condition using forwarded rs1 and rs2 values.
    // Supports BEQ (funct3=000), BNE (001), BLT (100), BGE (101).
    reg ex_branch_cond;
    always @(*) begin
        case (id_ex_branch_type)
            3'b000:  ex_branch_cond = (fwd_rs1_val == fwd_rs2_val);                        // BEQ
            3'b001:  ex_branch_cond = (fwd_rs1_val != fwd_rs2_val);                        // BNE
            3'b100:  ex_branch_cond = ($signed(fwd_rs1_val) < $signed(fwd_rs2_val));       // BLT
            3'b101:  ex_branch_cond = ($signed(fwd_rs1_val) >= $signed(fwd_rs2_val));      // BGE
            3'b110:  ex_branch_cond = (fwd_rs1_val < fwd_rs2_val);                         // BLTU
            3'b111:  ex_branch_cond = (fwd_rs1_val >= fwd_rs2_val);                        // BGEU
            default: ex_branch_cond = 1'b0;
        endcase
    end

    // ---- PC next logic ----
    wire [31:0] pred_target;
    wire [31:0] jal_target;
    assign pred_target = if_id_pc + imm_b;
    assign jal_target  = if_id_pc + imm_j;

    reg [31:0] pc_next;
    always @(*) begin
        pc_next = pc_plus4;
        if (if_id_valid && cu_branch && predict_taken && !stall)
            pc_next = pred_target;
        if (if_id_valid && cu_jump && !stall)
            pc_next = jal_target;
        if (mispredicted)
            pc_next = correct_pc;
    end

    // ---- PC register ----
    always @(posedge clk or posedge rst) begin
        if (rst)
            pc <= 32'd0;
        else if (!stall || mispredicted)
            pc <= pc_next;
    end

    wire flush_jal;
    assign flush_jal = if_id_valid && cu_jump && !stall;

    // ---- IF/ID register ----
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            if_id_valid <= 1'b0; if_id_instr <= 32'd0; if_id_pc <= 32'd0;
        end else if (mispredicted || flush_jal) begin
            if_id_valid <= 1'b0; if_id_instr <= 32'd0; if_id_pc <= 32'd0;
        end else if (stall) begin
            if_id_valid <= if_id_valid;
            if_id_instr <= if_id_instr;
            if_id_pc    <= if_id_pc;
        end else begin
            if_id_valid <= 1'b1;
            if_id_instr <= instr_in;
            if_id_pc    <= pc;
        end
    end

    // ---- ID/EX register ----
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            id_ex_valid<=0; id_ex_reg_write<=0; id_ex_mem_read<=0;
            id_ex_mem_write<=0; id_ex_branch<=0; id_ex_jump<=0;
            id_ex_rd<=0; id_ex_rs1_val<=0; id_ex_rs2_val<=0;
            id_ex_imm<=0; id_ex_pc<=0; id_ex_alu_op<=0;
            id_ex_alu_src<=0; id_ex_predict_taken<=0;
            id_ex_rs1<=0; id_ex_rs2<=0;
            id_ex_branch_type<=0;
        end else if (stall || mispredicted) begin
            id_ex_valid<=0; id_ex_reg_write<=0; id_ex_mem_read<=0;
            id_ex_mem_write<=0; id_ex_branch<=0; id_ex_jump<=0;
            id_ex_rd<=0;
            id_ex_rs1<=0; id_ex_rs2<=0;
            id_ex_branch_type<=0;
        end else begin
            id_ex_valid         <= if_id_valid;
            id_ex_pc            <= if_id_pc;
            id_ex_rs1_val       <= id_rs1_val;
            id_ex_rs2_val       <= id_rs2_val;
            id_ex_imm           <= id_imm;
            id_ex_reg_write     <= cu_reg_write & if_id_valid;
            id_ex_mem_read      <= cu_mem_read  & if_id_valid;
            id_ex_mem_write     <= cu_mem_write & if_id_valid;
            id_ex_alu_src       <= cu_alu_src;
            id_ex_alu_op        <= cu_alu_op;
            id_ex_branch        <= cu_branch & if_id_valid;
            id_ex_jump          <= cu_jump   & if_id_valid;
            id_ex_rd            <= rd_dec;
            id_ex_predict_taken <= predict_taken;
            id_ex_rs1           <= rs1_dec;
            id_ex_rs2           <= rs2_dec;
            id_ex_branch_type   <= cu_branch_type;
        end
    end

    // ---- EX/MEM register ----
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ex_mem_branch<=0; ex_mem_reg_write<=0; ex_mem_mem_read<=0;
            ex_mem_mem_write<=0; ex_mem_valid<=0; ex_mem_jump<=0;
            ex_mem_rd<=0; ex_mem_alu_result<=0; ex_mem_branch_cond<=0;
            ex_mem_pc<=0; ex_mem_branch_target<=0; ex_mem_predict_taken<=0;
            ex_mem_write_data<=0; ex_mem_pc_plus4<=0;
        end else if (mispredicted) begin
            ex_mem_branch<=0; ex_mem_reg_write<=0; ex_mem_mem_read<=0;
            ex_mem_mem_write<=0; ex_mem_valid<=0; ex_mem_jump<=0;
            ex_mem_rd<=0;
        end else begin
            ex_mem_valid         <= id_ex_valid;
            ex_mem_pc            <= id_ex_pc;
            ex_mem_pc_plus4      <= id_ex_pc + 32'd4;
            ex_mem_alu_result    <= alu_result;
            ex_mem_write_data    <= fwd_rs2_val;
            ex_mem_reg_write     <= id_ex_reg_write;
            ex_mem_mem_read      <= id_ex_mem_read;
            ex_mem_mem_write     <= id_ex_mem_write;
            ex_mem_rd            <= id_ex_rd;
            ex_mem_branch        <= id_ex_branch;
            ex_mem_branch_cond   <= ex_branch_cond;
            ex_mem_branch_target <= id_ex_pc + id_ex_imm;
            ex_mem_predict_taken <= id_ex_predict_taken;
            ex_mem_jump          <= id_ex_jump;
        end
    end

    // ---- MEM/WB register ----
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            mem_wb_reg_write<=0; mem_wb_mem_read<=0;
            mem_wb_jump<=0; mem_wb_rd<=0;
            mem_wb_alu_result<=0; mem_wb_read_data<=0;
            mem_wb_pc_plus4<=0;
        end else begin
            mem_wb_alu_result <= ex_mem_alu_result;
            mem_wb_read_data  <= data_rd;
            mem_wb_reg_write  <= ex_mem_reg_write;
            mem_wb_rd         <= ex_mem_rd;
            mem_wb_mem_read   <= ex_mem_mem_read;
            mem_wb_jump       <= ex_mem_jump;
            mem_wb_pc_plus4   <= ex_mem_pc_plus4;
        end
    end

    // ---- Memory interface ----
    assign data_addr = ex_mem_alu_result;
    assign data_wd   = ex_mem_write_data;
    assign data_we   = ex_mem_mem_write;
    assign mem_req   = ex_mem_mem_read;

endmodule