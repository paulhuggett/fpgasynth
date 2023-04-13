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

module adsr #(
  parameter TOTAL_BITS = 32,
  parameter FRACTIONAL_BITS = 16,
  parameter real ATTACK_RATIO = 0.3,
  parameter real DECAY_RATIO = 0.0001,
  parameter real RELEASE_RATIO = 0.0001
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

  `define TO_FIXED(x) (fixed'((x) * FRACTIONAL_MUL))
  `define MUL2FIX(x) (fixed'((x) >> FRACTIONAL_BITS))

  // 'one' is actually the value that is just less than one!
  localparam fixed one = ((fixed'(1) << FRACTIONAL_BITS) - fixed'(1));

  localparam real FRACTIONAL_MUL = 2.0 ** FRACTIONAL_BITS;
  localparam fixed ATTACK_RATIO_F  = fixed'(ATTACK_RATIO * FRACTIONAL_MUL);
  localparam fixed DECAY_RATIO_F   = fixed'(DECAY_RATIO * FRACTIONAL_MUL);
  localparam fixed RELEASE_RATIO_F = fixed'(RELEASE_RATIO * FRACTIONAL_MUL);
  // Quartus Prime doesn't support synthesis of a call to $ln() even if evaluating a compile-time constant
  //  localparam fixed ATTACK_ALPHA  = fixed'((-$ln ((1.0 + ATTACK_RATIO ) / ATTACK_RATIO )) * (1 << FRACTIONAL_BITS));
  //  localparam fixed DECAY_ALPHA   = fixed'((-$ln ((1.0 + DECAY_RATIO  ) / DECAY_RATIO  )) * (1 << FRACTIONAL_BITS));
  //  localparam fixed RELEASE_ALPHA = fixed'((-$ln ((1.0 + RELEASE_RATIO) / RELEASE_RATIO)) * (1 << FRACTIONAL_BITS));
  localparam fixed ATTACK_ALPHA  = `TO_FIXED(-1.46633706879);
  localparam fixed DECAY_ALPHA   = `TO_FIXED(-9.21044036698);
  localparam fixed RELEASE_ALPHA = `TO_FIXED(-9.21044036698);

  typedef struct packed {
    fixed a;
    fixed d;
    fixed r;
  } time_values;
  time_values bases_;
  time_values coefs_;
  time_values x_;

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

  eexp #(.TOTAL_BITS(TOTAL_BITS), .FRACTIONAL_BITS(FRACTIONAL_BITS)) attack_exp  (.x(x_.a), .out(coefs_.a));
  eexp #(.TOTAL_BITS(TOTAL_BITS), .FRACTIONAL_BITS(FRACTIONAL_BITS)) decay_exp   (.x(x_.d), .out(coefs_.d));
  eexp #(.TOTAL_BITS(TOTAL_BITS), .FRACTIONAL_BITS(FRACTIONAL_BITS)) release_exp (.x(x_.r), .out(coefs_.r));

  logic[TOTAL_BITS-1:0] maout;
  logic[TOTAL_BITS-1:0] mdout;
  logic[TOTAL_BITS-1:0] mrout;
  mul #(.TOTAL_BITS(TOTAL_BITS), .FRACTIONAL_BITS(FRACTIONAL_BITS)) ma (.in1(output_), .in2(coefs_.a), .out(maout));
  mul #(.TOTAL_BITS(TOTAL_BITS), .FRACTIONAL_BITS(FRACTIONAL_BITS)) md (.in1(output_), .in2(coefs_.d), .out(mdout));
  mul #(.TOTAL_BITS(TOTAL_BITS), .FRACTIONAL_BITS(FRACTIONAL_BITS)) mr (.in1(output_), .in2(coefs_.r), .out(mrout));

  // sustain amplitude as a 'fixed'.
  fixed sustain_f;

  always_comb begin
    sustain_f = fixed'(sustain) << (FRACTIONAL_BITS - AMPLITUDE_BITS);

    x_.a = `MUL2FIX(sign_extend(ATTACK_ALPHA ) * sign_extend(attack_time  ));
    x_.d = `MUL2FIX(sign_extend(DECAY_ALPHA  ) * sign_extend(decay_time  ));
    x_.r = `MUL2FIX(sign_extend(RELEASE_ALPHA) * sign_extend(release_time));

    active = state_ != IDLE;

    bases_.a = `MUL2FIX(sign_extend(one       + ATTACK_RATIO_F ) * sign_extend(one - coefs_.a));
    bases_.d = `MUL2FIX(sign_extend(sustain_f - DECAY_RATIO_F  ) * sign_extend(one - coefs_.d));
    bases_.r = `MUL2FIX(sign_extend(0         - RELEASE_RATIO_F) * sign_extend(one - coefs_.r));
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
        automatic fixed aout = bases_.a + maout;
        ///assert (output_ >= 0 && coefs_.a >= 0);
        if (aout >= one) begin
          output_ <= one;
          out <= fixed2amplitude(one);
          state_ <= DECAY;
        end else begin
          output_ <= aout;
          out <= fixed2amplitude(aout);
        end
      end

      DECAY: begin
        automatic fixed dout = bases_.d + mdout;
        if (dout <= sustain_f) begin
          output_ <= sustain_f;
          out <= sustain;
          state_ <= SUSTAIN;
        end else begin
          output_ <= dout;
          out <= fixed2amplitude(dout);
        end
      end

      RELEASE: begin
        automatic fixed rout = bases_.r + mrout;
        if (rout <= fixed'(0) || fixed2amplitude(rout) == 0) begin
          output_ <= fixed'(0);
          out <= fixed2amplitude(fixed'(0));
          state_ <= IDLE;
        end else begin
          output_ <= rout;
          out <= fixed2amplitude(rout);
        end
      end

      default: ;
      endcase
    end
  end

endmodule:adsr
