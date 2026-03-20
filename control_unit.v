// Control Unit Module
// Implement instruction decode stage of the CPU,
// generating all necessary control signals based on the instruction
// fields: opcode, funct3, and funct7.
// instructions including R-type, I-type, Load (LW), Store (SW),
// Branch (BEQ-type), and Jump (JAL).
// The control unit determines data path behavior such as register
// write enable, memory access control, ALU operation selection,
// immediate type selection, and branch/jump decisions. 
// ALU operations are encoded into a 4-bit signal and mapped according
// to instruction type and function fields. This module is purely
// combinational and is critical for correct instruction execution.

module control_unit (
    input  [6:0]  opcode,
    input  [2:0]  funct3,
    input  [6:0]  funct7,
    output reg        reg_write,
    output reg        mem_read,
    output reg        mem_write,
    output reg        alu_src,
    output reg [1:0]  imm_src,
    output reg        branch,
    output reg        jump,
    output reg [3:0]  alu_op
);
    // Opcode constants
    localparam R_TYPE = 7'b0110011;
    localparam I_TYPE = 7'b0010011;
    localparam LW     = 7'b0000011;
    localparam SW     = 7'b0100011;
    localparam BR     = 7'b1100011;
    localparam JAL    = 7'b1101111;

    always @(*) begin
        // Safe defaults
        reg_write = 1'b0;
        mem_read  = 1'b0;
        mem_write = 1'b0;
        alu_src   = 1'b0;
        imm_src   = 2'b00;
        branch    = 1'b0;
        jump      = 1'b0;
        alu_op    = 4'b0000;

        case (opcode)
            R_TYPE: begin
                reg_write = 1'b1;
                alu_src   = 1'b0;
                case (funct3)
                    3'b000: alu_op = (funct7 == 7'b0100000) ? 4'b0001 : 4'b0000; // SUB : ADD
                    3'b111: alu_op = 4'b0010; // AND  (FIX: was 4'b0011)
                    3'b110: alu_op = 4'b0011; // OR   (FIX: was 4'b0100)
                    3'b100: alu_op = 4'b0100; // XOR  (FIX: was 4'b0101)
                    3'b010: alu_op = 4'b0101; // SLT
                    3'b001: alu_op = 4'b0110; // SLL
                    3'b101: alu_op = (funct7 == 7'b0000000) ? 4'b0111 : 4'b0000; // SRL : (no SRA)
                    default: alu_op = 4'b0000;
                endcase
            end
            I_TYPE: begin
                reg_write = 1'b1;
                alu_src   = 1'b1;
                imm_src   = 2'b00;
                case (funct3)
                    3'b000: alu_op = 4'b0000; // ADDI
                    3'b111: alu_op = 4'b0010; // ANDI
                    3'b110: alu_op = 4'b0011; // ORI
                    3'b100: alu_op = 4'b0100; // XORI
                    3'b010: alu_op = 4'b0101; // SLTI
                    3'b001: alu_op = 4'b0110; // SLLI
                    3'b101: alu_op = 4'b0111; // SRLI
                    default: alu_op = 4'b0000;
                endcase
            end
            LW: begin
                reg_write = 1'b1;
                mem_read  = 1'b1;
                alu_src   = 1'b1;
                imm_src   = 2'b00;
                alu_op    = 4'b0000; // ADD for address calc
            end
            SW: begin
                mem_write = 1'b1;
                alu_src   = 1'b1;
                imm_src   = 2'b01;
                alu_op    = 4'b0000; // ADD for address calc
            end
            BR: begin
                branch  = 1'b1;
                alu_src = 1'b0;
                imm_src = 2'b10;
                alu_op  = 4'b0001; // SUB to compare (zero flag)
            end
            JAL: begin
                reg_write = 1'b1;
                jump      = 1'b1;
                alu_src   = 1'b1;
                imm_src   = 2'b11;
                alu_op    = 4'b0000;
            end
            default: begin
                // All outputs already at safe defaults
            end
        endcase
    end
endmodule
