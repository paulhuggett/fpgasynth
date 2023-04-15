//*          _         *
//*  __ _ __| |____ _  *
//* / _` / _` (_-< '_| *
//* \__,_\__,_/__/_|   *
//*                    *

`timescale 1 ps / 1 ps

import mypackage::amplitude;
import mypackage::AMPLITUDE_BITS;

module adsr_tb ();

  localparam FRACTIONAL_BITS = 32;
  localparam TOTAL_BITS = FRACTIONAL_BITS + 5;
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

  function fixed time_value (real x, real sample_rate);
    return fixed'((1.0 / (x * sample_rate)) * MAX);
  endfunction:time_value

  adsr #(.TOTAL_BITS(TOTAL_BITS), .FRACTIONAL_BITS(FRACTIONAL_BITS)) adsr (
    .clk,
    .reset,
    .attack_time(a),
    .decay_time(d),
    .sustain(s),
    .release_time(r),
    .gate,
    .out,
    .active
  );

  initial begin
    $monitor ("[%0t] active=%d gate=%d out=%x output_=%.16f (%x)", $time, active, gate, out, adsr.output_  / (2.0**FRACTIONAL_BITS), adsr.output_);
    #1
    reset = 1'b0;
    gate = 1'b0;
    {a, d, s, r} = 0;
    #1 reset = 1'b1;
    #1 reset = 1'b0;
    if (1) begin
      // Set the A, D, and R times to 0.1s at 1kHz sample rate.
      a = time_value (0.1, 1000);
      d = time_value (0.1, 1000);
      s = amplitude'(0.5 * (2.0 ** AMPLITUDE_BITS));
      r = time_value (0.1, 1000);
      #10
      assert (active == 1'b0);
      assert (out == amplitude'(0));
      // Open the gate.
      gate = 1'b1;
      $display ("0.1s attack");
      #1 assert (active == 1'b1);

      // Wait 100 clock cycles (0.1s at 1000Hz sample rate).
      #200 $display("0.1s (100 ticks) decay starts");
      assert (out == ~amplitude'(1'b0));
      #200 $display("0.1s sustain level");
      assert (out == amplitude'(0.5 * (2.0 ** AMPLITUDE_BITS)));

      // 50 clock ticks at sustain then close the gate. This starts the
      // release phase.
      #100 gate = 1'b0;
      $display("release!");
      assert (out == amplitude'(0.5 * (2.0 ** AMPLITUDE_BITS)));
      #200 $display("0.1s release complete");
      assert (out == amplitude'(0));
      assert (active == 1'b0);
    end
    if (1) begin
      // Set the A, D, and R times as short as possible.
      a = time_value (0.0010, 1000);
      d = time_value (0.0050, 1000);
      s = amplitude'(0.5 * (2.0 ** AMPLITUDE_BITS));
      r = time_value (0.0050, 1000);
      gate = 1'b1;
      #10
      gate = 1'b0;
      #5
      assert (out == amplitude'(0));
      assert (active == 1'b0);
    end
    if (1) begin
      a = time_value (0.01, 192000);
      d = time_value (0.01, 192000);
      s = amplitude'(0.75 * (2.0 ** AMPLITUDE_BITS));
      r = time_value (0.01, 192000);
      // Open the gate.
      gate = 1'b1;
      $display ("0.01s attack @192kHz");
      #1 assert (active == 1'b1);
      #3840; //assert (out == ~amplitude'(1'b0)); // start decay
      #3840; //start sustain
      #100 gate = 1'b0;
      #3840 ;//release

//      assert (out == amplitude'(0));
//      assert (active == 1'b0);
    end

    $finish;
  end

endmodule:adsr_tb
