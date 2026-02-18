`timescale 1ns / 1ns

// Structural Submodules
module adder_n #(parameter WIDTH = 8)(input [WIDTH-1:0] a, b, input cin, output [WIDTH-1:0] sum, output cout);
    wire [WIDTH:0] carry; assign carry[0] = cin;
    genvar i;
    generate for (i=0; i<WIDTH; i=i+1) begin : fa_loop
        full_adder fa_inst (.a(a[i]), .b(b[i]), .cin(carry[i]), .sum(sum[i]), .cout(carry[i+1]));
    end endgenerate
    assign cout = carry[WIDTH];
endmodule

module twos_complement #(parameter WIDTH = 8)(input [WIDTH-1:0] in, output [WIDTH-1:0] out);
    wire [WIDTH-1:0] not_in; wire [WIDTH-1:0] ground = {WIDTH{1'b0}}; wire unused;
    genvar i; generate for (i=0; i<WIDTH; i=i+1) begin : inv_loop not g_not (not_in[i], in[i]); end endgenerate
    adder_n #(.WIDTH(WIDTH)) add_1_inst (.a(not_in), .b(ground), .cin(1'b1), .sum(out), .cout(unused));
endmodule

module mux2_n #(parameter WIDTH = 8)(input [WIDTH-1:0] d0, d1, input s, output [WIDTH-1:0] y);
    genvar i; generate for (i=0; i<WIDTH; i=i+1) begin : mux_loop
        mux2 m_inst (.d0(d0[i]), .d1(d1[i]), .s(s), .y(y[i]));
    end endgenerate
endmodule

module mult_8x8 (input [7:0] a, b, output [15:0] p);
    wire [15:0] pp [0:7];
    genvar i, j; generate for (i=0; i<8; i=i+1) begin : pp_row
        for (j=0; j<16; j=j+1) begin : pp_col
            if (j>=i && j<i+8) and g_and (pp[i][j], a[j-i], b[i]);
            else assign pp[i][j] = 1'b0;
        end
    end endgenerate
    wire [15:0] s01, s23, s45, s67, s03, s47; wire un;
    adder_n #(.WIDTH(16)) a01(.a(pp[0]), .b(pp[1]), .cin(1'b0), .sum(s01), .cout(un));
    adder_n #(.WIDTH(16)) a23(.a(pp[2]), .b(pp[3]), .cin(1'b0), .sum(s23), .cout(un));
    adder_n #(.WIDTH(16)) a45(.a(pp[4]), .b(pp[5]), .cin(1'b0), .sum(s45), .cout(un));
    adder_n #(.WIDTH(16)) a67(.a(pp[6]), .b(pp[7]), .cin(1'b0), .sum(s67), .cout(un));
    adder_n #(.WIDTH(16)) a03(.a(s01), .b(s23), .cin(1'b0), .sum(s03), .cout(un));
    adder_n #(.WIDTH(16)) a47(.a(s45), .b(s67), .cin(1'b0), .sum(s47), .cout(un));
    adder_n #(.WIDTH(16)) aF(.a(s03), .b(s47), .cin(1'b0), .sum(p), .cout(un));
endmodule

// MAIN MODULE
module mult_pixel_weight (
    input  wire [7:0]  pixel,      
    input  wire [8:0]  weight,     
    output wire [19:0] result      
);

`ifdef BEHAVIORAL
    // FAST SIMULATION: Standard System Math
    wire is_negative = weight[8];
    wire [7:0] weight_mag = is_negative ? (~weight[7:0] + 1'b1) : weight[7:0];
    wire [15:0] mult_mag = pixel * weight_mag;
    wire [19:0] padded_mag = {4'b0000, mult_mag};
    wire [19:0] negative_result = ~padded_mag + 1'b1;
    assign result = is_negative ? negative_result : padded_mag;

`else
    // GATE-LEVEL: True Structural Array Logic
    wire is_negative = weight[8];
    wire [7:0] neg_weight, weight_mag;
    twos_complement #(.WIDTH(8)) tc_w (.in(weight[7:0]), .out(neg_weight));
    mux2_n #(.WIDTH(8)) mux_w (.d0(weight[7:0]), .d1(neg_weight), .s(is_negative), .y(weight_mag));

    wire [15:0] mult_mag;
    mult_8x8 mult_inst (.a(pixel), .b(weight_mag), .p(mult_mag));
    
    wire [19:0] padded_mag = {1'b0, 1'b0, 1'b0, 1'b0, mult_mag};
    wire [19:0] negative_result;
    
    twos_complement #(.WIDTH(20)) tc_res (.in(padded_mag), .out(negative_result));
    mux2_n #(.WIDTH(20)) mux_final (.d0(padded_mag), .d1(negative_result), .s(is_negative), .y(result));
`endif

endmodule