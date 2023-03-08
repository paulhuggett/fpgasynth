import mypackage::frequency;
import mypackage::amplitude;
import mypackage::FREQUENCY_FRACTIONAL_BITS;

module top(
  input wire CLOCK_50, // connect to the 50MHz crystal
  input logic KEY[1:0], // the two press buttons
  output logic LED[0:7], // connect to the LEDs
  output logic GPIO[17:0] // GPIO_1[0..17] on JP2
);

  logic fast_clock; // 24.576MHz clock
  logic audio_clock; // 192kHz clock
  logic locked;

  //logic rb_empty;
  //logic rb_full;
  //amplitude rb_out;

	logic reset;
  frequency f;
  amplitude osc_out;

  pll clocks (.areset(reset), .inclk0(CLOCK_50), .c0(audio_clock), .c1(fast_clock), .locked(locked));

  always @(posedge CLOCK_50) begin
    reset <= ~KEY[0];
  end

  nco osc1 (
    .clock(audio_clock),
    .reset(reset),
    .enable(1'b1),
    .freq(f),
    .out(osc_out)
  );

  always @(posedge audio_clock or posedge reset) begin
    if (reset) begin
      f <= 0;
    end else if (KEY[1]) begin
      f <= 22'd880 << FREQUENCY_FRACTIONAL_BITS;
    end else begin
      f <= 22'd440 << FREQUENCY_FRACTIONAL_BITS;
    end
  end
   
  //ring_buffer rb (.rst(reset), .clk(fast_clock), .read_enable(audio_clock), .write_enable(fast_clock), .data_in(osc_out), .data_out(rb_out), .empty(rb_empty), .full(rb_full));

  logic dout; // pdm audio out.
  pdm #(.NBITS(16)) pdm1 (.clock(CLOCK_50), .reset(reset), .din(osc_out), .dout(dout));
 
  assign GPIO[0] = reset;
  assign GPIO[1] = CLOCK_50; // AD2 DIO0
  assign GPIO[2] = fast_clock; // AD2 DIO1
  assign GPIO[3] = audio_clock; // AD2 DIO2
  assign GPIO[4] = dout; // AD2 DIO3
  assign GPIO[17] = dout; 
  
  always @(posedge audio_clock) begin
    LED[0] <= osc_out[0];
    LED[1] <= osc_out[1];
    LED[2] <= osc_out[2];
    LED[3] <= osc_out[3];
    LED[4] <= osc_out[4];
    LED[5] <= osc_out[5];
    LED[6] <= osc_out[6];
    LED[7] <= osc_out[7];

    GPIO[ 5] <= osc_out[0];
    GPIO[ 6] <= osc_out[1];
    GPIO[ 7] <= osc_out[2];
    GPIO[ 8] <= osc_out[3];
    GPIO[ 9] <= osc_out[4];
    GPIO[10] <= osc_out[5];
    GPIO[11] <= osc_out[6];
    GPIO[12] <= osc_out[7];
    GPIO[13] <= osc_out[8];
    GPIO[14] <= osc_out[9];
    GPIO[15] <= osc_out[10];
    GPIO[16] <= osc_out[11];
  end
endmodule:top
