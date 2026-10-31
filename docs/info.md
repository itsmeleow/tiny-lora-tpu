# tiny-tpu

A TPU-inspired accelerator targeting small neural network training and inference. Designed around a weight-stationary 2×2 systolic MAC array with FP8 (E4M3FN) operands and FP32 accumulation. Written in SystemVerilog, targeting ASIC implementation in SkyWater’s 130 nm process using the high-density standard-cell library.