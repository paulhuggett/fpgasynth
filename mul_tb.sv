`timescale 1 ps / 1 ps

module mul_tb ();

  typedef logic [6:0] qu83;
  typedef logic signed [6:0] qs70;
  qu83 qu43_in1, qu43_in2, qu43_out;
  qs70 qs70_in1, qs70_in2, qs70_out;

  mul #(.TOTAL_BITS(7), .FRACTIONAL_BITS(3)) mul_qu43 (.in1(qu43_in1), .in2(qu43_in2), .out(qu43_out));
  muls #(.TOTAL_BITS(7), .FRACTIONAL_BITS(0)) mul_qs70 (.in1(qs70_in1), .in2(qs70_in2), .out(qs70_out));


  initial begin
    $monitor ("QU4.3: [%0t] %x %x %x", $time, qu43_in1, qu43_in2, qu43_out);
    qu43_in1 = 7'b0001_100; // 1.5
    qu43_in2 = 7'b0010_000; // 2.0
    #1 assert (qu43_out == 7'b0011_000); // 3.0
    qu43_in1 = 7'b1111_000; // 15.0
    qu43_in2 = 7'b0000_100; // 0.5
    #1 assert (qu43_out == 7'b0111_100); // 7.5
    qu43_in1 = 7'b1111_000; // 15.0
    qu43_in2 = 7'b0010_000; // 2.0
    #1 assert (qu43_out == 7'b1110_000); // 30.0 % 15

    $monitor ("QS7.0: [%0t] %b %b %b", $time, qs70_in1, qs70_in2, qs70_out);
    qs70_in1 = 3;
    qs70_in2 = 5;
    #1 assert (qs70_out == 15) else $error("qs_out=%d", qs70_out);
    qs70_in1 = -3;
    qs70_in2 = -5;
    #1 assert (qs70_out == 15) else $error("qs_out=%d", qs70_out);
    qs70_in1 = 3;
    qs70_in2 = -5;
    #1 assert (qs70_out == -15) else $error("qs_out=%d", qs70_out);
    qs70_in1 = -3;
    qs70_in2 = 5;
    #1 assert (qs70_out == -15) else $error("qs_out=%d", qs70_out);
    qs70_in1 = 63;
    qs70_in2 = -1;
    #1 assert (qs70_out == -63) else $error("qs_out=%d", qs70_out);
    qs70_in1 = -32;
    qs70_in2 = 2;
    #1 assert (qs70_out == -64) else $error("qs_out=%d", qs70_out);
    $finish;
  end
endmodule:mul_tb
