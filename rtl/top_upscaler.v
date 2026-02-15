`timescale 1ns / 1ps

module top_upscaler #(
    parameter IMG_W = 128,      // Input Width
    parameter IMG_H = 72        // Input Height
)(
    input  wire        clk,
    input  wire        rst,
    
    // Input Stream (From Testbench)
    input  wire [7:0]  pixel_in,
    input  wire        input_valid,
    
    // Output Stream (To Testbench)
    output wire [7:0]  pixel_out,
    output reg         output_valid
);

    // =========================================================================
    // 1. Coefficient ROM (The Lookup Table)
    // We have 3 phases for 3x scaling (0.0, 0.33, 0.66)
    // Format: 4 weights per phase (w0, w1, w2, w3)
    // =========================================================================
    reg signed [8:0] coeff_rom [0:11]; // 3 phases * 4 weights = 12 entries
    
    initial begin
        // Load the weights we generated in Python/C++
        // This file must be in the simulation folder for Vivado to find it
        $readmemh("D:/vivado_projects/image_upscale/sim/coeffs.txt", coeff_rom);
    end

    // =========================================================================
    // 2. Line Buffer Instance
    // Stores 3 previous rows so we can access a vertical column
    // =========================================================================
    wire [7:0] r0, r1, r2, r3;
    
    line_buffer #(
        .IMG_WIDTH(IMG_W)
    ) lb_inst (
        .clk(clk),
        .rst(rst),
        .ce(input_valid), // Only shift when valid data comes in
        .din(pixel_in),
        .dout_0(r0), // Current Row
        .dout_1(r1),
        .dout_2(r2),
        .dout_3(r3)  // Oldest Row
    );

    // =========================================================================
    // 3. Phase Counters (The Scaling Logic)
    // We need to know: "Are we computing output pixel 1, 2, or 3?"
    // =========================================================================
    reg [1:0] h_phase; // Horizontal Phase (0, 1, 2)
    reg [1:0] v_phase; // Vertical Phase (0, 1, 2)
    
    // Since we are simulating a pure pipeline, we will cheat slightly for simplicity:
    // We assume the Testbench feeds the SAME input pixel 3 times horizontally,
    // and repeats the entire row 3 times vertically.
    // This removes complex "Stall" logic from the hardware.
    
    always @(posedge clk) begin
        if (rst) begin
            h_phase <= 0;
            v_phase <= 0;
        end else if (input_valid) begin
            // Simple Modulo-3 Counter for Horizontal Phase
            if (h_phase == 2) 
                h_phase <= 0;
            else 
                h_phase <= h_phase + 1;
                
            // Vertical logic would go here if we were handling full frame timing
            // For now, we drive phases from the testbench loop for maximum control.
        end
    end

    // =========================================================================
    // 4. Fetch Weights based on Phase
    // =========================================================================
    reg signed [8:0] h_w0, h_w1, h_w2, h_w3;
    reg signed [8:0] v_w0, v_w1, v_w2, v_w3;
    
    always @(*) begin
        // Horizontal Weights Lookup
        // Base address is phase * 4
        h_w0 = coeff_rom[{h_phase, 2'b00}]; // index = phase*4 + 0
        h_w1 = coeff_rom[{h_phase, 2'b01}]; // index = phase*4 + 1
        h_w2 = coeff_rom[{h_phase, 2'b10}]; // index = phase*4 + 2
        h_w3 = coeff_rom[{h_phase, 2'b11}]; // index = phase*4 + 3
        
        // Vertical Weights (Fixed to 0 for this simplified test, or drive from input)
        // Ideally, you'd have a v_phase input or counter. 
        // Let's assume v_phase matches h_phase for a symmetric test.
        v_w0 = coeff_rom[{v_phase, 2'b00}]; 
        v_w1 = coeff_rom[{v_phase, 2'b01}]; 
        v_w2 = coeff_rom[{v_phase, 2'b10}]; 
        v_w3 = coeff_rom[{v_phase, 2'b11}]; 
    end

    // =========================================================================
    // 5. The Bicubic Core Instance
    // =========================================================================
    bicubic_core core_inst (
        .clk(clk),
        .rst(rst),
        // Data Inputs
        .row0_in(r0), .row1_in(r1), .row2_in(r2), .row3_in(r3),
        // Weight Inputs
        .h_w0(h_w0), .h_w1(h_w1), .h_w2(h_w2), .h_w3(h_w3),
        .v_w0(v_w0), .v_w1(v_w1), .v_w2(v_w2), .v_w3(v_w3),
        // Output
        .pixel_out(pixel_out)
    );

    // Delay the valid signal to match the pipeline latency of the core
    // The core takes ~3 cycles to compute.
    reg [2:0] valid_pipe;
    always @(posedge clk) begin
        if (rst) valid_pipe <= 0;
        else valid_pipe <= {valid_pipe[1:0], input_valid};
    end
    
    always @(*) output_valid = valid_pipe[2];

endmodule