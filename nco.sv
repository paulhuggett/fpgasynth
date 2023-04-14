`timescale 1 ps / 1 ps

import mypackage::C_FRACTIONAL_BITS;
import mypackage::FREQUENCY_FRACTIONAL_BITS;
import mypackage::PHASE_ACCUMULATOR_FRACTIONAL_BITS;
import mypackage::PHASE_INDEX_BITS;
import mypackage::WAVETABLE_N;
import mypackage::amplitude;
import mypackage::frequency;
import mypackage::phase_index_type;

module nco #(
  parameter unsigned SAMPLE_RATE = 'd192_000 // 192kHz
) (
  input logic clock, // System clock.
  input logic reset,
  input logic enable,
  input frequency freq,
  output amplitude out
);

  // C is derived from f/(S*r) where S is the sample rate and
  // r is the number of entries in the wavetable. Everything but f is constant
  // and we'd like to eliminate the division, so rearrange to get f*(r/S).
  localparam real WAVETABLE_MAX = 2**WAVETABLE_N;
  localparam real FRACTIONAL_MAX = 2**C_FRACTIONAL_BITS;
  // The type of the oscillator's phase accumulator constant.
  typedef logic[C_FRACTIONAL_BITS:0] PAC_type;
  localparam C = PAC_type'((WAVETABLE_MAX / SAMPLE_RATE) * FRACTIONAL_MAX);

  phase_index_type increment;
  phase_index_type phase;

  sine_wavetable wt (.clock(clock), .phase(phase), .q(out));

  assign increment = phase_index_type'(freq) * C;

  always @(posedge clock or posedge reset) begin
    if (reset) begin
      phase <= 0;
    end else if (enable) begin
      phase <= phase + increment;
    end
  end
endmodule:nco
