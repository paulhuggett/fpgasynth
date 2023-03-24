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
  output logic signed [TOTAL_BITS-1:0] out,
  output logic active
);

  typedef logic signed [TOTAL_BITS-1:0]    fixed;
  typedef logic signed [TOTAL_BITS*2-1:0]  mul_type;

  localparam fixed one = fixed'(1) << FRACTIONAL_BITS;
  localparam real FRACTIONAL_MUL = 2.0 ** FRACTIONAL_BITS;
  localparam fixed ATTACK_RATIO_F  = fixed'(ATTACK_RATIO  * FRACTIONAL_MUL);
  localparam fixed DECAY_RATIO_F   = fixed'(DECAY_RATIO   * FRACTIONAL_MUL);
  localparam fixed RELEASE_RATIO_F = fixed'(RELEASE_RATIO * FRACTIONAL_MUL);
  // Quartus Prime doesn't support synthesis of a call to $ln() even if evaluating a compile-time constant!!!
  //  localparam fixed ATTACK_ALPHA  = fixed'((-$ln ((1.0 + ATTACK_RATIO ) / ATTACK_RATIO )) * (1 << FRACTIONAL_BITS));
  //  localparam fixed DECAY_ALPHA   = fixed'((-$ln ((1.0 + DECAY_RATIO  ) / DECAY_RATIO  )) * (1 << FRACTIONAL_BITS));
  //  localparam fixed RELEASE_ALPHA = fixed'((-$ln ((1.0 + RELEASE_RATIO) / RELEASE_RATIO)) * (1 << FRACTIONAL_BITS));
  localparam fixed ATTACK_ALPHA  = fixed'(-1.46633706879 * FRACTIONAL_MUL);
  localparam fixed DECAY_ALPHA = fixed'(-9.21044036698 * FRACTIONAL_MUL);
  localparam fixed RELEASE_ALPHA = fixed'(-9.21044036698 * FRACTIONAL_MUL);

  typedef struct packed {
    fixed a;
    fixed d;
    fixed r;
  } time_values;
  time_values bases_;
  time_values coefs_;

  enum logic [2:0] { IDLE, ATTACK, DECAY, SUSTAIN, RELEASE } state_;
  fixed output_;
  logic gate_;

  function mul_type sign_extend (fixed x);
    return { {TOTAL_BITS{x[TOTAL_BITS-1]}}, x[TOTAL_BITS-1:0] };
  endfunction:sign_extend

  eexp #(.TOTAL_BITS(TOTAL_BITS), .FRACTIONAL_BITS(FRACTIONAL_BITS))
    attack_exp (
      .x(fixed'((sign_extend(ATTACK_ALPHA) * sign_extend(a)) >> FRACTIONAL_BITS)),
      .out(coefs_.a)
  );
  eexp #(.TOTAL_BITS(TOTAL_BITS), .FRACTIONAL_BITS(FRACTIONAL_BITS))
    decay_exp (
      .x(fixed'((sign_extend (DECAY_ALPHA) * sign_extend(d)) >> FRACTIONAL_BITS)),
      .out(coefs_.d)
  );

  eexp #(.TOTAL_BITS(TOTAL_BITS), .FRACTIONAL_BITS(FRACTIONAL_BITS))
    release_exp (
      .x(fixed'((sign_extend(RELEASE_ALPHA) * sign_extend(r)) >> FRACTIONAL_BITS)),
      .out(coefs_.r)
  );

  always_comb begin
    active = state_ != IDLE;
    bases_.a = fixed'((sign_extend(one + ATTACK_RATIO_F ) * sign_extend(one - coefs_.a)) >> FRACTIONAL_BITS);
    bases_.d = fixed'((sign_extend(s   - DECAY_RATIO_F  ) * sign_extend(one - coefs_.d)) >> FRACTIONAL_BITS);
    bases_.r = fixed'((sign_extend(0   - RELEASE_RATIO_F) * sign_extend(one - coefs_.r)) >> FRACTIONAL_BITS);
  end

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      state_ <= IDLE;
      output_ <= 0;
      out <= 0;
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

      case (state_)
      ATTACK: begin
        automatic fixed aout = bases_.a + fixed'((sign_extend(output_) * sign_extend(coefs_.a)) >> FRACTIONAL_BITS);
        if (aout >= one) begin
          output_ <= one;
          out <= one;
          state_ <= DECAY;
        end else begin
          output_ <= aout;
          out <= aout;
        end
      end

      DECAY: begin
        automatic fixed dout = bases_.d + fixed'((sign_extend(output_) * sign_extend(coefs_.d)) >> FRACTIONAL_BITS);
        if (dout <= s) begin
          output_ <= s;
          out <= s;
          state_ <= SUSTAIN;
        end else begin
          output_ <= dout;
          out <= dout;
        end
      end

      RELEASE: begin
        automatic fixed rout = bases_.r + fixed'((mul_type'(output_) * coefs_.r) >> FRACTIONAL_BITS);
        if (rout <= 0) begin
          output_ <= 0;
          out <= 0;
          state_ <= IDLE;
        end else begin
          output_ <= rout;
          out <= rout;
        end
      end

      default: begin
      end
      endcase
    end
  end

endmodule:adsr
