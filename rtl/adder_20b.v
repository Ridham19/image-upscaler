`timescale 1ns / 1ps

// A simple 20-bit structural adder
module adder_20b (
    input  wire [19:0] a,
    input  wire [19:0] b,
    output wire [19:0] sum
);
    // In a true gate-level design, this would be a chain of Full Adders.
    // For RTL Structural modeling, letting the synthesizer infer the adder block 
    // inside a dedicated module is the industry standard.
    assign sum = a + b;
    
endmodule