`timescale 1ps / 1ps
import mypackage::frequency;
import mypackage::amplitude;
import mypackage::FREQUENCY_FRACTIONAL_BITS;

module nco_tb();
  logic clock = 0;
  logic reset = 0;
  logic enable;
  frequency f;
  amplitude out;

  nco dut (
    .clock(clock), 
    .reset(reset), 
    .enable(enable), 
    .freq(f), 
    .out(out)
  );

  initial forever #1 clock = ~clock;

  initial begin
    $monitor("[%0t]\t reset=%d f=%d out=%d increment=%d", $time, reset, f, out, dut.increment);
  end

  initial begin
    #2 reset = 1;
    #2 reset = 0;
    enable = 1;
    f = 440 << FREQUENCY_FRACTIONAL_BITS;
    #8 f = 880 << FREQUENCY_FRACTIONAL_BITS;
    #8 $finish;
  end
endmodule:nco_tb
