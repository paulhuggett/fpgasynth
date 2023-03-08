import mypackage::frequency;
import mypackage::amplitude;
import mypackage::FREQUENCY_FRACTIONAL_BITS;
import mypackage::WAVETABLE_N;
import mypackage::phase_index_type;
import mypackage::PHASE_INDEX_BITS;

module nco #(
  parameter unsigned WIDTH = 16, // The number of bits for each stored value.
  parameter unsigned SAMPLE_RATE = 'd192_000 // 192kHz
) (
  input logic clock, // System clock.
  input logic reset,
  input logic enable,
  input frequency freq,
  output amplitude out
);

  // The number of fractional bits for the constant multiplication factor (C)
  // used by the oscillator's phase accumulator.
  localparam C_FRACTIONAL_BITS = PHASE_INDEX_BITS - FREQUENCY_FRACTIONAL_BITS - WAVETABLE_N;

  // C is derived from f/(S*r) where S is the sample rate and
  // r is the number of entries in the wavetable. Everything but f is constant
  // and we'd like to eliminate the division, so rearrange to get f*(r/S).
  localparam real WAVETABLE_MAX = 2**WAVETABLE_N;
  localparam real FRACTIONAL_MAX = 2**C_FRACTIONAL_BITS;
  // The type of the oscillator's phase accumulator constant.
  typedef logic[C_FRACTIONAL_BITS:0] PAC_type;
  localparam C = PAC_type'((WAVETABLE_MAX / SAMPLE_RATE) * FRACTIONAL_MAX);

  // When multiplying a UQa.b number by a UQc.d number, the result is
  // UQ(a+c).(b+d). For the phase accumulator, a+c should be at least
  // wavetable::N but may be more (we don't care if it overflows); b+d should
  // be as large as possible to maintain precision.
  localparam ACCUMULATOR_FRACTIONAL_BITS = FREQUENCY_FRACTIONAL_BITS + C_FRACTIONAL_BITS;

  phase_index_type increment;
  phase_index_type phase;

  typedef logic [WAVETABLE_N-1:0] address_type;
  address_type addr;

  sine_wavetable wt (.clock(clock), .phase(addr), .q(out));

  assign increment = phase_index_type'(freq) * C;

  always @(posedge clock or posedge reset) begin
    if (reset) begin
      {addr, phase} <= 0;
    end else if (enable) begin
      // TODO: interpolation.
      // The most significant (WAVETABLE_N) bits of the phase accumulator output
      // provide the index into the lookup table.
      addr <= address_type'(phase >> ACCUMULATOR_FRACTIONAL_BITS);
      phase <= phase + increment;
    end
  end
endmodule:nco
