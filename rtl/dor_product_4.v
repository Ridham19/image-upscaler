`timescale 1ns / 1ps

module dot_product_4 (
    input  wire [7:0]  p0, p1, p2, p3,       // 8-bit Unsigned Pixels
    input  wire [8:0]  w0, w1, w2, w3,       // 9-bit 2's Complement Weights
    output wire [19:0] result                // 20-bit 2's Complement Result
);

    // Multiplier output wires
    wire [19:0] m0, m1, m2, m3;

    // Instantiate 4 Hardware Multipliers
    mult_pixel_weight mul0 (.pixel(p0), .weight(w0), .result(m0));
    mult_pixel_weight mul1 (.pixel(p1), .weight(w1), .result(m1));
    mult_pixel_weight mul2 (.pixel(p2), .weight(w2), .result(m2));
    mult_pixel_weight mul3 (.pixel(p3), .weight(w3), .result(m3));

    // Adder Tree Stage 1 (Parallel Addition)
    wire [19:0] add0_1, add2_3;
    adder_20b adder_stg1_0 (.a(m0), .b(m1), .sum(add0_1));
    adder_20b adder_stg1_1 (.a(m2), .b(m3), .sum(add2_3));

    // Adder Tree Stage 2 (Final Accumulation)
    adder_20b adder_stg2 (.a(add0_1), .b(add2_3), .sum(result));

endmodule