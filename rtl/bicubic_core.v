`timescale 1ns / 1ns

// Structural Submodules (Safe to leave here, they only synthesize if instantiated)
module reg8 (input clk, rst, input [7:0] d, output [7:0] q);
    genvar i; generate for (i=0; i<8; i=i+1) begin : dff_loop
        dff f (.clk(clk), .rst(rst), .d(d[i]), .q(q[i]));
    end endgenerate
endmodule

module reg8_en (input clk, rst, en, input [7:0] d, output [7:0] q);
    genvar i; generate for (i=0; i<8; i=i+1) begin : reg_loop
        wire d_next; mux2 m (.d0(q[i]), .d1(d[i]), .s(en), .y(d_next));
        dff f (.clk(clk), .rst(rst), .d(d_next), .q(q[i]));
    end endgenerate
endmodule

module bicubic_core #(
    parameter DATA_WIDTH = 8
)(
    input  wire                   clk, rst, shift_window, 
    input  wire [DATA_WIDTH-1:0]  row0_in, row1_in, row2_in, row3_in,
    input  wire [8:0]             h_w0, h_w1, h_w2, h_w3, v_w0, v_w1, v_w2, v_w3,
    output wire [DATA_WIDTH-1:0]  pixel_out
);

`ifdef BEHAVIORAL
    // =========================================================================
    // BEHAVIORAL STAGE 1: Shift Registers & Pipeline
    // =========================================================================
    reg [7:0] r0_c0, r0_c1, r0_c2, r0_c3;
    reg [7:0] r1_c0, r1_c1, r1_c2, r1_c3;
    reg [7:0] r2_c0, r2_c1, r2_c2, r2_c3;
    reg [7:0] r3_c0, r3_c1, r3_c2, r3_c3;

    always @(posedge clk) begin
        if (rst) begin
            r0_c0<=0; r0_c1<=0; r0_c2<=0; r0_c3<=0;
            r1_c0<=0; r1_c1<=0; r1_c2<=0; r1_c3<=0;
            r2_c0<=0; r2_c1<=0; r2_c2<=0; r2_c3<=0;
            r3_c0<=0; r3_c1<=0; r3_c2<=0; r3_c3<=0;
        end else if (shift_window) begin
            r0_c0 <= row0_in; r0_c1 <= r0_c0; r0_c2 <= r0_c1; r0_c3 <= r0_c2;
            r1_c0 <= row1_in; r1_c1 <= r1_c0; r1_c2 <= r1_c1; r1_c3 <= r1_c2;
            r2_c0 <= row2_in; r2_c1 <= r2_c0; r2_c2 <= r2_c1; r2_c3 <= r2_c2;
            r3_c0 <= row3_in; r3_c1 <= r3_c0; r3_c2 <= r3_c1; r3_c3 <= r3_c2;
        end
    end

`else
    // =========================================================================
    // STRUCTURAL STAGE 1: Gate-Level Registers
    // =========================================================================
    wire [7:0] r0_c0, r0_c1, r0_c2, r0_c3;
    wire [7:0] r1_c0, r1_c1, r1_c2, r1_c3;
    wire [7:0] r2_c0, r2_c1, r2_c2, r2_c3;
    wire [7:0] r3_c0, r3_c1, r3_c2, r3_c3;

    reg8_en R00 (.clk(clk), .rst(rst), .en(shift_window), .d(row0_in), .q(r0_c0));
    reg8_en R01 (.clk(clk), .rst(rst), .en(shift_window), .d(r0_c0),   .q(r0_c1));
    reg8_en R02 (.clk(clk), .rst(rst), .en(shift_window), .d(r0_c1),   .q(r0_c2));
    reg8_en R03 (.clk(clk), .rst(rst), .en(shift_window), .d(r0_c2),   .q(r0_c3));

    reg8_en R10 (.clk(clk), .rst(rst), .en(shift_window), .d(row1_in), .q(r1_c0));
    reg8_en R11 (.clk(clk), .rst(rst), .en(shift_window), .d(r1_c0),   .q(r1_c1));
    reg8_en R12 (.clk(clk), .rst(rst), .en(shift_window), .d(r1_c1),   .q(r1_c2));
    reg8_en R13 (.clk(clk), .rst(rst), .en(shift_window), .d(r1_c2),   .q(r1_c3));

    reg8_en R20 (.clk(clk), .rst(rst), .en(shift_window), .d(row2_in), .q(r2_c0));
    reg8_en R21 (.clk(clk), .rst(rst), .en(shift_window), .d(r2_c0),   .q(r2_c1));
    reg8_en R22 (.clk(clk), .rst(rst), .en(shift_window), .d(r2_c1),   .q(r2_c2));
    reg8_en R23 (.clk(clk), .rst(rst), .en(shift_window), .d(r2_c2),   .q(r2_c3));

    reg8_en R30 (.clk(clk), .rst(rst), .en(shift_window), .d(row3_in), .q(r3_c0));
    reg8_en R31 (.clk(clk), .rst(rst), .en(shift_window), .d(r3_c0),   .q(r3_c1));
    reg8_en R32 (.clk(clk), .rst(rst), .en(shift_window), .d(r3_c1),   .q(r3_c2));
    reg8_en R33 (.clk(clk), .rst(rst), .en(shift_window), .d(r3_c2),   .q(r3_c3));
`endif

    // =========================================================================
    // STAGE 2: Horizontal Pass (Automatically routes based on master switch)
    // =========================================================================
    wire [19:0] h_raw_0, h_raw_1, h_raw_2, h_raw_3;
    wire [7:0]  h_norm_0, h_norm_1, h_norm_2, h_norm_3;

    dot_product_4 dp_h0 (.p0(r0_c3), .p1(r0_c2), .p2(r0_c1), .p3(r0_c0), .w0(h_w0), .w1(h_w1), .w2(h_w2), .w3(h_w3), .result(h_raw_0));
    dot_product_4 dp_h1 (.p0(r1_c3), .p1(r1_c2), .p2(r1_c1), .p3(r1_c0), .w0(h_w0), .w1(h_w1), .w2(h_w2), .w3(h_w3), .result(h_raw_1));
    dot_product_4 dp_h2 (.p0(r2_c3), .p1(r2_c2), .p2(r2_c1), .p3(r2_c0), .w0(h_w0), .w1(h_w1), .w2(h_w2), .w3(h_w3), .result(h_raw_2));
    dot_product_4 dp_h3 (.p0(r3_c3), .p1(r3_c2), .p2(r3_c1), .p3(r3_c0), .w0(h_w0), .w1(h_w1), .w2(h_w2), .w3(h_w3), .result(h_raw_3));

    pixel_clipper clip_h0 (.in_val(h_raw_0), .out_pixel(h_norm_0));
    pixel_clipper clip_h1 (.in_val(h_raw_1), .out_pixel(h_norm_1));
    pixel_clipper clip_h2 (.in_val(h_raw_2), .out_pixel(h_norm_2));
    pixel_clipper clip_h3 (.in_val(h_raw_3), .out_pixel(h_norm_3));

`ifdef BEHAVIORAL
    reg [7:0] v_in_0, v_in_1, v_in_2, v_in_3;
    always @(posedge clk) begin
        if (rst) begin
            v_in_0 <= 0; v_in_1 <= 0; v_in_2 <= 0; v_in_3 <= 0;
        end else begin
            v_in_0 <= h_norm_0; v_in_1 <= h_norm_1; v_in_2 <= h_norm_2; v_in_3 <= h_norm_3;
        end
    end
`else
    wire [7:0] v_in_0, v_in_1, v_in_2, v_in_3;
    reg8 V0 (.clk(clk), .rst(rst), .d(h_norm_0), .q(v_in_0));
    reg8 V1 (.clk(clk), .rst(rst), .d(h_norm_1), .q(v_in_1));
    reg8 V2 (.clk(clk), .rst(rst), .d(h_norm_2), .q(v_in_2));
    reg8 V3 (.clk(clk), .rst(rst), .d(h_norm_3), .q(v_in_3));
`endif

    // =========================================================================
    // STAGE 3: Vertical Pass
    // =========================================================================
    wire [19:0] v_raw_final;
    dot_product_4 dp_v (.p0(v_in_3), .p1(v_in_2), .p2(v_in_1), .p3(v_in_0), .w0(v_w0), .w1(v_w1), .w2(v_w2), .w3(v_w3), .result(v_raw_final));
    pixel_clipper clip_final (.in_val(v_raw_final), .out_pixel(pixel_out));

endmodule