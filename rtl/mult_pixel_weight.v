`timescale 1ns / 1ps

module mult_pixel_weight (
    input  wire [7:0] pixel,      // 8-bit Unsigned Pixel (0-255)
    input  wire [8:0] weight,     // 9-bit 2's Complement Weight
    output wire [19:0] result     // 20-bit 2's Complement Result
);

    // 1. Extract the sign bit (MSB)
    wire is_negative;
    assign is_negative = weight[8];

    // 2. Get the absolute magnitude of the weight
    // If negative, invert and add 1 (2's complement). If positive, keep it.
    wire [7:0] weight_mag;
    assign weight_mag = is_negative ? (~weight[7:0] + 1'b1) : weight[7:0];

    // 3. Pure Unsigned Multiplication (8-bit x 8-bit = 16-bit)
    wire [15:0] mult_mag;
    assign mult_mag = pixel * weight_mag;

    // 4. Pad the 16-bit result to 20-bits (filling with 0s)
    wire [19:0] padded_mag;
    assign padded_mag = {4'b0000, mult_mag};

    // 5. Calculate the negative version of the result
    wire [19:0] negative_result;
    assign negative_result = ~padded_mag + 1'b1;

    // 6. Output MUX: Choose positive or negative result based on original sign bit
    assign result = is_negative ? negative_result : padded_mag;

endmodule