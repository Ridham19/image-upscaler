`timescale 1ns / 1ns

// Structural Submodules
module reg_en #(parameter WIDTH = 8)(input clk, rst, en, input [WIDTH-1:0] d, output [WIDTH-1:0] q);
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : bit_loop
            wire d_next;
            mux2 m (.d0(q[i]), .d1(d[i]), .s(en), .y(d_next));
            dff  f (.clk(clk), .rst(rst), .d(d_next), .q(q[i]));
        end
    endgenerate
endmodule

module row_shift_register #(parameter DATA_WIDTH = 24, parameter IMG_WIDTH = 384)(
    input clk, rst, ce, input [DATA_WIDTH-1:0] din, output [DATA_WIDTH-1:0] dout
);
    wire [DATA_WIDTH-1:0] tap [0:IMG_WIDTH];
    assign tap[0] = din;
    genvar i;
    generate
        for (i = 0; i < IMG_WIDTH; i = i + 1) begin : shift_loop
            reg_en #(.WIDTH(DATA_WIDTH)) r_inst (.clk(clk), .rst(rst), .en(ce), .d(tap[i]), .q(tap[i+1]));
        end
    endgenerate
    assign dout = tap[IMG_WIDTH];
endmodule

// MAIN MODULE
module line_buffer #(
    parameter DATA_WIDTH = 8,
    parameter IMG_WIDTH  = 128
)(
    input  wire                   clk, rst, ce,
    input  wire [DATA_WIDTH-1:0]  din,
    output wire [DATA_WIDTH-1:0]  dout_0, dout_1, dout_2, dout_3
);

`ifdef BEHAVIORAL
    // FAST SIMULATION: Behavioral RAM
    reg [DATA_WIDTH-1:0] line_ram_0 [0:IMG_WIDTH-1];
    reg [DATA_WIDTH-1:0] line_ram_1 [0:IMG_WIDTH-1];
    reg [DATA_WIDTH-1:0] line_ram_2 [0:IMG_WIDTH-1];
    reg [$clog2(IMG_WIDTH)-1:0] wr_ptr;
    
    reg [DATA_WIDTH-1:0] r_dout_1, r_dout_2, r_dout_3;

    always @(posedge clk) begin
        if (rst) begin
            wr_ptr <= 0; r_dout_1 <= 0; r_dout_2 <= 0; r_dout_3 <= 0;
        end else if (ce) begin
            r_dout_1 <= line_ram_0[wr_ptr];
            r_dout_2 <= line_ram_1[wr_ptr];
            r_dout_3 <= line_ram_2[wr_ptr];
            
            line_ram_0[wr_ptr] <= din;
            line_ram_1[wr_ptr] <= r_dout_1; 
            line_ram_2[wr_ptr] <= r_dout_2; 
            
            if (wr_ptr == IMG_WIDTH - 1) wr_ptr <= 0;
            else wr_ptr <= wr_ptr + 1;
        end
    end
    assign dout_0 = din;
    assign dout_1 = r_dout_1;
    assign dout_2 = r_dout_2;
    assign dout_3 = r_dout_3;

`else
    // GATE-LEVEL: Structural Delay Lines
    assign dout_0 = din;
    row_shift_register #(.DATA_WIDTH(DATA_WIDTH), .IMG_WIDTH(IMG_WIDTH)) row1 (.clk(clk), .rst(rst), .ce(ce), .din(dout_0), .dout(dout_1));
    row_shift_register #(.DATA_WIDTH(DATA_WIDTH), .IMG_WIDTH(IMG_WIDTH)) row2 (.clk(clk), .rst(rst), .ce(ce), .din(dout_1), .dout(dout_2));
    row_shift_register #(.DATA_WIDTH(DATA_WIDTH), .IMG_WIDTH(IMG_WIDTH)) row3 (.clk(clk), .rst(rst), .ce(ce), .din(dout_2), .dout(dout_3));
`endif

endmodule