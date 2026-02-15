`timescale 1ns / 1ps

module tb_upscaler;

    parameter IMG_W = 128;
    parameter IMG_H = 72;
    parameter SCALE = 3;
    
    reg clk;
    reg rst;
    reg [23:0] pixel_in;
    reg input_valid;
    wire [23:0] pixel_out;
    wire output_valid;

    integer f_in, f_out, scan_res, i, j, k;

    always #5 clk = ~clk;

    top_upscaler #(.IMG_W(IMG_W), .IMG_H(IMG_H)) dut (
        .clk(clk), .rst(rst), .pixel_in(pixel_in), .input_valid(input_valid),
        .pixel_out(pixel_out), .output_valid(output_valid)
    );

    initial f_out = $fopen("D:/vivado_projects/image_upscale/sim/output_image.hex", "w");

    always @(posedge clk) begin
        if (output_valid) begin
            if (^pixel_out === 1'bx) begin
                $fwrite(f_out, "000000\n"); // Force Pipeline XX to Black
            end else begin
                $fwrite(f_out, "%06x\n", pixel_out); // Write 24-bit Hex
            end
        end
    end

    reg [23:0] row_buffer [0:IMG_W-1];
    
    initial begin
        clk = 0; rst = 1; pixel_in = 0; input_valid = 0;
        f_in = $fopen("D:/vivado_projects/image_upscale/sim/input_image.hex", "r");
        #120; rst = 0; #20;

        for (i = 0; i < IMG_H; i = i + 1) begin
            // Progress tracker! Check Tcl Console for this!
            if (i % 10 == 0) $display("Processing Row %0d / %0d...", i, IMG_H);
            
            for (j = 0; j < IMG_W; j = j + 1) scan_res = $fscanf(f_in, "%h\n", row_buffer[j]);

            for (k = 0; k < SCALE; k = k + 1) begin
                for (j = 0; j < IMG_W; j = j + 1) begin
                    repeat (SCALE) begin
                        @(posedge clk);
                        pixel_in <= row_buffer[j];
                        input_valid <= 1;
                    end
                end
                @(posedge clk);
                input_valid <= 0;
            end
        end

        #1000;
        $fclose(f_in);
        $fclose(f_out);
        $display("SUCCESS: Simulation Complete. Output saved!");
        $finish;
    end
endmodule