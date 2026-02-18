`timescale 1ns / 1ns

module mod3_counter (
    input  wire clk,
    input  wire rst,
    input  wire en,
    output wire [1:0] count
);

`ifdef BEHAVIORAL
    reg [1:0] count_reg;
    always @(posedge clk) begin
        if (rst) count_reg <= 0;
        else if (en) begin
            if (count_reg == 2) count_reg <= 0;
            else count_reg <= count_reg + 1;
        end
    end
    assign count = count_reg;

`else
    wire q0, q1, not_q0, not_q1, d0_cnt, d1_cnt, d0_next, d1_next;

    not inv_q0 (not_q0, q0);
    not inv_q1 (not_q1, q1);

    and and_d0 (d0_cnt, not_q1, not_q0);
    and and_d1 (d1_cnt, not_q1, q0);

    mux2 mux0 (.d0(q0), .d1(d0_cnt), .s(en), .y(d0_next));
    mux2 mux1 (.d0(q1), .d1(d1_cnt), .s(en), .y(d1_next));
    
    dff ff0 (.clk(clk), .rst(rst), .d(d0_next), .q(q0));
    dff ff1 (.clk(clk), .rst(rst), .d(d1_next), .q(q1));

    assign count = {q1, q0};
`endif

endmodule