`timescale 1ns / 1ns

// Raw Gate-Level 2-to-1 Multiplexer
module mux2 (
    input  wire d0,  // Selected when s == 0
    input  wire d1,  // Selected when s == 1
    input  wire s,   // Select signal (Enable)
    output wire y
);
    wire not_s;
    wire and0_out;
    wire and1_out;

    // Y = (D0 AND NOT S) OR (D1 AND S)
    not g_not (not_s, s);
    and g_and0 (and0_out, d0, not_s);
    and g_and1 (and1_out, d1, s);
    or  g_or   (y, and0_out, and1_out);

endmodule