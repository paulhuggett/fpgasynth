// Pulse Density Modulation
`timescale 1 ns / 1 ps
module pdm #(
  parameter NBITS = 16
) (
  input logic clock,
  input logic reset,
  input logic [NBITS-1:0] din,
  output logic dout // 1 bit output.
);

  typedef logic [NBITS-1:0] value_type;
  value_type din_reg;
  value_type error0;
  value_type error1;
  value_type error;

  always_ff @(posedge clock) begin
    din_reg <= din;
    error1 <= error + value_type'(2**NBITS - 1) - din_reg;
    error0 <= error - din_reg;
  end

  always_ff @(posedge clock) begin
    if (reset == 1'b1) begin
      dout <= 1'b0;
      error <= 0;
    end else if (din_reg >= error) begin
      dout <= 1'b1;
      error <= error1;
    end else begin
      dout <= 1'b0;
      error <= error0;
    end
  end
endmodule:pdm
