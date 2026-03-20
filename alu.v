module alu (
    input      [31:0] a,
    input      [31:0] b,
    input      [3:0]  alu_op,
    output reg [31:0] result
);
    localparam OP_ADD = 4'b0000;
    localparam OP_SUB = 4'b0001;
    localparam OP_AND = 4'b0010;
    localparam OP_OR  = 4'b0011;
    localparam OP_XOR = 4'b0100;
    localparam OP_SLT = 4'b0101;
    localparam OP_SLL = 4'b0110;
    localparam OP_SRL = 4'b0111;

    always @(*) begin
        case (alu_op)
            OP_ADD: result = a + b;
            OP_SUB: result = a - b;
            OP_AND: result = a & b;
            OP_OR:  result = a | b;
            OP_XOR: result = a ^ b;
            OP_SLT: result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
            OP_SLL: result = a << b[4:0];
            OP_SRL: result = a >> b[4:0];
            default: result = 32'd0;
        endcase
    end
endmodule