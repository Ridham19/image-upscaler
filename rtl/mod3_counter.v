`timescale 1ns / 1ps

module mod3_counter (
    input  wire clk,
    input  wire rst,
    input  wire en,
    output wire [1:0] count
);
    wire q0, q1;           // Current state
    wire not_q0, not_q1;   // Inverted state
    wire d0_cnt, d1_cnt;   // Next state (if counting)
    wire d0_next, d1_next; // Final next state (after MUX)

    // 1. Invert the current state
    not inv_q0 (not_q0, q0);
    not inv_q1 (not_q1, q1);

    // 2. Next State Logic (Raw AND gates)
    // D0 = NOT Q1 AND NOT Q0
    and and_d0 (d0_cnt, not_q1, not_q0);
    
    // D1 = NOT Q1 AND Q0
    and and_d1 (d1_cnt, not_q1, q0);

    // 3. Enable Logic (Raw MUX instances)
    // If en=0, feed Q back into D. If en=1, feed new count into D.
    mux2 mux0 (.d0(q0), .d1(d0_cnt), .s(en), .y(d0_next));
    mux2 mux1 (.d1(q1), .d1(d1_cnt), .s(en), .y(d1_next));

    // 4. Physical D-Flip-Flops
    dff ff0 (.clk(clk), .rst(rst), .d(d0_next), .q(q0));
    dff ff1 (.clk(clk), .rst(rst), .d(d1_next), .q(q1));

    // 5. Output Wiring (Bus concatenation is just physical wire bundling)
    assign count = {q1, q0};

endmodule