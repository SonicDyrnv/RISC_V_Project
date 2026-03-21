/* This module implements a 2-bit saturating counter branch predictor with 16 entries.
The table is indexed using PC[5:2], allowing prediction based on recent branch history.
Each entry stores a 2-bit state representing strongly/weakly taken or not taken.
Prediction is made by checking if the counter value is >= 2 (predict taken).
On update, the corresponding counter is incremented or decremented based on actual outcome.
Counters saturate at 00 (strongly not taken) and 11 (strongly taken).
All entries are initialized to weakly not taken (01) on reset.
The design improves pipeline performance by reducing branch mispredictions. */

module predictor (
    input         clk,
    input         rst,
    input  [31:0] pc_in,
    input         update_en,
    input  [31:0] pc_update,
    input         actual_taken,
    output reg    predict_taken
);

    reg [1:0] c0,  c1,  c2,  c3,
              c4,  c5,  c6,  c7,
              c8,  c9,  c10, c11,
              c12, c13, c14, c15;

    wire [3:0] ridx = pc_in[5:2];
    wire [3:0] widx = pc_update[5:2];

    // Read current prediction value
    reg [1:0] rval;
    always @(*) begin
        case (ridx)
            4'd0:  rval = c0;  4'd1:  rval = c1;
            4'd2:  rval = c2;  4'd3:  rval = c3;
            4'd4:  rval = c4;  4'd5:  rval = c5;
            4'd6:  rval = c6;  4'd7:  rval = c7;
            4'd8:  rval = c8;  4'd9:  rval = c9;
            4'd10: rval = c10; 4'd11: rval = c11;
            4'd12: rval = c12; 4'd13: rval = c13;
            4'd14: rval = c14; default: rval = c15;
        endcase
        predict_taken = (rval >= 2'b10) ? 1'b1 : 1'b0;
    end

    // Read value at update index
    reg [1:0] wval;
    always @(*) begin
        case (widx)
            4'd0:  wval = c0;  4'd1:  wval = c1;
            4'd2:  wval = c2;  4'd3:  wval = c3;
            4'd4:  wval = c4;  4'd5:  wval = c5;
            4'd6:  wval = c6;  4'd7:  wval = c7;
            4'd8:  wval = c8;  4'd9:  wval = c9;
            4'd10: wval = c10; 4'd11: wval = c11;
            4'd12: wval = c12; 4'd13: wval = c13;
            4'd14: wval = c14; default: wval = c15;
        endcase
    end

    // Compute next counter value
    wire [1:0] wval_inc = (wval == 2'b11) ? 2'b11 : wval + 2'b01;
    wire [1:0] wval_dec = (wval == 2'b00) ? 2'b00 : wval - 2'b01;
    wire [1:0] wval_next = actual_taken ? wval_inc : wval_dec;

    // Updates table on clock edge
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            c0<=2'b01;  c1<=2'b01;  c2<=2'b01;  c3<=2'b01;
            c4<=2'b01;  c5<=2'b01;  c6<=2'b01;  c7<=2'b01;
            c8<=2'b01;  c9<=2'b01;  c10<=2'b01; c11<=2'b01;
            c12<=2'b01; c13<=2'b01; c14<=2'b01; c15<=2'b01;
        end else if (update_en) begin
            case (widx)
                4'd0:  c0  <= wval_next; 4'd1:  c1  <= wval_next;
                4'd2:  c2  <= wval_next; 4'd3:  c3  <= wval_next;
                4'd4:  c4  <= wval_next; 4'd5:  c5  <= wval_next;
                4'd6:  c6  <= wval_next; 4'd7:  c7  <= wval_next;
                4'd8:  c8  <= wval_next; 4'd9:  c9  <= wval_next;
                4'd10: c10 <= wval_next; 4'd11: c11 <= wval_next;
                4'd12: c12 <= wval_next; 4'd13: c13 <= wval_next;
                4'd14: c14 <= wval_next; default: c15 <= wval_next;
            endcase
        end
    end

endmodule