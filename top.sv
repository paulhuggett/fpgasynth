`timescale 1 ps / 1 ps

import mypackage::frequency;
import mypackage::amplitude;
import mypackage::FREQUENCY_FRACTIONAL_BITS;
import mypackage::AMPLITUDE_BITS;

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
  //ring_buffer rb (.rst(reset), .clk(fast_clock), .read_enable(audio_clock), .write_enable(fast_clock), .data_in(osc_out), .data_out(rb_out), .empty(rb_empty), .full(rb_full));

	logic reset;
  frequency f;
  amplitude osc_out;

  pll clocks (.areset(reset), .inclk0(CLOCK_50), .c0(audio_clock), .c1(fast_clock), .locked(locked));

  localparam real sample_rate = 192000;
  localparam real attack_time = 0.05;
  localparam real decay_time = 0.2;
  localparam real sustain = 0.8;
  localparam real release_time = 0.2;

  localparam FRACTIONAL_BITS = 32;
  localparam TOTAL_BITS = FRACTIONAL_BITS + 16;
  typedef logic signed [TOTAL_BITS-1:0]  fixed;
  typedef logic [TOTAL_BITS-2:0]  ufixed;

  localparam real FRACTIONAL_MUL = (2.0 ** FRACTIONAL_BITS);
  fixed a = fixed'((1.0 / (attack_time * sample_rate)) * FRACTIONAL_MUL);
  fixed d = fixed'((1.0 / (decay_time * sample_rate)) * FRACTIONAL_MUL);
  amplitude s = amplitude'(24'h800000);// 50%
  fixed r = fixed'((1.0 / (release_time * sample_rate)) * FRACTIONAL_MUL);
  logic active;
  logic gate;
  amplitude eg_out;

  adsr #(.TOTAL_BITS(TOTAL_BITS), .FRACTIONAL_BITS(FRACTIONAL_BITS)) adsr (
    .clk(audio_clock),
    .reset,
    .attack_time(a),
    .decay_time(d),
    .sustain(s),
    .release_time(r),
    .gate,
    .out(eg_out),
    .active
  );
  nco osc1 (.clock(audio_clock), .reset, .enable(active), .freq(f), .out(osc_out));

  logic [AMPLITUDE_BITS*2-1:0] final_out;

  logic dout; // PDM audio out.
  pdm #(.NBITS(AMPLITUDE_BITS)) pdm1 (.clock(CLOCK_50), .reset(reset), .din(final_out[AMPLITUDE_BITS*2-1:AMPLITUDE_BITS]), .dout(dout));

  logic reset_0;
  always @(posedge CLOCK_50) reset_0 <= ~KEY[1];
  always @(posedge CLOCK_50) reset <= reset_0;

  always_comb begin
    gate = ~KEY[0];
    final_out = osc_out * eg_out;
  end

  always @(posedge audio_clock or posedge reset) begin
    if (reset) begin
      f <= 0;
/*    end else if (~KEY[1]) begin
      f <= 22'd880 << FREQUENCY_FRACTIONAL_BITS;
*/
    end else begin
      f <= 22'd440 << FREQUENCY_FRACTIONAL_BITS;
    end
  end

  //assign GPIO[0] = reset;
  assign GPIO[0] = ~KEY[1];
  assign GPIO[1] = CLOCK_50;    // AD2 DIO0
  assign GPIO[2] = fast_clock;  // AD2 DIO1
  assign GPIO[3] = audio_clock; // AD2 DIO2
  assign GPIO[4] = dout;        // AD2 DIO3
  assign GPIO[17] = dout;

  always @(posedge audio_clock) begin
    LED[0] <= active;//(egout >= 48'd1 << 32);//fixed'(1 * (2 ** FRACTIONAL_BITS))) ? 1'b1 : 1'b0;
    LED[1] <= (eg_out >= 24'hE00000);
    LED[2] <= (eg_out >= 24'hC00000);
    LED[3] <= (eg_out >= 24'hA00000);
    LED[4] <= (eg_out >= 24'h800000);
    LED[5] <= (eg_out >= 24'h600000);
    LED[6] <= (eg_out >= 24'h400000);
    LED[7] <= (eg_out >= 24'h200000);
  end
  always @(posedge audio_clock) begin
    GPIO[ 5] <= eg_out[0];//osc_out[0];
    GPIO[ 6] <= eg_out[1];//osc_out[1];
    GPIO[ 7] <= eg_out[2];//osc_out[2];
    GPIO[ 8] <= eg_out[3];//osc_out[3];
    GPIO[ 9] <= eg_out[4];//osc_out[4];
    GPIO[10] <= eg_out[5];//osc_out[5];
    GPIO[11] <= eg_out[6];//osc_out[6];
    GPIO[12] <= eg_out[7];//osc_out[7];
    GPIO[13] <= eg_out[8];//osc_out[8];
    GPIO[14] <= eg_out[9];//osc_out[9];
    GPIO[15] <= eg_out[10];//osc_out[10];
    GPIO[16] <= eg_out[11];//osc_out[11];
  end
endmodule:top
