`timescale 1ns / 1ps

module tb_upscaler;

    // =========================================================================
    // 1. Parameters & Signals
    // =========================================================================
    parameter IMG_W = 128; // Must match Python script
    parameter IMG_H = 72;
    parameter SCALE = 3;   // 3x Scaling
    
    reg clk;
    reg rst;
    
    // Inputs to DUT (Device Under Test)
    reg [7:0] pixel_in;
    reg       input_valid;
    
    // Outputs from DUT
    wire [7:0] pixel_out;
    wire       output_valid;

    // File Handlers
    integer f_in, f_out;
    integer scan_res;
    integer i, j, k;

    // =========================================================================
    // 2. Clock Generation (100 MHz)
    // =========================================================================
    always #5 clk = ~clk; 

    // =========================================================================
    // 3. Instantiate the Top Module
    // =========================================================================
    top_upscaler #(
        .IMG_W(IMG_W),
        .IMG_H(IMG_H)
    ) dut (
        .clk(clk),
        .rst(rst),
        .pixel_in(pixel_in),
        .input_valid(input_valid),
        .pixel_out(pixel_out),
        .output_valid(output_valid)
    );

    // =========================================================================
    // 4. Capture Output Process
    // =========================================================================
    initial begin
        f_out = $fopen("output_image.hex", "w"); // Will be created in sim folder
    end

    always @(posedge clk) begin
        if (output_valid) begin
            // Write hex value to file
            $fwrite(f_out, "%h\n", pixel_out);
        end
    end

    // =========================================================================
    // 5. Main Stimulus Process (The Smart Feeder)
    // =========================================================================
    reg [7:0] row_buffer [0:IMG_W-1]; // Temp storage for one row
    
    initial begin
        // Initialize Signals
        clk = 0;
        rst = 1;
        pixel_in = 0;
        input_valid = 0;
        
        // Open Input File (Ensure this path matches where Python saved it!)
        // Note: In Vivado Simulation, just the filename usually works if it's added to sources.
        // If it fails, use the absolute path.
        f_in = $fopen("input_image.hex", "r");
        
        if (f_in == 0) begin
            $display("ERROR: Could not open input_image.hex");
            $finish;
        end

        // Apply Reset
        #100;
        rst = 0;
        #20;

        // ---------------------------------------------------------------------
        // The Loop: Read Image Row by Row
        // ---------------------------------------------------------------------
        for (i = 0; i < IMG_H; i = i + 1) begin
            
            // Step A: Load one full row from file into simulation memory
            for (j = 0; j < IMG_W; j = j + 1) begin
                scan_res = $fscanf(f_in, "%h\n", row_buffer[j]);
            end

            // Step B: Send this row to the FPGA multiple times (Vertical Scaling)
            // For 3x scaling, we send the same row 3 times.
            for (k = 0; k < SCALE; k = k + 1) begin
                
                // Send pixels of this row
                for (j = 0; j < IMG_W; j = j + 1) begin
                    
                    // Step C: Send each pixel multiple times (Horizontal Scaling)
                    // The 'top_upscaler' expects us to hold the pixel for 3 clocks
                    // or send it 3 times so it can cycle through phases 0, 1, 2.
                    repeat (SCALE) begin
                        @(posedge clk);
                        pixel_in <= row_buffer[j];
                        input_valid <= 1;
                    end
                end
                
                // Small gap between rows (optional, mimics horizontal blanking)
                @(posedge clk);
                input_valid <= 0;
            end
        end

        // End of Simulation
        #1000; // Wait for pipeline to drain
        $fclose(f_in);
        $fclose(f_out);
        $display("Simulation Complete. Output saved to output_image.hex");
        $finish;
    end

endmodule