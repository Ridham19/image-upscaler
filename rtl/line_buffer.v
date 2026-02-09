`timescale 1ns / 1ps

module line_buffer #(
    parameter DATA_WIDTH = 8,      // 8-bit pixels
    parameter IMG_WIDTH  = 128     // CHANGE THIS to match your simulation target
)(
    input  wire                   clk,
    input  wire                   rst,
    input  wire                   ce,         // Clock Enable (only shift when new data arrives)
    input  wire [DATA_WIDTH-1:0]  din,        // New incoming pixel
    
    // Outputs: The same column across 4 vertical rows
    output wire [DATA_WIDTH-1:0]  dout_0,     // Current Row (Newest)
    output wire [DATA_WIDTH-1:0]  dout_1,     // Row - 1
    output wire [DATA_WIDTH-1:0]  dout_2,     // Row - 2
    output wire [DATA_WIDTH-1:0]  dout_3      // Row - 3 (Oldest)
);

    // =========================================================================
    // Internal Memory (RAM) to store the lines
    // We need 3 buffers to store 3 full previous rows.
    // The "Current Row" (dout_0) is just the input passing through.
    // =========================================================================
    
    // In simulation/small FPGAs, these will synthesize as Distributed RAM (LUTs).
    // In large images (1080p), Vivado will automatically map these to Block RAM (BRAM).
    
    reg [DATA_WIDTH-1:0] line_ram_0 [0:IMG_WIDTH-1];
    reg [DATA_WIDTH-1:0] line_ram_1 [0:IMG_WIDTH-1];
    reg [DATA_WIDTH-1:0] line_ram_2 [0:IMG_WIDTH-1];
    
    // Read Pointers (Counters to know which pixel to read/write)
    reg [$clog2(IMG_WIDTH)-1:0] wr_ptr;
    
    // Output Registers to keep signals stable
    reg [DATA_WIDTH-1:0] r_dout_1;
    reg [DATA_WIDTH-1:0] r_dout_2;
    reg [DATA_WIDTH-1:0] r_dout_3;

    // =========================================================================
    // Logic
    // =========================================================================
    always @(posedge clk) begin
        if (rst) begin
            wr_ptr <= 0;
            r_dout_1 <= 0;
            r_dout_2 <= 0;
            r_dout_3 <= 0;
        end 
        else if (ce) begin
            // 1. READ old data from the buffers (before overwriting it)
            // This retrieves the pixel from the SAME column but previous rows
            r_dout_1 <= line_ram_0[wr_ptr];
            r_dout_2 <= line_ram_1[wr_ptr];
            r_dout_3 <= line_ram_2[wr_ptr];
            
            // 2. WRITE new data into the buffers
            // The input 'din' goes into Buffer 0
            // The output of Buffer 0 goes into Buffer 1 (Cascading)
            line_ram_0[wr_ptr] <= din;
            line_ram_1[wr_ptr] <= r_dout_1; // Shift row 1 down to row 2
            line_ram_2[wr_ptr] <= r_dout_2; // Shift row 2 down to row 3
            
            // 3. Increment Pointer (Circular Buffer)
            if (wr_ptr == IMG_WIDTH - 1)
                wr_ptr <= 0;
            else
                wr_ptr <= wr_ptr + 1;
        end
    end

    // Direct assignment for the current row (No delay needed)
    assign dout_0 = din;
    
    // Assign stored values to outputs
    assign dout_1 = r_dout_1;
    assign dout_2 = r_dout_2;
    assign dout_3 = r_dout_3;

endmodule