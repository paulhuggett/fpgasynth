`timescale 1 ps / 1 ps

import mypackage::amplitude;
import mypackage::AMPLITUDE_BITS;

module adsr_tb ();

  localparam SAMPLE_RATE = 1000;
  localparam TOTAL_BITS = 48;
  localparam FRACTIONAL_BITS = 32;
  localparam MAX = 2.0 ** FRACTIONAL_BITS;

  logic clk = 1'b0;
  logic reset = 1'b0;

  typedef logic signed [TOTAL_BITS-1:0] fixed;
  fixed a;
  fixed d;
  amplitude s;
  fixed r;
  bit gate;
  amplitude out;
  bit active;

  initial forever #1 clk = ~clk;

  function fixed time_value (real x);
    return fixed'((1.0 / (x * SAMPLE_RATE)) * MAX);
  endfunction:time_value

  adsr #(.TOTAL_BITS(TOTAL_BITS), .FRACTIONAL_BITS(FRACTIONAL_BITS)) adsr (
    .clk,
    .reset(reset),
    .attack_time(a),
    .decay_time(d),
    .sustain(s),
    .release_time(r),
    .gate,
    .out,
    .active
  );

  initial begin
    $monitor ("[%0t] active=%d gate=%d out=%x output_=%f", $time, active, gate, out, adsr.output_ / (2.0 ** FRACTIONAL_BITS));

    #1
    reset = 1'b0;
    gate = 1'b0;
    {a, d, s, r} = 0;

    #1 reset = 1'b1;
    #1 reset = 1'b0;
    a = time_value (0.1);
    d = time_value (0.1);
    s = amplitude'(0.5 * (2.0 ** AMPLITUDE_BITS));
    r = time_value (0.1);
    #10
    assert (active == 1'b0);
    assert (out == amplitude'(0));
    // Open the gate.
    gate = 1'b1;
    $display ("0.0s attack");
    #1 assert (active == 1'b1);
    #200 $display("0.1s (100 ticks) decay starts");
    assert (out == ~amplitude'(1'b0));
    #200 $display("0.1s sustain level");
    assert (out == amplitude'(0.5 * (2.0 ** AMPLITUDE_BITS)));
    #100 gate = 1'b0;
    $display("release!");
    assert (out == amplitude'(0.5 * (2.0 ** AMPLITUDE_BITS)));
    #200 $display("0.1s release complete");
    assert (out == amplitude'(0));
    assert (active == 1'b0);
    $finish;
  end

endmodule:adsr_tb
