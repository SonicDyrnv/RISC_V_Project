/* This module implements a forwarding unit used in a pipelined processor to resolve data hazards.
It checks source registers (rs1, rs2) in the EX stage against destination registers in later stages.
If a match is found with EX/MEM stage and write is enabled, it forwards the most recent data.
If no EX/MEM hazard exists, it checks MEM/WB stage for possible forwarding.
Forwarding avoids pipeline stalls by bypassing register file reads.
Priority is given to EX/MEM stage over MEM/WB stage for correcness.
Register x0(zero register)is excluded from forwarding logic.
Outputs forward_a and forward_b control multiplexers for ALU inputs. */

module forwarding_unit (

    input  [4:0] id_ex_rs1,
    input  [4:0] id_ex_rs2,

    input  [4:0] ex_mem_rd,
    input        ex_mem_reg_write,
    input        ex_mem_valid,

    input  [4:0] mem_wb_rd,
    input        mem_wb_reg_write,

    output reg [1:0] forward_a,   
    output reg [1:0] forward_b    
);

    always @(*) begin

        // Default: no forwarding
        forward_a = 2'b00;
        forward_b = 2'b00;

        // EX/MEM hazard (highest priority — most recent)
        if (ex_mem_reg_write && ex_mem_valid &&
            (ex_mem_rd != 5'd0) &&
            (ex_mem_rd == id_ex_rs1)) begin
            forward_a = 2'b10;
        end

        // MEM/WB hazard (lower priority)
        else if (mem_wb_reg_write &&
                 (mem_wb_rd != 5'd0) &&
                 (mem_wb_rd == id_ex_rs1)) begin
            forward_a = 2'b01;
        end

        // EX/MEM hazard (highest priority)
        if (ex_mem_reg_write && ex_mem_valid &&
            (ex_mem_rd != 5'd0) &&
            (ex_mem_rd == id_ex_rs2)) begin
            forward_b = 2'b10;
        end

        // MEM/WB hazard (lower priority)
        else if (mem_wb_reg_write &&
                 (mem_wb_rd != 5'd0) &&
                 (mem_wb_rd == id_ex_rs2)) begin
            forward_b = 2'b01;
        end
    end

endmodule