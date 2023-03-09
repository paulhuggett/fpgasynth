// Single Port ROM
import mypackage::WAVETABLE_N;
import mypackage::AMPLITUDE_BITS;
import mypackage::amplitude;


module sine_wavetable (
  input logic clock,
  input logic [WAVETABLE_N-1:0] phase, //TODO: phase_index_type
  output amplitude q
);

  // Declare the ROM variable
  amplitude rom[0:2**WAVETABLE_N-1];

  // Initialize the ROM with $readmemh.
  initial begin
    $readmemh("/media/psf/Home/realwork/fpga/testbench/sine.mem", rom);
  end

  amplitude ina;
  amplitude inb;
  logic [8-1:0] ratio;

  lerp #(.INPUT_BITS(AMPLITUDE_BITS), .RATIO_FRAC_BITS(8)) l (.a(ina), .b(inb), .ratio(ratio), .out(q));

  always @(posedge clock) begin
    ina <= rom[phase];     // use just the integer part of phase.
    inb <= rom[phase + 1]; // as above.
    ratio <= phase;              // shift away the integer part of addr.
  end

endmodule:sine_wavetable
