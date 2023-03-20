`timescale 1 ps / 1 ps

typedef logic signed [31:0] fixed;

function fixed to_fixed (input real x);
  return fixed'(x * (2 ** 16));
endfunction:to_fixed

function real to_fp (input fixed x);
  return real'(x) / (2 ** 16);
endfunction:to_fp

module eexp_tb ();
  fixed in;
  fixed out;

  eexp #(.TOTAL_BITS(32), .FRACTIONAL_BITS(16)) eexp (in, out);

  initial begin
    $monitor ("[%0t] in=%f\t out=%f", $time, to_fp(in), to_fp(out));

    #1 in = to_fixed (-1.0);
    #1 assert (to_fp(out) > 0.33 && to_fp(out) < 0.37) else $display("got %f", to_fp(out));

    #1 in = to_fixed (-0.75);
    #1 assert (to_fp(out) > 0.46 && to_fp(out) < 0.48);

    #1 in = to_fixed (-0.5);
    #1 assert (to_fp(out) > 0.60 && to_fp(out) < 0.61);

    #1 in = to_fixed (-0.25);
    #1 assert (to_fp(out) > 0.77 && to_fp(out) < 0.78);

    #1 in = to_fixed(0.0);
    #1 assert (to_fp(out) == 1.0);

    #1 in = to_fixed (0.25);
    #1 assert (to_fp(out) > 1.28 && to_fp(out) < 1.29);

    #1 in = to_fixed (0.5);
    #1 assert (to_fp(out) > 1.64 && to_fp(out) < 1.65);

    #1 in = to_fixed (0.75);
    #1 assert (to_fp(out) > 2.1 && to_fp(out) < 2.2);

    #1 in = to_fixed (1.0);
    #1 assert (to_fp(out) > 2.66 && to_fp(out) < 2.72);

    #1 $finish;
  end
endmodule:eexp_tb
