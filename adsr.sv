//*          _         *
//*  __ _ __| |____ _  *
//* / _` / _` (_-< '_| *
//* \__,_\__,_/__/_|   *
//*                    *

// This module implements an analog-like ADSR envelope generator. It is based
// on the techniques described and implemented by Nigel Redmon in his EarLevel
// blog series at <https://www.earlevel.com/main/category/envelope-generators/>.
// This is also mentioned in Will C. Pirkle's book "Designing Software
// Synthesizer Plugins In C++ with Audio DSP" (2nd edition) in the Chapter
// "Envelope Generators and DCA" section 7.5 "Analog EG Emulation".

`timescale 1 ps / 1 ps

import mypackage::amplitude;
import mypackage::AMPLITUDE_BITS;

/* verilator lint_off DECLFILENAME */
module egtimer #(
  parameter TOTAL_BITS = 32,
  parameter FRACTIONAL_BITS = 16,
  parameter real ALPHA = -1.46633706879 // -$ln((1.0+RATIO)/RATIO)
) (
  input logic signed [TOTAL_BITS-1:0] t, // the time as 1/t*S where S is the sample rate.
  input logic signed [TOTAL_BITS-1:0] out, // the current output value
  input logic signed [TOTAL_BITS-1:0] mult,
  output logic signed [TOTAL_BITS-1:0] new_out
);

  typedef logic signed [TOTAL_BITS-1:0]  fixed;
  typedef logic signed [TOTAL_BITS*2-1:0]  mul_type;

  localparam fixed one = ((fixed'(1) << FRACTIONAL_BITS) - fixed'(1));
  localparam real FRACTIONAL_MUL = 2.0 ** FRACTIONAL_BITS;
  localparam fixed ALPHA_F = fixed'(ALPHA * FRACTIONAL_MUL);

  fixed coef;
  fixed x;
  fixed mout;
  fixed base;

  // The flow of values here is:
  // t(ime) -> x -> coef -> base
  muls #(.TOTAL_BITS(TOTAL_BITS), .FRACTIONAL_BITS(FRACTIONAL_BITS)) mx (.in1(ALPHA_F), .in2(t), .out(x));
  muls #(.TOTAL_BITS(TOTAL_BITS), .FRACTIONAL_BITS(FRACTIONAL_BITS)) ma (.in1(out), .in2(coef), .out(mout));
  eexp #(.TOTAL_BITS(TOTAL_BITS), .FRACTIONAL_BITS(FRACTIONAL_BITS)) exp (.x(x), .out(coef));
  muls #(.TOTAL_BITS(TOTAL_BITS), .FRACTIONAL_BITS(FRACTIONAL_BITS)) mb (.in1(mult), .in2(one - coef), .out(base));

  always_comb new_out = base + mout;

endmodule:egtimer

// The Attack, Decay, and Release times are expressed as 1/t*S where S is the sample rate.
module adsr #(
  parameter TOTAL_BITS = 32,
  parameter FRACTIONAL_BITS = 16
) (
  input logic clk,
  input logic reset,
  input logic signed [TOTAL_BITS-1:0] attack_time,
  input logic signed [TOTAL_BITS-1:0] decay_time,
  input amplitude sustain,
  input logic signed [TOTAL_BITS-1:0] release_time,
  input logic gate,
  output amplitude out,
  output logic active
);

  typedef logic signed [TOTAL_BITS-1:0]    fixed;
  typedef logic signed [TOTAL_BITS*2-1:0]  mul_type;

  `define REAL2FIX(x) (fixed'((x) * FRACTIONAL_MUL))

  // 'one' is actually the value that is just less than one!
  localparam fixed one = ((fixed'(1) << FRACTIONAL_BITS) - fixed'(1));

  localparam real FRACTIONAL_MUL = 2.0 ** FRACTIONAL_BITS;

  localparam real ATTACK_RATIO  = 0.3;
  localparam real DECAY_RATIO   = 0.0001;
  localparam real RELEASE_RATIO = 0.0001;
  localparam fixed ATTACK_RATIO_F  = `REAL2FIX(ATTACK_RATIO);
  localparam fixed DECAY_RATIO_F   = `REAL2FIX(DECAY_RATIO);
  localparam fixed RELEASE_RATIO_F = `REAL2FIX(RELEASE_RATIO);
  // Unfortunately, Quartus Prime doesn't support synthesis of a call to $ln()
  // even if evaluating a compile-time constant
  //  localparam real ATTACK_ALPHA  = -$ln ((1.0 + ATTACK_RATIO ) / ATTACK_RATIO );
  //  localparam real DECAY_ALPHA   = -$ln ((1.0 + DECAY_RATIO  ) / DECAY_RATIO  );
  //  localparam real RELEASE_ALPHA = -$ln ((1.0 + RELEASE_RATIO) / RELEASE_RATIO);
  localparam real ATTACK_ALPHA  = -1.46633706879;
  localparam real DECAY_ALPHA   = -9.21044036698;
  localparam real RELEASE_ALPHA = -9.21044036698;
  struct packed {
    fixed a;
    fixed d;
    fixed r;
  } next_output_;
  enum logic [4:0] { // Ensure that states are onehot.
    IDLE    = 5'b00001,
    ATTACK  = 5'b00010,
    DECAY   = 5'b00100,
    SUSTAIN = 5'b01000,
    RELEASE = 5'b10000
  } state_ = IDLE;
  logic gate_ = 1'b0;
  fixed output_;

  function mul_type sign_extend (fixed x);
    return { {TOTAL_BITS{x[TOTAL_BITS-1]}}, x[TOTAL_BITS-1:0] };
  endfunction:sign_extend
  /* verilator lint_off UNUSEDSIGNAL */
  function amplitude fixed2amplitude (fixed x);
    return x[FRACTIONAL_BITS-1:FRACTIONAL_BITS-AMPLITUDE_BITS];
  endfunction
  /* verilator lint_on UNUSEDSIGNAL */
  function fixed amplitude2fixed (amplitude x);
    return fixed'(x) << (FRACTIONAL_BITS - AMPLITUDE_BITS);
  endfunction:amplitude2fixed

  egtimer #(
    .TOTAL_BITS(TOTAL_BITS),
    .FRACTIONAL_BITS(FRACTIONAL_BITS),
    .ALPHA(ATTACK_ALPHA)
  ) attack_timer (
    attack_time,
    output_,
    one + ATTACK_RATIO_F,
    next_output_.a
  );
  egtimer #(
    .TOTAL_BITS(TOTAL_BITS),
    .FRACTIONAL_BITS(FRACTIONAL_BITS),
    .ALPHA(DECAY_ALPHA)
  ) decay_timer (
    decay_time,
    output_,
    amplitude2fixed(sustain) - DECAY_RATIO_F,
    next_output_.d
  );
  egtimer #(
    .TOTAL_BITS(TOTAL_BITS),
    .FRACTIONAL_BITS(FRACTIONAL_BITS),
    .ALPHA(RELEASE_ALPHA)
  ) release_timer (
    release_time,
    output_,
    0 - RELEASE_RATIO_F,
    next_output_.r
  );

  always_comb begin
    active = state_ != IDLE;
    assert (output_ === {TOTAL_BITS{1'bX}} || output_ < `REAL2FIX(1.0)) else $error("output=%x", output_);
  end

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      output_ <= fixed'(0);
      out <= amplitude'(0);
      state_ <= IDLE;
      gate_ <= 1'b0;
    end else begin
      if (gate != gate_) begin
        gate_ <= gate;
        if (gate) begin
          state_ <= ATTACK;
        end else if (state_ != IDLE) begin
          state_ <= RELEASE;
        end
      end

      unique case (state_)
      ATTACK: begin
        if (next_output_.a >= one) begin
          output_ <= one;
          out <= fixed2amplitude(one);
          state_ <= DECAY;
        end else begin
          output_ <= next_output_.a;
          out <= fixed2amplitude(next_output_.a);
        end
      end

      DECAY: begin
        if (next_output_.d <= amplitude2fixed(sustain)) begin
          output_ <= amplitude2fixed(sustain);
          out <= sustain;
          state_ <= SUSTAIN;
        end else begin
          output_ <= next_output_.d;
          out <= fixed2amplitude(next_output_.d);
        end
      end

      RELEASE: begin
        if (next_output_.r <= fixed'(0) || fixed2amplitude(next_output_.r) == amplitude'(0)) begin
          output_ <= fixed'(0);
          out <= amplitude'(0);
          state_ <= IDLE;
        end else begin
          output_ <= next_output_.r;
          out <= fixed2amplitude(next_output_.r);
        end
      end

      default: ;
      endcase
    end
  end

endmodule:adsr
