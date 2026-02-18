`timescale 1ns / 1ns

module full_adder (
    input wire a, b, cin, output wire sum, cout
);
    wire xor_ab, and_ab, and_cin_xor;
    xor g1 (xor_ab, a, b);
    xor g2 (sum, xor_ab, cin);
    and g3 (and_ab, a, b);
    and g4 (and_cin_xor, cin, xor_ab);
    or  g5 (cout, and_ab, and_cin_xor);
endmodule

module adder_20b (
    input  wire [19:0] a,
    input  wire [19:0] b,
    output wire [19:0] sum
);

`ifdef BEHAVIORAL
    assign sum = a + b;
`else
    wire [20:0] carry;
    assign carry[0] = 1'b0;
    genvar i;
    generate
        for (i = 0; i < 20; i = i + 1) begin : fa_loop
            full_adder fa_inst (.a(a[i]), .b(b[i]), .cin(carry[i]), .sum(sum[i]), .cout(carry[i+1]));
        end
    endgenerate
`endif

endmodule