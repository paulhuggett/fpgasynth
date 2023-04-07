`timescale 1 ps / 1 ps

import mypackage::amplitude;

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
  fixed s;
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
    .a,
    .d,
    .s,
    .r,
    .gate,
    .out,
    .active
  );

  initial begin
    $monitor ("[%0t] active=%d gate=%d out=%x", $time, active, gate, out);

    #1
    reset = 1'b0;
    gate = 1'b0;
    {a, d, s, r} = 0;

    #1 reset = 1'b1;
    #1 reset = 1'b0;
    a = time_value (0.1);
    d = time_value (0.1);
    s = fixed'(0.5 * MAX);
    r = time_value (0.1);
    #10 gate = 1'b1;
    #100 $display("0.1s decay starts");
    #100 $display("0.1s sustain level");
    #800 gate = 1'b0;
    #300 $finish;
  end

endmodule:adsr_tb
