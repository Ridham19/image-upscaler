`timescale 1ns / 1ps

module pixel_clipper (
    input  wire [19:0] in_val,     // 20-bit 2's complement input
    output wire [7:0]  out_pixel   // 8-bit unsigned output (0-255)
);

    // Hardware routing: MSB (bit 19) is the sign bit
    wire is_negative = in_val[19];

    // Hardware shift: Hard-wire the bits shifted by 7 (Divide by 128)
    wire [19:0] shifted = in_val >> 7; 

    // Hardware Multiplexers (MUX)
    // If negative -> Output 0
    // If > 255 -> Output 255
    // Else -> Output the lower 8 bits
    assign out_pixel = (is_negative) ? 8'd0 :
                       (shifted > 20'd255) ? 8'd255 :
                       shifted[7:0];

endmodule