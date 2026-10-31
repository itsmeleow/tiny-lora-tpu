/* 
 * Vector Processing Unit (VPU)
 *
 */

module vpu #(
    parameter integer VPU_WIDTH = 32
) (
    input  logic [VPU_WIDTH-1:0] a,
    input  logic [VPU_WIDTH-1:0] b,
    output logic [VPU_WIDTH-1:0] result
);

    // Simple vector addition for now
    assign result = a + b;

endmodule
