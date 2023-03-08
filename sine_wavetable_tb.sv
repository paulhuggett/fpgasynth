`timescale 1 ps / 1 ps
module sine_wavetable_tb ();

  reg [7:0] address = 0;
  logic [31:0] value; // Output from DUT is wire type

  initial begin
    $display($time, " << Starting Simulation >>");
    address = 8'b0;

    #5120;
    $display($time, " << Simulation Complete >>");
    $stop;
  end
   
  always begin
    address = address + 1;
  end

  // Instantiate the DUT.
  sine_wavetable wt (.phase(address), .q(value));

endmodule
