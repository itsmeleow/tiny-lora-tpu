/*
 * Copyright (c) 2026 Leo Wang (itsmeleow)
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_itsmeleow_tiny_tpu (
    input  logic [7:0] ui_in,    // Dedicated inputs
    output logic [7:0] uo_out,   // Dedicated outputs
    input  logic [7:0] uio_in,   // IOs: Input path
    output logic [7:0] uio_out,  // IOs: Output path
    output logic [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  logic       ena,      // always 1 when the design is powered, so you can ignore it
    input  logic       clk,      // clock
    input  logic       rst_n     // reset_n - low to reset
);
    logic [7:0]  activation_reg;
    logic [7:0]  row_out_unused;
    logic [31:0] product_out;
    logic        product_valid_unused;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            activation_reg <= 8'd0;
        else if (ena && uio_in[1])
            activation_reg <= ui_in;
        end

    pe pe_inst (
    	.clk(clk),
    	.rst_n(rst_n),
    	.step_en(ena && uio_in[2]),
    	.in_valid(1'b1),
    	.out_valid(product_valid_unused),
    	.weight_load(ena && uio_in[0]),
    	.weight_in(ui_in),
    	.row_in(activation_reg),
    	.row_out(row_out_unused),
    	// .acc_in(product_out),
        .acc_out(product_out)
  	);

  	// Read the registered 32-bit result as four bytes, least significant first.
  	always_comb begin
    	case (uio_in[4:3])
      		2'd0: uo_out = product_out[7:0];
      		2'd1: uo_out = product_out[15:8];
        	2'd2: uo_out = product_out[23:16];
            2'd3: uo_out = product_out[31:24];
            default: uo_out = 8'd0;
        endcase
    end

    assign uio_out = 8'd0;
    assign uio_oe  = 8'd0;

    wire _unused = &{uio_in[7:5], row_out_unused, product_valid_unused, 1'b0};
endmodule
