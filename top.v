module top (
    input clk,
    input rst
);
    wire [31:0] instr_addr;
    wire [31:0] instr_in;
    wire [31:0] data_addr;
    wire [31:0] data_wd;
    wire [31:0] data_rd;
    wire        data_we;
    wire        mem_req;

    reg [31:0] imem [0:1023];
    reg [31:0] dmem [0:1023];

    initial begin
        $readmemh("program.hex", imem);
    end

    assign instr_in = imem[instr_addr[11:2]];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dmem[0] <= 32'd0;
            dmem[1] <= 32'd0;
            dmem[2] <= 32'd0;
            dmem[3] <= 32'd0;
        end else if (data_we) begin
            dmem[data_addr[11:2]] <= data_wd;
        end
    end

    assign data_rd = dmem[data_addr[11:2]];

    cpu cpu_inst (
        .clk      (clk),
        .rst      (rst),
        .instr_addr(instr_addr),
        .instr_in (instr_in),
        .data_addr(data_addr),
        .data_wd  (data_wd),
        .data_rd  (data_rd),
        .data_we  (data_we),
        .mem_req  (mem_req)
    );
endmodule
