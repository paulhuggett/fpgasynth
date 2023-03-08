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

  typedef logic signed [INPUT_BITS:0] sintype;
  typedef logic unsigned [INPUT_BITS-1:0] uintype;

  sintype shi;
  assign shi[INPUT_BITS] = 1'b0;
  assign shi[INPUT_BITS-1:0] = ina;
  
  sintype slo;
  assign slo [INPUT_BITS] = 1'b0;
  assign slo [INPUT_BITS-1:0] = inb;
  
  // Qx.0-Qx.0=Qx.0
  sintype a;
  assign a = shi - slo;

  // Qx.0*Q0.r=Qx.r (r=RATIO_FRACTIONAL_BITS)
  typedef logic signed [INPUT_BITS + RATIO_FRAC_BITS:0] qxr;
  qxr b;
  assign b = qxr'(a) * ratio;

  // Qx.r => Qx.0
  sintype c;
  assign c = sintype'(b >>> RATIO_FRAC_BITS);

  // Qx.0+Qx.0=Q(x+1).0 => QUx.0 (truncate to QUx.0)
  assign out = uintype'(c + inb);
endmodule:lerp
