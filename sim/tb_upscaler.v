//`define BEHAVIORAL   // <--- THE MASTER SWITCH! Comment this out to run pure Gate-Level!
`timescale 1ns / 1ns // <--- Fixed timescale for speed

module tb_upscaler;

    parameter IMG_W = 384;   
    parameter IMG_H = 216;
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

    initial begin
        #500;
        $display("\n=======================================================");
        $display(" SIMULATION PAUSED AT 500ns.");
        $display(" Click 'Run All' in the top toolbar to process image!");
        $display("=======================================================\n");
        $stop;
    end

    initial begin
        f_out = $fopen("D:/vivado_projects/image_upscale/sim/output_image.hex", "w");
        if (f_out == 0) $display("\nâ?Œ FATAL ERROR: COULD NOT OPEN output_image.hex FOR WRITING!\n");
    end

    always @(posedge clk) begin
        if (output_valid) begin
            if (^pixel_out === 1'bx) begin
                $fwrite(f_out, "000000\n");
            end else begin
                $fwrite(f_out, "%06x\n", pixel_out);
            end
        end
    end

    reg [23:0] row_buffer [0:IMG_W-1];
    
    initial begin
        clk = 0; rst = 1; pixel_in = 0; input_valid = 0;
        
        f_in = $fopen("D:/vivado_projects/image_upscale/sim/input_image.hex", "r");
        if (f_in == 0) begin
            $display("\n=======================================================");
            $display(" â?Œ FATAL ERROR: COULD NOT OPEN input_image.hex!");
            $display("=======================================================\n");
            $finish; 
        end
        
        #120; rst = 0; #20;

        for (i = 0; i < IMG_H; i = i + 1) begin
            if (i % 10 == 0) $display("Processing Row %0d / %0d...", i, IMG_H);
            for (j = 0; j < IMG_W; j = j + 1) begin
                scan_res = $fscanf(f_in, "%h\n", row_buffer[j]);
                if (scan_res == 0 || scan_res == -1) begin
                    $display("\nâ?Œ FATAL ERROR: Failed to read pixel at Row %0d!", i);
                    $finish;
                end
            end

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
        $display("\n=======================================================");
        $display(" SUCCESS: Simulation Complete. Output saved!");
        $display("=======================================================\n");
        $finish;
    end
endmodule