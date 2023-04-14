`timescale 1 ps / 1 ps

import mypackage::WAVETABLE_N;
import mypackage::AMPLITUDE_BITS;
import mypackage::amplitude;
import mypackage::phase_index_type;
import mypackage::PHASE_ACCUMULATOR_FRACTIONAL_BITS;
import mypackage::PHASE_INDEX_BITS;

module sine_wavetable (
  input logic clock,
  input phase_index_type phase,
  output amplitude q
);

  // Declare the ROM variable
  amplitude rom[0:2**WAVETABLE_N-1];

  // Initialize the ROM with $readmemh.
  initial begin
    $readmemh("../sine.mem", rom);
  end

  amplitude ina;
  amplitude inb;
  logic [PHASE_ACCUMULATOR_FRACTIONAL_BITS-1:0] ratio;

  lerp #(.INPUT_BITS(AMPLITUDE_BITS), .RATIO_FRAC_BITS(PHASE_ACCUMULATOR_FRACTIONAL_BITS)) lerper (
    .a(ina),
    .b(inb),
    .ratio(ratio),
    .out(q)
  );

  always @(posedge clock) begin
    // Extract the whole number part from the phase.
    automatic logic [WAVETABLE_N-1:0] whole = phase[PHASE_INDEX_BITS-1:PHASE_ACCUMULATOR_FRACTIONAL_BITS];
    assert (PHASE_INDEX_BITS - PHASE_ACCUMULATOR_FRACTIONAL_BITS == WAVETABLE_N);

    ina <= rom[whole];        // use just the integer part of phase.
    inb <= rom[whole + 1'b1]; // as above.
    ratio <= phase[PHASE_ACCUMULATOR_FRACTIONAL_BITS-1:0]; // the fractional part of the phase.
  end

endmodule:sine_wavetable
