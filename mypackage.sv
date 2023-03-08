`timescale 1 ps / 1 ps
package mypackage;
  parameter AMPLITUDE_BITS = 16;
  typedef logic[AMPLITUDE_BITS - 1:0] amplitude;

  // UQ25.7
  parameter FREQUENCY_TOTAL_BITS = 22; // 0..32,768Hz
  parameter FREQUENCY_FRACTIONAL_BITS = 7;
  parameter FREQUENCY_INTEGRAL_BITS = FREQUENCY_TOTAL_BITS - FREQUENCY_FRACTIONAL_BITS;

  typedef logic [FREQUENCY_INTEGRAL_BITS-1:-FREQUENCY_FRACTIONAL_BITS]  frequency;
  
  parameter unsigned WAVETABLE_N = 'd11; // 2^N wavetable entries.

  parameter unsigned PHASE_INDEX_BITS = 'd48; // Phase accumulation is performed in a 48-bit integer register.
  typedef logic[PHASE_INDEX_BITS-1:0] phase_index_type;

endpackage:mypackage
