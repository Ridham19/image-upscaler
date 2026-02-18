`timescale 1ns / 1ns

module reg_en #(
    parameter WIDTH = 8
)(
    input  wire             clk,
    input  wire             rst,
    input  wire             en,
    input  wire [WIDTH-1:0] d,
    output wire [WIDTH-1:0] q
);
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : bit_loop
            wire d_next;
            // Your custom raw-gate MUX and DFF
            mux2 m (.d0(q[i]), .d1(d[i]), .s(en), .y(d_next));
            dff  f (.clk(clk), .rst(rst), .d(d_next), .q(q[i]));
        end
    endgenerate
endmodule

module row_shift_register #(
    parameter DATA_WIDTH = 24,
    parameter IMG_WIDTH  = 384
)(
    input  wire                  clk,
    input  wire                  rst,
    input  wire                  ce,
    input  wire [DATA_WIDTH-1:0] din,
    output wire [DATA_WIDTH-1:0] dout
);
    // Wire array to connect the Q of one register to the D of the next
    wire [DATA_WIDTH-1:0] tap [0:IMG_WIDTH];

    // Input goes to the first tap
    assign tap[0] = din;

    genvar i;
    generate
        for (i = 0; i < IMG_WIDTH; i = i + 1) begin : shift_loop
            reg_en #(
                .WIDTH(DATA_WIDTH)
            ) r_inst (
                .clk(clk),
                .rst(rst),
                .en(ce),
                .d(tap[i]),       // Connects to previous register
                .q(tap[i+1])      // Outputs to next register
            );
        end
    endgenerate

    // The output is the very last wire in the chain
    assign dout = tap[IMG_WIDTH];

endmodule


module line_buffer #(
    parameter DATA_WIDTH = 8,
    parameter IMG_WIDTH  = 128
)(
    input  wire                   clk,
    input  wire                   rst,
    input  wire                   ce,
    input  wire [DATA_WIDTH-1:0]  din,
    
    output wire [DATA_WIDTH-1:0]  dout_0,
    output wire [DATA_WIDTH-1:0]  dout_1,
    output wire [DATA_WIDTH-1:0]  dout_2,
    output wire [DATA_WIDTH-1:0]  dout_3
);

    // Current Row is a direct wire connection
    assign dout_0 = din;

    // Row 1: Delays 'din' by 1 full image width
    row_shift_register #(
        .DATA_WIDTH(DATA_WIDTH), 
        .IMG_WIDTH(IMG_WIDTH)
    ) row1 (
        .clk(clk), .rst(rst), .ce(ce),
        .din(dout_0), 
        .dout(dout_1)
    );

    // Row 2: Delays Row 1 by another full image width
    row_shift_register #(
        .DATA_WIDTH(DATA_WIDTH), 
        .IMG_WIDTH(IMG_WIDTH)
    ) row2 (
        .clk(clk), .rst(rst), .ce(ce),
        .din(dout_1), 
        .dout(dout_2)
    );

    // Row 3: Delays Row 2 by another full image width
    row_shift_register #(
        .DATA_WIDTH(DATA_WIDTH), 
        .IMG_WIDTH(IMG_WIDTH)
    ) row3 (
        .clk(clk), .rst(rst), .ce(ce),
        .din(dout_2), 
        .dout(dout_3)
    );

endmodule