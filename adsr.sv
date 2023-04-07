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
  input logic signed [TOTAL_BITS-1:0] a,
  input logic signed [TOTAL_BITS-1:0] d,
  input logic signed [TOTAL_BITS-1:0] s,
  input logic signed [TOTAL_BITS-1:0] r,
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
  localparam real ARFR = ATTACK_RATIO * FRACTIONAL_MUL;
  localparam real DRFR = DECAY_RATIO * FRACTIONAL_MUL;
  localparam real RRFR= RELEASE_RATIO * FRACTIONAL_MUL;
  localparam fixed ATTACK_RATIO_F  = fixed'(ARFR);
  localparam fixed DECAY_RATIO_F   = fixed'(DRFR);
  localparam fixed RELEASE_RATIO_F = fixed'(RRFR);//0.0001 * 4294967296 //`TO_FIXED(RELEASE_RATIO);
  // Quartus Prime doesn't support synthesis of a call to $ln() even if evaluating a compile-time constant
  //  localparam fixed ATTACK_ALPHA  = fixed'((-$ln ((1.0 + ATTACK_RATIO ) / ATTACK_RATIO )) * (1 << FRACTIONAL_BITS));
  //  localparam fixed DECAY_ALPHA   = fixed'((-$ln ((1.0 + DECAY_RATIO  ) / DECAY_RATIO  )) * (1 << FRACTIONAL_BITS));
  //  localparam fixed RELEASE_ALPHA = fixed'((-$ln ((1.0 + RELEASE_RATIO) / RELEASE_RATIO)) * (1 << FRACTIONAL_BITS));
  //localparam fixed ATTACK_ALPHA  = `TO_FIXED(-1.46633706879);
  localparam real AA = -1.46633706879 * FRACTIONAL_MUL;
  localparam real DA = -9.21044036698 * FRACTIONAL_MUL;
  localparam real RA = -9.21044036698 * FRACTIONAL_MUL;
  localparam fixed ATTACK_ALPHA = fixed'(AA);
  localparam fixed DECAY_ALPHA = fixed'(DA);
  localparam fixed RELEASE_ALPHA = fixed'(RA);

  typedef struct packed {
    fixed a;
    fixed d;
    fixed r;
  } time_values;
  time_values bases_;
  time_values coefs_;

  enum logic [3:0] { // Ensure that states are onehot.
    IDLE    = 4'b0000,
    ATTACK  = 4'b0001,
    DECAY   = 4'b0010,
    SUSTAIN = 4'b0100,
    RELEASE = 4'b1000
  } state_ = IDLE;
  logic gate_ = 1'b0;
  fixed output_;

  fixed attack_x;
  fixed decay_x;
  fixed release_x;

  function mul_type sign_extend (fixed x);
    return { {TOTAL_BITS{x[TOTAL_BITS-1]}}, x[TOTAL_BITS-1:0] };
  endfunction:sign_extend
  /* verilator lint_off UNUSEDSIGNAL */
  function amplitude fixed2amplitude (fixed x);
    return x[FRACTIONAL_BITS-1:FRACTIONAL_BITS-AMPLITUDE_BITS];
  endfunction
  /* verilator lint_on UNUSEDSIGNAL */

  eexp #(.TOTAL_BITS(TOTAL_BITS), .FRACTIONAL_BITS(FRACTIONAL_BITS)) attack_exp  (.x(attack_x ), .out(coefs_.a));
  eexp #(.TOTAL_BITS(TOTAL_BITS), .FRACTIONAL_BITS(FRACTIONAL_BITS)) decay_exp   (.x(decay_x  ), .out(coefs_.d));
  eexp #(.TOTAL_BITS(TOTAL_BITS), .FRACTIONAL_BITS(FRACTIONAL_BITS)) release_exp (.x(release_x), .out(coefs_.r));

  always_comb begin
    attack_x  = `MUL2FIX(sign_extend(ATTACK_ALPHA ) * sign_extend(a));
    decay_x   = `MUL2FIX(sign_extend(DECAY_ALPHA  ) * sign_extend(d));
    release_x = `MUL2FIX(sign_extend(RELEASE_ALPHA) * sign_extend(r));

    active = state_ != IDLE;

    bases_.a = fixed'((sign_extend(one + ATTACK_RATIO_F ) * sign_extend(one - coefs_.a)) >> FRACTIONAL_BITS);
    bases_.d = fixed'((sign_extend(s   - DECAY_RATIO_F  ) * sign_extend(one - coefs_.d)) >> FRACTIONAL_BITS);
    bases_.r = fixed'((sign_extend(0   - RELEASE_RATIO_F) * sign_extend(one - coefs_.r)) >> FRACTIONAL_BITS);
  end

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      state_ <= IDLE;
      output_ <= fixed'(0);
      out <= amplitude'(0);
      gate_ <= 1'b0;
    end else begin
      if (gate != gate_) begin
        gate_ <= gate;
        if (gate) begin
          state_ <= ATTACK;
        end else begin
          if (state_ != IDLE) begin
            state_ <= RELEASE;
          end
        end
      end

      /*unique*/ case (state_)
      ATTACK: begin
        automatic fixed aout = bases_.a + fixed'((sign_extend(output_) * sign_extend(coefs_.a)) >> FRACTIONAL_BITS);
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
        automatic fixed dout = bases_.d + fixed'((sign_extend(output_) * sign_extend(coefs_.d)) >> FRACTIONAL_BITS);
        if (dout <= s) begin
          output_ <= s;
          out <= fixed2amplitude(s);
          state_ <= SUSTAIN;
        end else begin
          output_ <= dout;
          out <= fixed2amplitude(dout);
        end
      end

      RELEASE: begin
        automatic fixed rout = bases_.r + fixed'((mul_type'(output_) * coefs_.r) >> FRACTIONAL_BITS);
        if (rout <= fixed'(0) || fixed2amplitude(rout) == 0) begin
          output_ <= fixed'(0);
          out <= amplitude'(0);
          state_ <= IDLE;
        end else begin
          output_ <= rout;
          out <= fixed2amplitude(rout);
        end
      end

      IDLE: begin end
      SUSTAIN: begin end

      endcase
    end
  end

endmodule:adsr
