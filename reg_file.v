//This is reg file, updated 
//I switched to vector of vector rather than those single vector brute force
//That single vector brute force can be seen in  initial commits

module reg_file (
    input         clk,
    input         rst,
    input         we3,
    input  [4:0]  a1, a2, a3,
    input  [31:0] wd3,
    output [31:0] rd1,
    output [31:0] rd2
);
    reg [31:0] regs [0:31];
    integer i;

    // x0 is always zero — read with mux
    assign rd1 = (a1 == 5'd0) ? 32'd0 : regs[a1];
    assign rd2 = (a2 == 5'd0) ? 32'd0 : regs[a2];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 32; i = i + 1)
                regs[i] <= 32'd0;
        end else if (we3 && a3 != 5'd0) begin
            regs[a3] <= wd3;
        end
    end
endmodule