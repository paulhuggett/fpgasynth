module ring_buffer #(
  parameter unsigned WIDTH = 16, // The number of bits for each stored value.
  parameter unsigned N = 4 // The buffer holds 2^N values.
) (
  input logic rst,
  input logic clk,
  input logic read_enable,
  input logic write_enable,
  input logic [WIDTH-1:0] data_in,
  output logic [WIDTH-1:0] data_out,
  output logic empty,
  output logic full
);

  localparam unsigned Depth = 2**N;
  localparam unsigned Mask = Depth - 1;

  logic [WIDTH-1:0] data [Depth-1:0];
  logic [N:0] head; // N+1 bits
  logic [N:0] tail;

  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      tail <= 0;
      head <= 0;
      empty <= 1;
      full <= 0;
    end else if (read_enable) begin
      if (!empty) begin
        data_out <= data[tail & Mask];
        tail <= tail + 1'b1;
        empty <= (head === tail + 1'b1);
        full <= 0;
      end
    end else if (write_enable) begin
      if (!full) begin
        data[head & Mask] <= data_in;
        head <= head + 1'b1;
        empty <= 0;
        full <= (head + 1'b1 - tail) >= Depth;
      end
    end
  end
endmodule:ring_buffer
