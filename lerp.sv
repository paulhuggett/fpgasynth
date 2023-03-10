// (uinteger_t<N> is an unsigned integer of at least N bits; sinteger_t<N> is 
// a signed integer of at least N bits.)
//
// First the simple version written in C++:
//
//    template <std::size_t input_bits = 16>
//    constexpr uinteger_t<input_bits> lerp2 (uinteger_t<input_bits> const a,
//                                            uinteger_t<input_bits> const b,
//                                            double const ratio) {
//      using sintype = sinteger_t<input_bits + 1U>;
//      return static_cast<uinteger_t<input_bits>> ((sintype{b} - sintype{a}) * ratio + a);
//    }
//
// Next a C++ implementation using a fixed point value for 'ratio':
//
//    template <std::size_t input_bits = 16, std::size_t ratio_fractional_bits = 8>
//    constexpr uinteger_t<input_bits> lerp (uinteger_t<input_bits> const a,
//                                           uinteger_t<input_bits> const b,
//                                           uinteger_t<ratio_fractional_bits> const ratio) {
//      constexpr std::size_t i1 = input_bits + 1U;
//      sinteger_t<i1> sa = a;
//      sinteger_t<i1> sb = b;
//
//      // Qx.0-Qx.0=Qx.0
//      sinteger_t<i1> const diff = sb - sa;
//      // Qx.0*Q0.r=Qx.r (r=RATIO_FRACTIONAL_BITS)
//      sinteger_t<i1 + ratio_fractional_bits> const f = static_cast<sinteger_t<i1 + ratio_fractional_bits>> (diff) * ratio;
//      // Qx.r => Qx.0
//      auto const g = f >> ratio_fractional_bits;
//      // Qx.0+Qx.0=Q(x+1).0 => QUx.0 (truncate to QUx.0)
//      return static_cast<uinteger_t<input_bits>> (g + a);
//    }
`timescale 1 ps / 1 ps

module lerp #(
  parameter INPUT_BITS = 16,
  parameter RATIO_FRAC_BITS = 8
)(
  input logic [INPUT_BITS-1:0] a, // QUx.0 where x=INPUT_BITS
  input logic [INPUT_BITS-1:0] b, // QUx.0
  input logic [RATIO_FRAC_BITS-1:0] ratio, // QU0.r where r=RATIO_FRACTIONAL_BITS
  output logic [INPUT_BITS-1:0] out // QUx.0
);
  localparam XR = INPUT_BITS + RATIO_FRAC_BITS;
  typedef logic signed [INPUT_BITS:0] sinttype;
  typedef logic unsigned [INPUT_BITS-1:0] uinttype;
  typedef logic signed [XR:0] qxr;

  always_comb begin
    automatic sinttype diff = sinttype'({1'b0, b}) - sinttype'({1'b0, a});
    automatic qxr d = qxr'(diff) * ratio; // Qx.0*Q0.r=Qx.r
    automatic sinttype e = d[XR:RATIO_FRAC_BITS]; // Extract the integer part.
    out = uinttype'(e + a); // Qx.0+Qx.0=Q(x+1).0 => QUx.0 (truncate to QUx.0)
  end
  
endmodule:lerp
