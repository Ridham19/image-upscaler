`timescale 1ns / 1ns

module pixel_clipper (
    input  wire [19:0] in_val,     
    output wire [7:0]  out_pixel   
);

`ifdef BEHAVIORAL
    wire is_negative = in_val[19];
    wire [19:0] shifted = (in_val + 20'd64) >> 7; 
    assign out_pixel = (is_negative) ? 8'd0 : (shifted > 20'd255) ? 8'd255 : shifted[7:0];

`else
    wire is_negative = in_val[19];
    wire [19:0] add_out;
    wire unused_cout;
    
    // 1. Structural Addition (+64 for rounding)
    adder_n #(.WIDTH(20)) add_64 (
        .a(in_val), .b(20'd64), .cin(1'b0), .sum(add_out), .cout(unused_cout)
    );
    
    // 2. Structural Shift Right by 7 (Physical wire rerouting)
    wire [19:0] shifted;
    assign shifted = {7'b0, add_out[19:7]};
    
    // 3. Structural Comparator (Is shifted > 255?)
    // If any bit from 8 to 19 is 1, the number has exceeded 255. 
    // This synthesizes as a massive OR gate tree.
    wire over_255 = |shifted[19:8];
    
    // 4. MUX tree for clipping limits
    wire [7:0] mux1_out;
    mux2_n #(.WIDTH(8)) mux_over (
        .d0(shifted[7:0]), .d1(8'd255), .s(over_255), .y(mux1_out)
    );
    
    mux2_n #(.WIDTH(8)) mux_neg (
        .d0(mux1_out), .d1(8'd0), .s(is_negative), .y(out_pixel)
    );
`endif

endmodule