`timescale 1 ps / 1 ps

module adsr_tb ();

  localparam SAMPLE_RATE = 1000;
  localparam TOTAL_BITS = 32;
  localparam FRACTIONAL_BITS = 16;
  localparam MAX = 2 ** FRACTIONAL_BITS;

  logic clock = 1'b0;
  logic reset = 1'b0;

  typedef logic signed [TOTAL_BITS-1:0] fixed;
  fixed a;
  fixed d;
  fixed s;
  fixed r;
  bit gate;
  fixed out;
  bit active;

  initial forever #1 clock = ~clock;

  function logic signed [TOTAL_BITS-1:0] time_value (real x);
    return $rtoi((1.0 / (x * SAMPLE_RATE)) * MAX);
  endfunction:time_value

  adsr #(.TOTAL_BITS(TOTAL_BITS), .FRACTIONAL_BITS(FRACTIONAL_BITS)) adsr (
    .clock(clock),
    .reset(reset),
    .a(a),
    .d(d),
    .s(s),
    .r(r),
    .gate(gate),
    .out(out),
    .active(active)
  );

  initial begin
    $monitor ("[%0t] active=%d out=%f", $time, active, real'(out) / MAX);

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
    #400 gate = 1'b0;
    #500 $finish;
  end
endmodule:adsr_tb
