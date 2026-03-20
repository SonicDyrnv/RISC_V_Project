// I am using such declarations because I couldn't simulate 2d registers
// So I choose to go with such declarations
// reason as far as I know verilog don't support it 

module reg_file (
    input         clk,
    input         rst,
    input         we3,
    input  [4:0]  a1, a2, a3,
    input  [31:0] wd3,
    output reg [31:0] rd1,
    output reg [31:0] rd2
);
    reg [31:0] r1,  r2,  r3,  r4,  r5,  r6,  r7,  r8;
    reg [31:0] r9,  r10, r11, r12, r13, r14, r15, r16;
    reg [31:0] r17, r18, r19, r20, r21, r22, r23, r24;
    reg [31:0] r25, r26, r27, r28, r29, r30, r31;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            r1<=0;  r2<=0;  r3<=0;  r4<=0;
            r5<=0;  r6<=0;  r7<=0;  r8<=0;
            r9<=0;  r10<=0; r11<=0; r12<=0;
            r13<=0; r14<=0; r15<=0; r16<=0;
            r17<=0; r18<=0; r19<=0; r20<=0;
            r21<=0; r22<=0; r23<=0; r24<=0;
            r25<=0; r26<=0; r27<=0; r28<=0;
            r29<=0; r30<=0; r31<=0;
        end else if (we3 && a3 != 5'd0) begin
            case (a3)
                5'd1:  r1  <= wd3; 5'd2:  r2  <= wd3;
                5'd3:  r3  <= wd3; 5'd4:  r4  <= wd3;
                5'd5:  r5  <= wd3; 5'd6:  r6  <= wd3;
                5'd7:  r7  <= wd3; 5'd8:  r8  <= wd3;
                5'd9:  r9  <= wd3; 5'd10: r10 <= wd3;
                5'd11: r11 <= wd3; 5'd12: r12 <= wd3;
                5'd13: r13 <= wd3; 5'd14: r14 <= wd3;
                5'd15: r15 <= wd3; 5'd16: r16 <= wd3;
                5'd17: r17 <= wd3; 5'd18: r18 <= wd3;
                5'd19: r19 <= wd3; 5'd20: r20 <= wd3;
                5'd21: r21 <= wd3; 5'd22: r22 <= wd3;
                5'd23: r23 <= wd3; 5'd24: r24 <= wd3;
                5'd25: r25 <= wd3; 5'd26: r26 <= wd3;
                5'd27: r27 <= wd3; 5'd28: r28 <= wd3;
                5'd29: r29 <= wd3; 5'd30: r30 <= wd3;
                5'd31: r31 <= wd3;
                default: r1 <= r1;
            endcase
        end
    end

    always @(*) begin
        case (a1)
            5'd0:  rd1 = 32'd0;
            5'd1:  rd1 = r1;  5'd2:  rd1 = r2;
            5'd3:  rd1 = r3;  5'd4:  rd1 = r4;
            5'd5:  rd1 = r5;  5'd6:  rd1 = r6;
            5'd7:  rd1 = r7;  5'd8:  rd1 = r8;
            5'd9:  rd1 = r9;  5'd10: rd1 = r10;
            5'd11: rd1 = r11; 5'd12: rd1 = r12;
            5'd13: rd1 = r13; 5'd14: rd1 = r14;
            5'd15: rd1 = r15; 5'd16: rd1 = r16;
            5'd17: rd1 = r17; 5'd18: rd1 = r18;
            5'd19: rd1 = r19; 5'd20: rd1 = r20;
            5'd21: rd1 = r21; 5'd22: rd1 = r22;
            5'd23: rd1 = r23; 5'd24: rd1 = r24;
            5'd25: rd1 = r25; 5'd26: rd1 = r26;
            5'd27: rd1 = r27; 5'd28: rd1 = r28;
            5'd29: rd1 = r29; 5'd30: rd1 = r30;
            default: rd1 = r31;
        endcase
    end

    always @(*) begin
        case (a2)
            5'd0:  rd2 = 32'd0;
            5'd1:  rd2 = r1;  5'd2:  rd2 = r2;
            5'd3:  rd2 = r3;  5'd4:  rd2 = r4;
            5'd5:  rd2 = r5;  5'd6:  rd2 = r6;
            5'd7:  rd2 = r7;  5'd8:  rd2 = r8;
            5'd9:  rd2 = r9;  5'd10: rd2 = r10;
            5'd11: rd2 = r11; 5'd12: rd2 = r12;
            5'd13: rd2 = r13; 5'd14: rd2 = r14;
            5'd15: rd2 = r15; 5'd16: rd2 = r16;
            5'd17: rd2 = r17; 5'd18: rd2 = r18;
            5'd19: rd2 = r19; 5'd20: rd2 = r20;
            5'd21: rd2 = r21; 5'd22: rd2 = r22;
            5'd23: rd2 = r23; 5'd24: rd2 = r24;
            5'd25: rd2 = r25; 5'd26: rd2 = r26;
            5'd27: rd2 = r27; 5'd28: rd2 = r28;
            5'd29: rd2 = r29; 5'd30: rd2 = r30;
            default: rd2 = r31;
        endcase
    end
endmodule
