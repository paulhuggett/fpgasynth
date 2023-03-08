// Verilate:
//
// Use this: verilator --timing --build --cc --exe --main lerp_tb.sv lerp.sv && ./obj_dir/Vlerp_tb

`timescale 1 ps / 1 ps

import mypackage::PHASE_ACCUMULATOR_FRACTIONAL_BITS;

module lerp_tb ();
  logic [15:0] ina;
  logic [15:0] inb;
  logic [7:0] ratio1;
  logic [PHASE_ACCUMULATOR_FRACTIONAL_BITS-1:0] ratio2;
  logic [15:0] out1;
  logic [15:0] out2;

  initial begin
    $monitor("[%0t]\t ina=%X\t inb=%X\t [ratio1=%X\t out1=%x][ratio2=%X\t out2=%X]", $time, ina, inb, ratio1, out1, ratio2, out2);
  end
 
  lerp #(.INPUT_BITS(16), .RATIO_FRAC_BITS(8)) dut1 (.ina(ina), .inb(inb), .ratio(ratio1), .out(out1));
  lerp #(.INPUT_BITS(16), .RATIO_FRAC_BITS(PHASE_ACCUMULATOR_FRACTIONAL_BITS)) dut2 (.ina(ina), .inb(inb), .ratio(ratio2), .out(out2));

  initial begin
    ina = 16'hFFFF;
    inb = 16'h0000;
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
    ina = 16'h0000;
    inb = 16'hFFFF;
    ratio1 = 8'b00000000; #1 assert (out1 == 16'hFFFF) else $error("got %x", out1);
    #1 ratio1 = 8'b00000001; #1 assert (out1 == 16'b11111110_11111111) else $error("got %x", out1);
    #1 ratio1 = 8'b00000010; #1 assert (out1 == 16'b11111101_11111111) else $error("got %x", out1);
    #1 ratio1 = 8'b00000100; #1 assert (out1 == 16'b11111011_11111111) else $error("got %x", out1);
    #1 ratio1 = 8'b00001000; #1 assert (out1 == 16'b11110111_11111111) else $error("got %x", out1);
    #1 ratio1 = 8'b00010000; #1 assert (out1 == 16'b11101111_11111111) else $error("got %x", out1);
    #1 ratio1 = 8'b00100000; #1 assert (out1 == 16'b11011111_11111111) else $error("got %x", out1);
    #1 ratio1 = 8'b01000000; #1 assert (out1 == 16'b10111111_11111111) else $error("got %x", out1);
    #1 ratio1 = 8'b10000000; #1 assert (out1 == 16'b01111111_11111111) else $error("got %x", out1);

    #1
    ina = 16'hFFFF;
    inb = 16'h0000;
    ratio1 = 0;
    ratio2 = 70'b0;
    #1 assert (out2 == 16'h0000) else $error("got %x", out2);
    
    #1 $stop;
  end
  
 endmodule
