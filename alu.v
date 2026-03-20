/* ALU Module
   I have tried to cover all the cases I could see
   Supports: ADD, SUB, AND, OR, XOR, SLT, SLL, SRL */
module alu (
    input  [31:0] a,
    input  [31:0] b,
    input  [3:0]  alu_op,
    output reg [31:0] result
);
    always @(*) begin
        case (alu_op)
            4'b0000: result = a + b;                    // ADD
            4'b0001: result = a - b;                    // SUB
            4'b0010: result = a & b;                    // AND
            4'b0011: result = a | b;                    // OR
            4'b0100: result = a ^ b;                    // XOR
            4'b0101: result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0; // SLT (signed)
            4'b0110: result = a << b[4:0];              // SLL
            4'b0111: result = a >> b[4:0];              // SRL
            default: result = 32'd0;
        endcase
    end
endmodule
