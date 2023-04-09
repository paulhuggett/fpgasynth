`timescale 1 ps / 1 ps

module mul_tb ();

  typedef logic [6:0] q83;
  q83 q43_in1;
  q83 q43_in2;
  q83 q43_out;
  mul #(.TOTAL_BITS(7), .FRACTIONAL_BITS(3)) mul_q43 (.in1(q43_in1), .in2(q43_in2), .out(q43_out));

  initial begin
    $monitor ("[%t] %x %x %x", $time, q43_in1, q43_in2, q43_out);
    q43_in1 = 7'b0001_100; // 1.5
    q43_in2 = 7'b0010_000; // 2.0
    #1 assert (q43_out == 7'b00011_000); // 3.0
    q43_in1 = 7'b1111_000; // 15.0
    q43_in2 = 7'b0000_100; // 0.5
    #1 assert (q43_out == 7'b0111_100); // 7.5
    q43_in1 = 7'b1111_000; // 15.0
    q43_in2 = 7'b0010_000; // 2.0
    #1 $display ("%x", q43_out); assert (q43_out == 7'b1110_000); // 30.0 % 15
    #1 $finish;
  end
endmodule:mul_tb
