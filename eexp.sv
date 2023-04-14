`timescale 1 ps / 1 ps

// Computes the first few terms of the Taylor series expansion of e^x:
//     e^x=\sum_{k=0}^{\infty}\frac{x^k}{k!}
// That is:
//     1 + x + \frac{x^2}{2!}+\frac{x^3}{3!}
// Using just the first few terms is sufficient to give us reasonable
// accuracy for values of x that are close to 0.
module eexp #(
  parameter TOTAL_BITS = 32,
  parameter FRACTIONAL_BITS = 16
) (
  input logic signed [TOTAL_BITS-1:0] x,
  output logic signed [TOTAL_BITS-1:0] out
);

  typedef logic signed [TOTAL_BITS - 1:0] value_type;
  typedef logic signed [TOTAL_BITS * 2 - 1:0] mul_type;

  function mul_type sign_extend (value_type y);
    return { {TOTAL_BITS{y[TOTAL_BITS-1]}}, y[TOTAL_BITS-1:0] };
  endfunction:sign_extend

  // At input values less than -2 our approximation is just woefully innacurate.
  localparam min = value_type'(-2.0 * (2.0 ** FRACTIONAL_BITS));

  localparam value_type one               = value_type'(1 * (2 ** FRACTIONAL_BITS));
  localparam value_type one_sixth         = value_type'(1.0 / 6.0 * (2.0 ** FRACTIONAL_BITS)); // 1/3!
  localparam value_type one_twenty_fourth = value_type'(1.0 / 24.0 * (2.0 ** FRACTIONAL_BITS)); // 1/4!

  always_comb begin
    value_type x2, x3, x3a, x4, x4a;
    out = one + x; // y=1+x

    assert (x === {TOTAL_BITS{1'bX}} || x >= min);

    x2 = value_type'((sign_extend(x) * sign_extend(x)) >> FRACTIONAL_BITS); // x2=x^2
    out += x2 >> 1; // y += x2 / 2!

    x3 = value_type'((sign_extend(x2) * sign_extend(x)) >> FRACTIONAL_BITS); // x3 = x^3
    x3a = value_type'((sign_extend(x3) * one_sixth) >> FRACTIONAL_BITS);
    out += x3a;

    x4 = value_type'((sign_extend(x3a) * sign_extend(x)) >> FRACTIONAL_BITS); // x4 = x^4
    x4a = value_type'((sign_extend(x4) * one_twenty_fourth) >> FRACTIONAL_BITS);
    out += x4a;
  end
endmodule:eexp
