`timescale 1ns / 1ps

module top_upscaler #(
    parameter IMG_W = 384,      // UPDATED RESOLUTION
    parameter IMG_H = 216        
)(
    input  wire        clk,
    input  wire        rst,
    input  wire [23:0] pixel_in,   
    input  wire        input_valid,
    output wire [23:0] pixel_out,  
    output reg         output_valid
);

    reg signed [8:0] coeff_rom [0:11];
    initial begin
        // NOTE: Check this path! Does it match your new GitHub folder location?
        $readmemh("D:/vivado_projects/image_upscale/sim/coeffs.txt", coeff_rom);
        
        // HARDWARE SELF-CHECK: Did the ROM load?
        #1; 
        if (coeff_rom[0] === 9'bx) begin
            $display("\n? FATAL ERROR: coeffs.txt missing or path is wrong in top_upscaler.v!\n");
        end
    end

    reg [1:0] h_phase, v_phase;
    always @(posedge clk) begin
        if (rst) begin
            h_phase <= 0; v_phase <= 0;
        end else if (input_valid) begin
            if (h_phase == 2) h_phase <= 0;
            else h_phase <= h_phase + 1;
        end
    end

    // FIX: Shift on the LAST phase so the data is perfectly ready for Phase 0
    wire shift_enable = input_valid && (h_phase == 2'b10);

    wire [23:0] r0, r1, r2, r3;
    line_buffer #(.DATA_WIDTH(24), .IMG_WIDTH(IMG_W)) lb_inst (
        .clk(clk), .rst(rst), .ce(shift_enable),
        .din(pixel_in), .dout_0(r0), .dout_1(r1), .dout_2(r2), .dout_3(r3)
    );

    reg signed [8:0] h_w0, h_w1, h_w2, h_w3;
    reg signed [8:0] v_w0, v_w1, v_w2, v_w3;
    always @(*) begin
        h_w0 = coeff_rom[{h_phase, 2'b00}]; h_w1 = coeff_rom[{h_phase, 2'b01}];
        h_w2 = coeff_rom[{h_phase, 2'b10}]; h_w3 = coeff_rom[{h_phase, 2'b11}];
        v_w0 = coeff_rom[{v_phase, 2'b00}]; v_w1 = coeff_rom[{v_phase, 2'b01}];
        v_w2 = coeff_rom[{v_phase, 2'b10}]; v_w3 = coeff_rom[{v_phase, 2'b11}]; 
    end

    wire [7:0] out_r, out_g, out_b;
    bicubic_core core_R (.clk(clk), .rst(rst), .shift_window(shift_enable),
        .row0_in(r0[23:16]), .row1_in(r1[23:16]), .row2_in(r2[23:16]), .row3_in(r3[23:16]),
        .h_w0(h_w0), .h_w1(h_w1), .h_w2(h_w2), .h_w3(h_w3), .v_w0(v_w0), .v_w1(v_w1), .v_w2(v_w2), .v_w3(v_w3), .pixel_out(out_r));

    bicubic_core core_G (.clk(clk), .rst(rst), .shift_window(shift_enable),
        .row0_in(r0[15:8]), .row1_in(r1[15:8]), .row2_in(r2[15:8]), .row3_in(r3[15:8]),
        .h_w0(h_w0), .h_w1(h_w1), .h_w2(h_w2), .h_w3(h_w3), .v_w0(v_w0), .v_w1(v_w1), .v_w2(v_w2), .v_w3(v_w3), .pixel_out(out_g));

    bicubic_core core_B (.clk(clk), .rst(rst), .shift_window(shift_enable),
        .row0_in(r0[7:0]), .row1_in(r1[7:0]), .row2_in(r2[7:0]), .row3_in(r3[7:0]),
        .h_w0(h_w0), .h_w1(h_w1), .h_w2(h_w2), .h_w3(h_w3), .v_w0(v_w0), .v_w1(v_w1), .v_w2(v_w2), .v_w3(v_w3), .pixel_out(out_b));

    assign pixel_out = {out_r, out_g, out_b};

    reg [1:0] valid_pipe;
    always @(posedge clk) begin
        if (rst) valid_pipe <= 0;
        else valid_pipe <= {valid_pipe[0], input_valid};
    end
    always @(*) output_valid = valid_pipe[1];

endmodule