`timescale 1 ps / 1 ps

module bin2bcd_tb ();
  logic [7:0] in8;
  logic [9:0] out8;
  logic [15:0] in16;
  logic [20:0] out16;

  bin2bcd #(.W(8)) bin2bcd8 (in8, out8);
  bin2bcd #(.W(16)) bin2bcd16 (in16, out16);

  initial begin
    $monitor ("[%t]\t %d\t %X", $time, in8, out8);
    in8 = 243; #1 assert (out8 == 10'h243);

    in8 = 0; #1 assert (out8 == 10'h0);
    in8 = 1; #1 assert (out8 == 10'h1);
    in8 = 4; #1 assert (out8 == 10'h4);
    in8 = 5; #1 assert (out8 == 10'h5);
    in8 = 7; #1 assert (out8 == 10'h7);
    in8 = 8; #1 assert (out8 == 10'h8);
    in8 = 9; #1 assert (out8 == 10'h9);
    in8 = 10; #1 assert (out8 == 10'h10);
    in8 = 20; #1 assert (out8 == 10'h20);
    in8 = 90; #1 assert (out8 == 10'h90);
    in8 = 99; #1 assert (out8 == 10'h99);
    in8 = 100; #1 assert (out8 == 10'h100);
    in8 = 200; #1 assert (out8 == 10'h200);
    in8 = 255; #1 assert (out8 == 10'h255);

    $monitor ("[%t]\t %d\t %X", $time, in16, out16);
    in16 = 65244; #1 assert (out16 == 21'h65244);
    in16 = 65535; #1 assert (out16 == 21'h65535);
    #1 $finish;
  end
endmodule:bin2bcd_tb
