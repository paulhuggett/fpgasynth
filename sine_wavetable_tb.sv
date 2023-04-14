`timescale 1 ps / 1 ps
import mypackage::phase_index_type;
import mypackage::PHASE_INDEX_BITS;
import mypackage::PHASE_ACCUMULATOR_FRACTIONAL_BITS;
import mypackage::amplitude;

module sine_wavetable_tb ();
  localparam INT_FIRST = PHASE_INDEX_BITS;
  localparam INT_LAST = PHASE_ACCUMULATOR_FRACTIONAL_BITS;
  logic clock = 0;
  phase_index_type phase = 0;
  amplitude value; // Output from DUT is wire type

  initial begin
    $monitor("[%0t] %x", $time, value);
    $display($time, " << Starting Simulation >>");
    #1000;
    $display($time, " << Simulation Complete >>");
    $finish;
  end
   
  initial forever #1 clock = ~clock;

  always_ff @(posedge clock) begin
    // +1 here to add 0.5 to the phase on each clock edge.
    phase[INT_FIRST-1:INT_LAST+1] <= phase[INT_FIRST-1:INT_LAST+1] + 1'b1;
  end

  // Instantiate the DUT.
  sine_wavetable wt (.clock(clock), .phase(phase), .q(value));

endmodule
