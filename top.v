module top (
    input clk,
    input rst
);
    wire [31:0] instr_addr, instr_in;
    wire [31:0] data_addr, data_wd, data_rd;
    wire        data_we, mem_req;

    // Instruction memory — 1024 words
    reg [31:0] imem [0:1023];

    // Data memory — 1024 words
    reg [31:0] dmem [0:1023];
    integer i;

    initial begin
        $readmemh("program.hex", imem);
    end

    // Instruction fetch (combinational read)
    assign instr_in = imem[instr_addr[11:2]];

    // Data memory: synchronous write, combinational read
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 4; i = i + 1)
                dmem[i] <= 32'd0;
        end else if (data_we) begin
            dmem[data_addr[11:2]] <= data_wd;
        end
    end

    assign data_rd = dmem[data_addr[11:2]];

    cpu cpu_inst (
        .clk       (clk),
        .rst       (rst),
        .instr_addr(instr_addr),
        .instr_in  (instr_in),
        .data_addr (data_addr),
        .data_wd   (data_wd),
        .data_rd   (data_rd),
        .data_we   (data_we),
        .mem_req   (mem_req)
    );
endmodule