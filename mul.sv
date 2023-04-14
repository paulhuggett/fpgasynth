`timescale 1 ps / 1 ps

// The rule is  U(a1,b1)*U(a1,b1)=U(2a1, 2b1)
// Default parameters are U(8,8).

module mul #(
  parameter TOTAL_BITS = 16,
  parameter FRACTIONAL_BITS = 8
) (
  input logic [TOTAL_BITS-1:0] in1,
  input logic [TOTAL_BITS-1:0] in2,
  output logic [TOTAL_BITS-1:0] out
);

  localparam WHOLE_BITS = TOTAL_BITS - FRACTIONAL_BITS;

  typedef logic [TOTAL_BITS*2-1:0] intermediate;
/* verilator lint_off UNUSEDSIGNAL */
  intermediate t;
/* verilator lint_on UNUSEDSIGNAL */

  always_comb begin
    t = intermediate'(in1) * in2;
    out = t[TOTAL_BITS*2-WHOLE_BITS-1:FRACTIONAL_BITS];
  end

endmodule:mul

/* verilator lint_off DECLFILENAME */
/* verilator lint_off MULTITOP */
module muls #(
  parameter TOTAL_BITS = 16,
  parameter FRACTIONAL_BITS = 8
) (
  input logic signed [TOTAL_BITS-1:0] in1,
  input logic signed [TOTAL_BITS-1:0] in2,
  output logic signed [TOTAL_BITS-1:0] out // strictly this should be TOTAL_BITS:0
);

  localparam WHOLE_BITS = TOTAL_BITS - FRACTIONAL_BITS;

  typedef logic signed [TOTAL_BITS*2-1:0] intermediate;
/* verilator lint_off UNUSEDSIGNAL */
  intermediate t;
/* verilator lint_on UNUSEDSIGNAL */

  always_comb begin
    t = intermediate'(in1) * in2;
    out = t[TOTAL_BITS*2-WHOLE_BITS-1:FRACTIONAL_BITS];
  end

endmodule:muls
