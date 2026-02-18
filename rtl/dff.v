`timescale 1ns / 1ns

// =========================================================================
// 1. Structural D-Latch (Built purely from NAND gates)
// =========================================================================
module d_latch (
    input  wire d,
    input  wire en,
    output wire q,
    output wire q_n
);
    wire d_n;
    wire s_n, r_n;

    not  g_not   (d_n, d);
    nand g_nand1 (s_n, d, en);
    nand g_nand2 (r_n, d_n, en);
    
    // Cross-coupled NAND gates to hold state
    nand g_nand3 (q, s_n, q_n);
    nand g_nand4 (q_n, r_n, q);
endmodule

// =========================================================================
// 2. Structural Edge-Triggered Master-Slave D-Flip-Flop
// =========================================================================
module dff (
    input  wire clk,
    input  wire rst,
    input  wire d,
    output wire q
);
    wire clk_n;
    wire rst_n;
    wire d_in;
    wire qm, qm_n; // Master outputs
    wire qs_n;     // Slave inverted output

    // Synchronous Reset Logic: D_in = D AND (NOT RST)
    not g_rst_inv (rst_n, rst);
    and g_rst_and (d_in, d, rst_n);

    // Clock Inverter for Master-Slave timing
    not g_clk_inv (clk_n, clk);

    // Master Latch (Transparent when CLK is LOW)
    d_latch master (
        .d(d_in),
        .en(clk_n),
        .q(qm),
        .q_n(qm_n)
    );

    // Slave Latch (Transparent when CLK is HIGH)
    d_latch slave (
        .d(qm),
        .en(clk),
        .q(q),
        .q_n(qs_n)
    );

endmodule