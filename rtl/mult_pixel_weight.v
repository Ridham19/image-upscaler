`timescale 1ns / 1ns

module adder_n #(
    parameter WIDTH = 8
)(
    input  wire [WIDTH-1:0] a,
    input  wire [WIDTH-1:0] b,
    input  wire             cin,
    output wire [WIDTH-1:0] sum,
    output wire             cout
);
    wire [WIDTH:0] carry;
    assign carry[0] = cin;

    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : fa_loop
            full_adder fa_inst (
                .a(a[i]),
                .b(b[i]),
                .cin(carry[i]),
                .sum(sum[i]),
                .cout(carry[i+1])
            );
        end
    endgenerate

    assign cout = carry[WIDTH];
endmodule

module twos_complement #(
    parameter WIDTH = 8
)(
    input  wire [WIDTH-1:0] in,
    output wire [WIDTH-1:0] out
);
    wire [WIDTH-1:0] not_in;
    wire [WIDTH-1:0] ground = {WIDTH{1'b0}}; // Structural array of 0s
    
    // Step 1: Invert all bits using raw NOT gates
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : inv_loop
            not g_not (not_in[i], in[i]);
        end
    endgenerate

    // Step 2: Add 1 (Tie 'b' to 0 and 'cin' to 1)
    wire unused_cout;
    adder_n #(.WIDTH(WIDTH)) add_1_inst (
        .a(not_in),
        .b(ground),
        .cin(1'b1),
        .sum(out),
        .cout(unused_cout)
    );
endmodule

module mux2_n #(
    parameter WIDTH = 8
)(
    input  wire [WIDTH-1:0] d0,
    input  wire [WIDTH-1:0] d1,
    input  wire             s,
    output wire [WIDTH-1:0] y
);
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : mux_loop
            // Uses your raw-gate 2-to-1 MUX
            mux2 m_inst (.d0(d0[i]), .d1(d1[i]), .s(s), .y(y[i]));
        end
    endgenerate
endmodule

module mult_8x8 (
    input  wire [7:0]  a,
    input  wire [7:0]  b,
    output wire [15:0] p
);
    // 8 rows of 16-bit partial products
    wire [15:0] pp [0:7];

    // 1. Generate Partial Products using raw AND gates
    genvar i, j;
    generate
        for (i = 0; i < 8; i = i + 1) begin : pp_row
            for (j = 0; j < 16; j = j + 1) begin : pp_col
                if (j >= i && j < i + 8) begin
                    and g_and (pp[i][j], a[j-i], b[i]);
                end else begin
                    assign pp[i][j] = 1'b0; // Hardwire unused columns to ground
                end
            end
        end
    endgenerate

    // 2. Fast Adder Tree (Balanced summation for lower propagation delay)
    wire [15:0] sum01, sum23, sum45, sum67;
    wire [15:0] sum03, sum47;
    wire unused;

    // Layer 1 Adders
    adder_n #(.WIDTH(16)) add01 (.a(pp[0]), .b(pp[1]), .cin(1'b0), .sum(sum01), .cout(unused));
    adder_n #(.WIDTH(16)) add23 (.a(pp[2]), .b(pp[3]), .cin(1'b0), .sum(sum23), .cout(unused));
    adder_n #(.WIDTH(16)) add45 (.a(pp[4]), .b(pp[5]), .cin(1'b0), .sum(sum45), .cout(unused));
    adder_n #(.WIDTH(16)) add67 (.a(pp[6]), .b(pp[7]), .cin(1'b0), .sum(sum67), .cout(unused));

    // Layer 2 Adders
    adder_n #(.WIDTH(16)) add03 (.a(sum01), .b(sum23), .cin(1'b0), .sum(sum03), .cout(unused));
    adder_n #(.WIDTH(16)) add47 (.a(sum45), .b(sum67), .cin(1'b0), .sum(sum47), .cout(unused));

    // Layer 3 (Final) Adder
    adder_n #(.WIDTH(16)) add_final (.a(sum03), .b(sum47), .cin(1'b0), .sum(p), .cout(unused));

endmodule

module mult_pixel_weight (
    input  wire [7:0]  pixel,      // Unsigned Pixel
    input  wire [8:0]  weight,     // 9-bit 2's Complement Weight
    output wire [19:0] result      // 20-bit 2's Complement Result
);

    // 1. Hardware Routing (MSB is the sign)
    wire is_negative;
    assign is_negative = weight[8];

    // 2. Structural 2's Complement of the Weight
    wire [7:0] neg_weight;
    wire [7:0] weight_mag;
    
    twos_complement #(.WIDTH(8)) tc_w (
        .in(weight[7:0]), 
        .out(neg_weight)
    );

    // MUX to choose Absolute Magnitude
    mux2_n #(.WIDTH(8)) mux_w (
        .d0(weight[7:0]), 
        .d1(neg_weight), 
        .s(is_negative), 
        .y(weight_mag)
    );

    // 3. Pure Structural Array Multiplication
    wire [15:0] mult_mag;
    mult_8x8 mult_inst (
        .a(pixel), 
        .b(weight_mag), 
        .p(mult_mag)
    );

    // 4. Structural Padding (Physical Wire Bundling)
    wire [19:0] padded_mag;
    assign padded_mag = {1'b0, 1'b0, 1'b0, 1'b0, mult_mag};

    // 5. Structural 2's Complement of the Result
    wire [19:0] negative_result;
    twos_complement #(.WIDTH(20)) tc_res (
        .in(padded_mag), 
        .out(negative_result)
    );

    // 6. Final Hardware MUX for Sign Application
    mux2_n #(.WIDTH(20)) mux_final (
        .d0(padded_mag), 
        .d1(negative_result), 
        .s(is_negative), 
        .y(result)
    );

endmodule