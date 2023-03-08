`timescale 1 ps / 1 ps

module ring_buffer_tb();
  localparam unsigned Width = 8; // Each buffered value is WIDTH bits.
  localparam unsigned N = 2; // Buffer holds 2^2 values.
  localparam unsigned ClkPeriod = 2;

  logic rst;
  logic clk;
  logic write_enable;
  logic read_enable;
  logic [Width-1:0] data_in;
  logic [Width-1:0] data_out;
  logic empty;
  logic full;

  ring_buffer #(.WIDTH(Width), .N(N)) dut (.rst, .clk, .write_enable, .read_enable, .data_in, .data_out, .empty, .full);

  initial begin
    $monitor("[%0t]\t write?=%d read?=%d in:%d\t out:%d\t empty?:%d full?:%d [%d %d %d %d]",
                   $time, write_enable, read_enable, data_in, data_out, empty, full, 
                   dut.data[0], dut.data[1], dut.data[2], dut.data[3]);
    clk = 0;
    forever #1 clk = ~clk;
  end

  initial begin
    write_enable = 0; read_enable = 0;

    // Initial reset
    #ClkPeriod rst = 1; write_enable = 1; #ClkPeriod; write_enable = 0;  rst = 0;
    assert (empty && !full && dut.head === 0 && dut.tail === 0);

    // Phase 1: simply fill the buffer then empty it.

    // Write 3, 5, 7, 11 to the buffer.
    #ClkPeriod data_in = 3;  write_enable = 1; #ClkPeriod write_enable = 0;
    assert (!empty && !full && dut.head === 1 && dut.tail === 0);
    assert (dut.data[0] === 3);
    #ClkPeriod data_in = 5;  write_enable = 1; #ClkPeriod write_enable = 0;
    assert (!empty && !full && dut.head === 2 && dut.tail === 0);
    assert (dut.data[0] === 3 && dut.data[1] === 5);
    #ClkPeriod data_in = 7;  write_enable = 1; #ClkPeriod write_enable = 0;
    assert (!empty && !full && dut.head === 3 && dut.tail === 0);
    assert (dut.data[0] === 3 && dut.data[1] === 5 && dut.data[2] === 7);
    #ClkPeriod data_in = 11; write_enable = 1; #ClkPeriod write_enable = 0;
    assert (!empty && full && dut.head === 4 && dut.tail === 0); // check for full.
    assert (dut.data[0] === 3 && dut.data[1] === 5 && dut.data[2] === 7 && dut.data[3] === 11)
      else $display("dut.data[0..3]=[%d %d %d %d]", dut.data[0], dut.data[1],
                                                    dut.data[2], dut.data[3]);

    #ClkPeriod read_enable = 1; #ClkPeriod read_enable = 0;
    assert (data_out === 3 && !empty && !full && dut.head === 4 && dut.tail === 1);
    #ClkPeriod read_enable = 1; #ClkPeriod read_enable = 0;
    assert (data_out === 5 && !empty && !full && dut.head === 4 && dut.tail === 2);
    #ClkPeriod read_enable = 1; #ClkPeriod read_enable = 0;
    assert (data_out === 7 && !empty && !full && dut.head === 4 && dut.tail === 3);
    #ClkPeriod read_enable = 1; #ClkPeriod read_enable = 0;
    assert (data_out === 11 && empty && !full && dut.head === 4 && dut.tail === 4);

    #ClkPeriod
    #ClkPeriod

    // Phase 2: We fill the buffer then alternately remove one item and insert a new one.

    // Write 13, 17, 19, 23 to the buffer.
    #ClkPeriod assert(empty && !full);
    #ClkPeriod data_in = 13; write_enable = 1; 
    #ClkPeriod write_enable = 0;
    #ClkPeriod
    assert (!empty);
    assert (!full);
    #ClkPeriod data_in = 17; write_enable = 1; #ClkPeriod write_enable = 0;
    #ClkPeriod assert(!empty && !full);
    #ClkPeriod data_in = 19; write_enable = 1; #ClkPeriod write_enable = 0;
    #ClkPeriod assert(!empty && !full);
    #ClkPeriod data_in = 23; write_enable = 1; #ClkPeriod write_enable = 0;
    #ClkPeriod assert(!empty && full) else
      $display("after push 23, buffer should be !empty and full");

    // Read 13 then write 29. Buffer should remain full afterwards.
    #ClkPeriod read_enable = 1; #ClkPeriod read_enable = 0;
    assert (data_out === 13 && !empty && !full) else
      $display("After pop, expected data_out=13, !empty, and !full");
    #ClkPeriod data_in = 29; write_enable = 1; #ClkPeriod write_enable = 0;
    assert (!empty && full) else
      $display("After push of 29, expected !empty && full");
    // As above, read 17 then write 31. Buffer should still be full.
    #ClkPeriod read_enable = 1; #ClkPeriod read_enable = 0;
    assert (data_out === 17 && !empty && !full) else
      $display("After pop, expected data_out=17, !empty and !full");
    #ClkPeriod data_in = 31; write_enable = 1; #ClkPeriod write_enable = 0;
    assert (!empty && full) else
      $display("After push of 31, expected !empty && full");
    // Third time: read (19) and write (37).
    #ClkPeriod read_enable = 1; #ClkPeriod read_enable = 0;
    assert (data_out === 19 && !empty && !full) else
      $display("After pop, expected data_out=19, !empty and !full");
    #ClkPeriod data_in = 37; write_enable = 1; #ClkPeriod write_enable = 0;
    assert (!empty && full) else $display("After push of 37, expected !empty && full");
    // Fourth and final time to cycle through the entire buffer: read (23) and write (41).
    #ClkPeriod read_enable = 1; #ClkPeriod read_enable = 0;
    assert (data_out === 23 && !empty && !full) else
      $display("After pop, expected data_out=23, !empty and !full");
    #ClkPeriod data_in = 41; write_enable = 1; #ClkPeriod write_enable = 0;
    assert (!empty && full) else $display("After push of 41, expected !empty && full");

    #ClkPeriod
    #ClkPeriod
    #ClkPeriod

    $finish;
  end
endmodule:ring_buffer_tb
