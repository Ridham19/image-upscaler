`timescale 1ns / 1ps

module bicubic_core #(
    parameter DATA_WIDTH = 8
)(
    input  wire                   clk,
    input  wire                   rst,
    
    // Inputs: Raw bits (No behavioral signed/unsigned keywords)
    input  wire [DATA_WIDTH-1:0]  row0_in, row1_in, row2_in, row3_in,
    input  wire [8:0]             h_w0, h_w1, h_w2, h_w3,
    input  wire [8:0]             v_w0, v_w1, v_w2, v_w3,
    
    output wire [DATA_WIDTH-1:0]  pixel_out
);

    // =========================================================================
    // Stage 1: Pipeline Registers (4x4 Pixel Window)
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
        end else begin
            r0_c0 <= row0_in; r0_c1 <= r0_c0; r0_c2 <= r0_c1; r0_c3 <= r0_c2;
            r1_c0 <= row1_in; r1_c1 <= r1_c0; r1_c2 <= r1_c1; r1_c3 <= r1_c2;
            r2_c0 <= row2_in; r2_c1 <= r2_c0; r2_c2 <= r2_c1; r2_c3 <= r2_c2;
            r3_c0 <= row3_in; r3_c1 <= r3_c0; r3_c2 <= r3_c1; r3_c3 <= r3_c2;
        end
    end

    // =========================================================================
    // Stage 2: Structural Horizontal Pass
    // =========================================================================
    wire [19:0] h_raw_0, h_raw_1, h_raw_2, h_raw_3;
    wire [7:0]  h_norm_0, h_norm_1, h_norm_2, h_norm_3;

    // 4x Dot Product Units
    dot_product_4 dp_h0 (.p0(r0_c3), .p1(r0_c2), .p2(r0_c1), .p3(r0_c0), .w0(h_w0), .w1(h_w1), .w2(h_w2), .w3(h_w3), .result(h_raw_0));
    dot_product_4 dp_h1 (.p0(r1_c3), .p1(r1_c2), .p2(r1_c1), .p3(r1_c0), .w0(h_w0), .w1(h_w1), .w2(h_w2), .w3(h_w3), .result(h_raw_1));
    dot_product_4 dp_h2 (.p0(r2_c3), .p1(r2_c2), .p2(r2_c1), .p3(r2_c0), .w0(h_w0), .w1(h_w1), .w2(h_w2), .w3(h_w3), .result(h_raw_2));
    dot_product_4 dp_h3 (.p0(r3_c3), .p1(r3_c2), .p2(r3_c1), .p3(r3_c0), .w0(h_w0), .w1(h_w1), .w2(h_w2), .w3(h_w3), .result(h_raw_3));

    // 4x Clippers (Normalize to 8-bit before Vertical Pass)
    pixel_clipper clip_h0 (.in_val(h_raw_0), .out_pixel(h_norm_0));
    pixel_clipper clip_h1 (.in_val(h_raw_1), .out_pixel(h_norm_1));
    pixel_clipper clip_h2 (.in_val(h_raw_2), .out_pixel(h_norm_2));
    pixel_clipper clip_h3 (.in_val(h_raw_3), .out_pixel(h_norm_3));

    // Pipeline Register to stabilize timing between H and V passes
    reg [7:0] v_in_0, v_in_1, v_in_2, v_in_3;
    always @(posedge clk) begin
        if (rst) begin
            v_in_0 <= 0; v_in_1 <= 0; v_in_2 <= 0; v_in_3 <= 0;
        end else begin
            v_in_0 <= h_norm_0;
            v_in_1 <= h_norm_1;
            v_in_2 <= h_norm_2;
            v_in_3 <= h_norm_3;
        end
    end

    // =========================================================================
    // Stage 3: Structural Vertical Pass & Final Output
    // =========================================================================
    wire [19:0] v_raw_final;
    
    // 1x Dot Product Unit
    dot_product_4 dp_v (.p0(v_in_3), .p1(v_in_2), .p2(v_in_1), .p3(v_in_0), .w0(v_w0), .w1(v_w1), .w2(v_w2), .w3(v_w3), .result(v_raw_final));

    // 1x Clipper (Final Output)
    // Note: In top_upscaler.v, you must change 'output reg' to 'output wire' since this is driven by continuous assignment
    pixel_clipper clip_final (.in_val(v_raw_final), .out_pixel(pixel_out));

endmodule