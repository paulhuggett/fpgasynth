// See https://en.wikipedia.org/wiki/Double_dabble

`timescale 1 ps / 1 ps

module bin2bcd #(
  parameter W = 18 // input width
) (
  input logic [W-1:0] bin,  // binary
  output logic [W+(W-4)/3:0] bcd  // bcd {...,thousands,hundreds,tens,units}
);

  integer i;
  integer j;

  always @(bin) begin
    for (i = 0; i <= W + (W-4)/3; i = i + 1) begin
      bcd[i] = 0;     // zero initialize
    end

    bcd[W-1:0] = bin;                         // initialize with input vector
    for (i = 0; i <= W-4; i = i + 1) begin      // iterate on structure depth
      for (j = 0; j <= i / 3; j = j + 1) begin  // iterate on structure width
        if (bcd[W-i+4*j -: 4] > 4) begin
          bcd[W-i+4*j -: 4] = bcd[W-i+4*j -: 4] + 4'd3; // add 3
        end
      end
    end
  end

endmodule:bin2bcd
