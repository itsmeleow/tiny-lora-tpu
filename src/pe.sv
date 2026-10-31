/*
 * Single FP8 Multiply-Accumulate (MAC) unit with FP32 accumulation.
 * acc_out = acc_in + (row_in * weight_in)
 */

module pe #(
    parameter DATA_WIDTH = 8,
    parameter ACC_WIDTH  = 32
) (
    input  logic clk,
    input  logic rst_n,

    // control signals
    input  logic step_en,
    input  logic in_valid,
    output logic out_valid,
    input  logic weight_load,

    // weight-stationary (WS) approach so weight held in PE
    input  logic [DATA_WIDTH-1:0] weight_in,

    // input stream: left -> right
    input  logic [DATA_WIDTH-1:0] row_in,
    output logic [DATA_WIDTH-1:0] row_out,

    // partial-sum accumulation stream: top -> bottom
    input  logic [ACC_WIDTH-1:0]  acc_in,
    output logic [ACC_WIDTH-1:0]  acc_out
);

    logic [31:0] product;
    logic [7:0]  weight_reg;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            weight_reg <= 8'd0;
        else if (weight_load)
            weight_reg <= weight_in;
    end
    

    // calculate product = (row_in * weight_reg)
    fp8_mul fp8_mul_inst (
        .fp8_a(row_in),
        .fp8_b(weight_reg),
        .fp32_res(product)
    );

    // calculate acc_out = acc_in + product
    /*
     * fp32_add fp32_add_inst ()
     */


    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            row_out     <= 8'd0;
            product_out <= 32'd0;
            out_valid   <= 1'b0;
        end else if (step_en) begin
            out_valid <= in_valid;
            if (in_valid) begin
                row_out     <= row_in;
                product_out <= product;
            end
        end
    end
endmodule
