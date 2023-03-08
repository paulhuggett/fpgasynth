// (uinteger_t<N> is an unsigned integer of at least N bits; sinteger_t<N> is 
// a signed integer of at least N bits.)
//
// template <std::size_t input_bits = 16, std::size_t ratio_fractional_bits = 8>
// constexpr uinteger_t<input_bits> lerp (uinteger_t<input_bits> const hi,
//                                        uinteger_t<input_bits> const lo,
//                                        uinteger_t<ratio_fractional_bits> const ratio) {
//   constexpr std::size_t i1 = input_bits + 1U;
//   sinteger_t<i1> shi = hi;
//   sinteger_t<i1> slo = lo;
//
//   // Qx.0-Qx.0=Qx.0
//   sinteger_t<i1> const a = shi - slo;
//   // Qx.0*Q0.r=Qx.r (r=RATIO_FRACTIONAL_BITS)
//   sinteger_t<i1 + ratio_fractional_bits> const b = (sinteger_t<i1 + ratio_fractional_bits>)a * ratio;
//   // Qx.r => Qx.0
//   auto const c = b >> ratio_fractional_bits;
//   // Qx.0+Qx.0=Q(x+1).0 => QUx.0 (truncate to QUx.0)
//   return static_cast<uinteger_t<input_bits>> (c + lo);
// }

module lerp #(
  parameter INPUT_BITS = 16,
  parameter RATIO_FRAC_BITS = 8
)(
  input logic [INPUT_BITS-1:0] ina, // QUx.0 where x=INPUT_BITS
  input logic [INPUT_BITS-1:0] inb, // QUx.0
  input logic [RATIO_FRAC_BITS-1:0] ratio, //QU0.b where b=RATIO_FRACTIONAL_BITS
  output logic [INPUT_BITS-1:0] out // QUx.0
);
  localparam XR = INPUT_BITS + RATIO_FRAC_BITS;
  typedef logic signed [INPUT_BITS:0] sintype;
  typedef logic unsigned [INPUT_BITS-1:0] uintype;
  typedef logic signed [XR:0] qxr;

  always_comb begin
    automatic sintype sina = {1'b0, ina}; // signed version of input A
    automatic sintype sinb = {1'b0, inb}; // signed version of input B
    automatic qxr b = qxr'(sina - sinb) * ratio; // Qx.0*Q0.r=Qx.r (r=RATIO_FRACTIONAL_BITS)
    automatic sintype c = b[XR:RATIO_FRAC_BITS];
    out = uintype'(c + inb); // Qx.0+Qx.0=Q(x+1).0 => QUx.0 (truncate to QUx.0)
  end
  
endmodule:lerp
