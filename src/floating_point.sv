/*
 * =========================================
 * FP8 Floating-Point Formats
 *
 * Reference: "FP8 Formats for Deep Learning" (arxiv 2209.05433)
 *
 * FP8 defines two encodings:
 *   E4M3: 1 sign bit, 4 exponent bits, 3 fraction bits.
 *   E5M2: 1 sign bit, 5 exponent bits, 2 fraction bits.
 *
 * The paper recommends:
 *   E4M3 for weights and activations.
 *   E5M2 for gradients.
 *
 * E4M3 bit layout: S EEEE FFF
 *   [7]   : Sign bit (1 = negative).
 *   [6:3] : Exponent, stored with a bias of 7.
 *   [2:0] : Fraction (trailing significand).
 *
 * For normal finite values:
 *   value = (-1)^S * 2^(E - 7) * (1 + F/8)
 *
 * The implied leading 1 is not stored in the fraction field.
 *
 * Minimum positive normal value: 2^-6
 * Maximum positive finite value: 448
 * 
 * =========================================
 *
 * FP32 Floating-Point Format (IEEE-754 binary32)
 *
 * FP32 consists of:
 *   1 sign bit, 8 exponent bits, and 23 fraction bits.
 *
 * Bit layout: S EEEEEEEE FFFFFFFFFFFFFFFFFFFFFFF
 *   [31]    : Sign bit (1 = negative).
 *   [30:23] : Exponent, stored with a bias of 127.
 *   [22:0]  : Fraction (trailing significand).
 *
 * For normal finite values (1 <= E <= 254):
 *   value = (-1)^S * 2^(E - 127) * (1 + F/2^23)
 *
 * The implied leading 1 is not stored in the fraction field.
 * Normal values therefore have 24 bits of significand precision.
 *
 * Special encodings:
 *   E =   0, F = 0 : Signed zero.
 *   E =   0, F > 0 : Subnormal; no implied leading 1.
 *   E = 255, F = 0 : Signed infinity.
 *   E = 255, F > 0 : NaN (Not a Number).
 *
 * Minimum positive normal value:    2^-126
 * Minimum positive subnormal value: 2^-149
 * Maximum positive finite value:    (2 - 2^-23) * 2^127
 *                                  approximately 3.4028235e38
 * =========================================
 */




/*
 * Multiply two FP8 (E4M3FN) operands and produce an FP32 product.
 */
module fp8_mul (
    input  logic [7:0]  fp8_a,
    input  logic [7:0]  fp8_b,
    output logic [31:0] fp32_res
);
    localparam FP8_BIAS = 7;
    localparam FP32_BIAS = 127;

    logic       sign_bit;
    logic [3:0] exp_a, exp_b;
    logic [2:0] frac_a, frac_b;

    // fraction a and b with hidden leading one restored
    logic [3:0] frac_a_lead, frac_b_lead;
    logic [7:0] frac_product, normalized_product;

    logic signed [9:0]  exp_unbiased;
    logic        [7:0]  exp_fp32;
    logic        [22:0] frac_fp32;

    always_comb begin
        sign_bit = fp8_a[7] ^ fp8_b[7];
        
        exp_a  = fp8_a[6:3];
        exp_b  = fp8_b[6:3];
        frac_a = fp8_a[2:0];
        frac_b = fp8_b[2:0];

        // normal numbers have a hidden 1 while subnormals have a hidden 0
        frac_a_lead = {{exp_a != 4'b0}, frac_a};
        frac_b_lead = {{exp_b != 4'b0}, frac_b};

        frac_product = frac_a_lead * frac_b_lead;

        // initialize defaults
        normalized_product = frac_product;
        exp_unbiased = 10'sd0;
        exp_fp32     = 8'd0;
        frac_fp32    = 23'd0;
        fp32_res     = 32'd0;

        // E4M3FN NaN: exponent = 1111, fraction = 111
        if (((exp_a == 4'hf) && (frac_a == 3'h7) || (exp_a == 4'hf) && (frac_a == 3'h7))) begin
            fp32_res = 32'h7fc0_0000;
        end else if (frac_product == 8'd0) begin
            fp32_res = {sign_bit, 31'd0};
        end else begin
            // subnormals use an effective exponent of 1 - bias
            exp_unbiased = (exp_a == 4'd0)
                         ? (1 - FP8_BIAS)
                         : ($signed({6'b0, exp_a}) - FP8_BIAS);

            exp_unbiased = exp_unbiased + ((exp_b == 4'd0)
                         ? (1 - FP8_BIAS)
                         : ($signed({6'b0, exp_b}) - FP8_BIAS));

            // product has six fractional bits
            // normalizing with the leading 1 at bit 7 requires +1.
            exp_unbiased = exp_unbiased + 10'sd1;

            // shift the leading 1 into bit 7, adjusting the exponent
            for (int i = 0; i < 7; i = i + 1) begin
                if (!normalized_product[7]) begin
                    normalized_product = normalized_product << 1;
                    exp_unbiased = exp_unbiased - 10'sd1;
                end
            end

            // re-bias the exponent and explicitly size it to 8 bits.
            exp_fp32 = 8'($unsigned(exp_unbiased + FP32_BIAS));

            // remove the hidden 1 and pad to 23 fraction bits.
            frac_fp32 = {normalized_product[6:0], 16'b0};

            // combine to form fp32 result
            fp32_res = {sign_bit, exp_fp32, frac_fp32};
        end
    end
endmodule




/*
 * FP32 Addition and Subtraction with exponent alignment and rounding.
 */
module fp32_add (
    input  logic [31:0] fp32_a,
    input  logic [31:0] fp32_b,
    output logic [31:0] fp32_res
);

endmodule




/*
 * FP32 Multiplication
 */
module fp32_mul (
    input  logic [31:0] fp32_a,
    input  logic [31:0] fp32_b,
    output logic [31:0] fp32_res
);

endmodule




/*
 * FP32 to FP8 Conversion
 */
module fp32_to_fp8 (
    input  logic [31:0] fp32_in,
    output logic [7:0]  fp8_out
);

endmodule




/*
 * FP8 to FP32 Conversion
 */
module fp8_to_fp32 (
    input  logic [7:0]  fp8_in,
    output logic [31:0] fp32_out
);
endmodule
