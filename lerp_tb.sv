// Verilate:
//
// Use this: verilator --Wall --timing --build --cc --exe --main --top-module lerp_tb mypackage.sv lerp_tb.sv lerp.sv && ./obj_dir/Vlerp_tb

`timescale 1 ps / 1 ps

module lerp_tb ();
  logic [15:0] a1;
  logic [15:0] b1;
  logic [7:0] ratio1;
  logic [15:0] out1;

  logic [23:0] a2;
  logic [23:0] b2;
  logic [36:0] ratio2;
  logic [23:0] out2;

  lerp #(.INPUT_BITS(16), .RATIO_FRAC_BITS(8)) dut1 (.a(a1), .b(b1), .ratio(ratio1), .out(out1));
  lerp #(.INPUT_BITS(24), .RATIO_FRAC_BITS(37)) dut2 (.a(a2), .b(b2), .ratio(ratio2), .out(out2));

  initial begin
    $monitor("[%0t]\t a=%X\t b=%X\t ratio1=%X\t out1=%X", $time, a1, b1, ratio1, out1);

    a1 = 16'h0000;
    b1 = 16'hFFFF;
    ratio1 = 8'b00000000; #1 assert (out1 == 16'h0000) else $error("expected 0, got %x", out1);
    #1 ratio1 = 8'b00000001; #1 assert (out1 == 16'b00000000_11111111) else $error("expected 1/256, got %x", out1);
    #1 ratio1 = 8'b00000010; #1 assert (out1 == 16'b00000001_11111111) else $error("expected 1/128, got %x", out1);
    #1 ratio1 = 8'b00000100; #1 assert (out1 == 16'b00000011_11111111) else $error("expected 1/64, got %x", out1);
    #1 ratio1 = 8'b00001000; #1 assert (out1 == 16'b00000111_11111111) else $error("expected 1/32, got %x", out1);
    #1 ratio1 = 8'b00010000; #1 assert (out1 == 16'b00001111_11111111) else $error("expected 1/16, got %x", out1);
    #1 ratio1 = 8'b00100000; #1 assert (out1 == 16'b00011111_11111111) else $error("expected 1/8, got %x", out1);
    #1 ratio1 = 8'b01000000; #1 assert (out1 == 16'b00111111_11111111) else $error("expected 1/4, got %x", out1);
    #1 ratio1 = 8'b10000000; #1 assert (out1 == 16'b01111111_11111111) else $error("expected 1/2, got %x", out1);

    #1
    a1 = 16'hFFFF;
    b1 = 16'h0000;
    ratio1 = 8'b00000000; #1 assert (out1 == 16'hFFFF) else $error("got %x", out1);
    #1 ratio1 = 8'b00000001; #1 assert (out1 == 16'b11111110_11111111) else $error("got %x", out1);
    #1 ratio1 = 8'b00000010; #1 assert (out1 == 16'b11111101_11111111) else $error("got %x", out1);
    #1 ratio1 = 8'b00000100; #1 assert (out1 == 16'b11111011_11111111) else $error("got %x", out1);
    #1 ratio1 = 8'b00001000; #1 assert (out1 == 16'b11110111_11111111) else $error("got %x", out1);
    #1 ratio1 = 8'b00010000; #1 assert (out1 == 16'b11101111_11111111) else $error("got %x", out1);
    #1 ratio1 = 8'b00100000; #1 assert (out1 == 16'b11011111_11111111) else $error("got %x", out1);
    #1 ratio1 = 8'b01000000; #1 assert (out1 == 16'b10111111_11111111) else $error("got %x", out1);
    #1 ratio1 = 8'b10000000; #1 assert (out1 == 16'b01111111_11111111) else $error("got %x", out1);

    $monitor("[%0t]\t a=%X\t b=%X\t [ratio2=%X\t out2=%X]",  $time, a2, b2, ratio2, out2);

    #1
    a2 = 24'h000000;
    b2 = 24'hFFFFFF;
    ratio2 = 37'b0;
    #1 assert (out2 == 24'h000000) else $error("got %x", out2);
    #1 ratio2 = 37'b1; #1 assert (out2 == 24'b0) else $error("got %x", out2);
    #1 ratio2 = {1'b1, 36'b0}; #1 assert (out2 == 24'b01111111_11111111_11111111) else $error("got %x", out2); // 50%
    #1 ratio2 = {2'b01, 35'b0}; #1 assert (out2 == 24'b00111111_11111111_11111111) else $error("got %x", out2); // 25%
    #1 ratio2 = {14'b0, 1'b1, 22'b0}; #1 assert (out2 == 24'h1FF) else $error("got %x", out2);
    #1 ratio2 = {15'b0, 1'b1, 21'b0}; #1 assert (out2 == 24'hFF) else $error("got %x", out2);
    #1 ratio2 = {36'b0, 1'b1}; #1 assert (out2 == 24'b0) else $error ("got %x", out2);
    #1 $finish;
  end
  
 endmodule
