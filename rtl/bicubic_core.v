`timescale 1ns / 1ps

module bicubic_core #(
    parameter DATA_WIDTH = 8
)(
    input  wire                   clk,
    input  wire                   rst,
    
    // Input Pixels: 4 rows from the Line Buffer
    // These are just single pixels arriving every clock cycle
    input  wire [DATA_WIDTH-1:0]  row0_in,
    input  wire [DATA_WIDTH-1:0]  row1_in,
    input  wire [DATA_WIDTH-1:0]  row2_in,
    input  wire [DATA_WIDTH-1:0]  row3_in,
    
    // Weights (Coefficients) from the Top Module (LUT)
    // Format: Signed 9-bit (S1.7). Example: 1.0 = 128
    // We need separate weights for Horizontal (H) and Vertical (V) phases
    input  wire signed [8:0]      h_w0, h_w1, h_w2, h_w3,
    input  wire signed [8:0]      v_w0, v_w1, v_w2, v_w3,
    
    // Output Pixel
    output reg [DATA_WIDTH-1:0]   pixel_out
);

    // =========================================================================
    // Stage 1: Create the 4x4 Window (Shift Registers)
    // We need to see 4 columns (Previous, Current, Next, Next+1)
    // =========================================================================
    reg [DATA_WIDTH-1:0] r0_c0, r0_c1, r0_c2, r0_c3;
    reg [DATA_WIDTH-1:0] r1_c0, r1_c1, r1_c2, r1_c3;
    reg [DATA_WIDTH-1:0] r2_c0, r2_c1, r2_c2, r2_c3;
    reg [DATA_WIDTH-1:0] r3_c0, r3_c1, r3_c2, r3_c3;

    always @(posedge clk) begin
        if (rst) begin
            // Reset all to 0
            r0_c0 <= 0; r0_c1 <= 0; r0_c2 <= 0; r0_c3 <= 0;
            r1_c0 <= 0; r1_c1 <= 0; r1_c2 <= 0; r1_c3 <= 0;
            r2_c0 <= 0; r2_c1 <= 0; r2_c2 <= 0; r2_c3 <= 0;
            r3_c0 <= 0; r3_c1 <= 0; r3_c2 <= 0; r3_c3 <= 0;
        end else begin
            // Shift pipeline for Row 0
            r0_c0 <= row0_in; // Newest pixel
            r0_c1 <= r0_c0;
            r0_c2 <= r0_c1;
            r0_c3 <= r0_c2;   // Oldest pixel
            
            // Shift pipeline for Row 1
            r1_c0 <= row1_in; r1_c1 <= r1_c0; r1_c2 <= r1_c1; r1_c3 <= r1_c2;
            
            // Shift pipeline for Row 2
            r2_c0 <= row2_in; r2_c1 <= r2_c0; r2_c2 <= r2_c1; r3_c3 <= r2_c2; // Typo fix: r2_c3 <= r2_c2
            r2_c3 <= r2_c2; // Corrected line
            
            // Shift pipeline for Row 3
            r3_c0 <= row3_in; r3_c1 <= r3_c0; r3_c2 <= r3_c1; r3_c3 <= r3_c2;
        end
    end

    // =========================================================================
    // Stage 2: Horizontal Interpolation (Calculating Intermediate Rows)
    // Formula: (P0*W0 + P1*W1 + P2*W2 + P3*W3)
    // =========================================================================
    
    // Function to calculate dot product for one row
    // We make this automatic to avoid writing it 4 times
    function signed [19:0] interpolate_row;
        input [7:0] p0, p1, p2, p3;
        input signed [8:0] w0, w1, w2, w3;
        begin
            // Pixel (unsigned) * Weight (signed)
            // Result needs to be large enough to hold the sum
            interpolate_row = ($signed({1'b0, p0}) * w0) + 
                              ($signed({1'b0, p1}) * w1) + 
                              ($signed({1'b0, p2}) * w2) + 
                              ($signed({1'b0, p3}) * w3);
        end
    endfunction

    reg signed [19:0] h_res_0, h_res_1, h_res_2, h_res_3;

    always @(posedge clk) begin
        // Perform horizontal interpolation for all 4 rows in parallel
        h_res_0 <= interpolate_row(r0_c3, r0_c2, r0_c1, r0_c0, h_w0, h_w1, h_w2, h_w3);
        h_res_1 <= interpolate_row(r1_c3, r1_c2, r1_c1, r1_c0, h_w0, h_w1, h_w2, h_w3);
        h_res_2 <= interpolate_row(r2_c3, r2_c2, r2_c1, r2_c0, h_w0, h_w1, h_w2, h_w3);
        h_res_3 <= interpolate_row(r3_c3, r3_c2, r3_c1, r3_c0, h_w0, h_w1, h_w2, h_w3);
    end

    // =========================================================================
    // Stage 3: Vertical Interpolation (The Final Value)
    // Now we take the 4 Horizontal results and combine them vertically
    // =========================================================================
    reg signed [19:0] v_final_sum;
    
    always @(posedge clk) begin
        // Note: We need to normalize the Horizontal results first (divide by 128)
        // Or we can just sum everything and divide by 128*128 at the end.
        // Let's divide by 128 (shift 7) now to keep numbers smaller.
        
        v_final_sum <= ( (h_res_0 >>> 7) * v_w0 ) + 
                       ( (h_res_1 >>> 7) * v_w1 ) + 
                       ( (h_res_2 >>> 7) * v_w2 ) + 
                       ( (h_res_3 >>> 7) * v_w3 );
    end

    // =========================================================================
    // Stage 4: Rounding, Normalization and Clipping
    // =========================================================================
    reg signed [19:0] result_normalized;
    
    always @(*) begin
        // We multiplied by 128 twice (Horizontal and Vertical), so we divide by 128 again.
        // Total scale factor was 128*128. We shifted once already. Shift 7 more bits.
        result_normalized = v_final_sum >>> 7;
        
        // CLIPPER: Handle overshoots (Negative numbers or > 255)
        if (result_normalized < 0)
            pixel_out = 8'd0;
        else if (result_normalized > 255)
            pixel_out = 8'd255;
        else
            pixel_out = result_normalized[7:0];
    end

endmodule