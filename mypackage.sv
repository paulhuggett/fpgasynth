`timescale 1 ps / 1 ps
package mypackage;

/* verilator lint_off UNUSEDPARAM */
  parameter AMPLITUDE_BITS = 24;
  typedef logic[AMPLITUDE_BITS - 1:0] amplitude;

  // UQ25.7
  parameter FREQUENCY_TOTAL_BITS = 22; // 0..32,768Hz
  parameter FREQUENCY_FRACTIONAL_BITS = 7;
  parameter FREQUENCY_INTEGRAL_BITS = FREQUENCY_TOTAL_BITS - FREQUENCY_FRACTIONAL_BITS;

  typedef logic [FREQUENCY_INTEGRAL_BITS-1:-FREQUENCY_FRACTIONAL_BITS]  frequency;
  
  parameter unsigned WAVETABLE_N = 'd11; // 2^N wavetable entries.

  parameter unsigned PHASE_INDEX_BITS = 'd48; // Phase accumulation is performed in a 48-bit integer register.

  // The number of fractional bits for the constant multiplication factor (C)
  // used by the oscillator's phase accumulator.
  localparam C_FRACTIONAL_BITS = PHASE_INDEX_BITS - FREQUENCY_FRACTIONAL_BITS - WAVETABLE_N;
  // When multiplying a UQa.b number by a UQc.d number, the result is
  // UQ(a+c).(b+d). For the phase accumulator, a+c should be at least
  // wavetable::N but may be more (we don't care if it overflows); b+d should
  // be as large as possible to maintain precision.
  parameter PHASE_ACCUMULATOR_FRACTIONAL_BITS = FREQUENCY_FRACTIONAL_BITS + C_FRACTIONAL_BITS;

  // QUa.b where a+b=PHASE_INDEX_BITS and b=PHASE_ACCUMULATOR_FRACTIONAL_BITS.
  typedef logic[PHASE_INDEX_BITS-1:0] phase_index_type;
/* verilator lint_on UNUSEDPARAM */

endpackage:mypackage
