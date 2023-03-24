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
  logic [1:0] key;
  //logic rb_empty;
  //logic rb_full;
  //amplitude rb_out;

	logic reset;
  frequency f;
  amplitude osc_out;

  pll clocks (.areset(reset), .inclk0(CLOCK_50), .c0(audio_clock), .c1(fast_clock), .locked(locked));

  assign key[0] = ~KEY[0];
  assign key[1] = ~KEY[1];

  always @(posedge CLOCK_50) begin
    //reset <= key[0];
    reset <= 0;
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
    end else if (key[1]) begin
      f <= 22'd880 << FREQUENCY_FRACTIONAL_BITS;
    end else begin
      f <= 22'd440 << FREQUENCY_FRACTIONAL_BITS;
    end
  end

  //ring_buffer rb (.rst(reset), .clk(fast_clock), .read_enable(audio_clock), .write_enable(fast_clock), .data_in(osc_out), .data_out(rb_out), .empty(rb_empty), .full(rb_full));

  logic dout; // pdm audio out.
  pdm #(.NBITS(AMPLITUDE_BITS)) pdm1 (.clock(CLOCK_50), .reset(reset), .din(osc_out), .dout(dout));

  //assign GPIO[0] = reset;
  assign GPIO[0] = key[1];
  assign GPIO[1] = CLOCK_50; // AD2 DIO0
  assign GPIO[2] = fast_clock; // AD2 DIO1
  assign GPIO[3] = audio_clock; // AD2 DIO2
  assign GPIO[4] = dout; // AD2 DIO3
  assign GPIO[17] = dout;

  localparam real sample_rate = 192000;
  localparam real attack_time = 0.1;
  localparam real decay_time = 0.1;
  localparam real sustain = 0.8;
  localparam real release_time = 0.5;

  localparam TOTAL_BITS = 48;
  localparam FRACTIONAL_BITS = 32;
  typedef logic signed [TOTAL_BITS-1:0]  fixed;

  localparam real FRACTIONAL_MUL = (2.0 ** FRACTIONAL_BITS);
  fixed a = fixed'((1.0 / (attack_time * sample_rate)) * FRACTIONAL_MUL);//48'd44739;//fixed'((1.0 / (attack_time * sample_rate)) * (2.0 ** FRACTIONAL_BITS))),
  fixed d = fixed'((1.0 / (decay_time * sample_rate)) * FRACTIONAL_MUL);//48'd44739;//fixed'((1.0 / (decay_time * sample_rate)) * (2.0 ** FRACTIONAL_BITS));
  fixed s = fixed'(48'h8000_0000);//sustain * FRACTIONAL_MUL);//48'h4000_0000;
  fixed r = fixed'((1.0 / (release_time * sample_rate)) * FRACTIONAL_MUL);//48'd44739;//fixed'((1.0 / (release_time * sample_rate)) * (2.0 ** FRACTIONAL_BITS));
  logic active;
  logic gate;
  fixed egout;

  adsr #(
    .TOTAL_BITS(TOTAL_BITS),
    .FRACTIONAL_BITS(FRACTIONAL_BITS)
  ) adsr (
    .clk(audio_clock),
    .reset(reset),
    .a(a),
    .d,
    .s,
    .r,
    .gate,
    .out(egout),
    .active
  );
  assign gate = key[0];

  always @(posedge audio_clock) begin
    LED[0] <= (egout >= 48'd1 << 32);//fixed'(1 * (2 ** FRACTIONAL_BITS))) ? 1'b1 : 1'b0;
    LED[1] <= (egout >= 48'hE000_0000);//fixed'(7.0 / 8.0 * FRACTIONAL_MUL)) ? 1'b1 : 1'b0;
    LED[2] <= (egout >= 48'hC000_0000);//fixed'(0.75 * FRACTIONAL_MUL)) ? 1'b1 : 1'b0;
    LED[3] <= (egout >= 48'hA000_0000);//fixed'(0.625 / 8.0 * FRACTIONAL_MUL)) ? 1'b1 : 1'b0;
    LED[4] <= (egout >= 48'h8000_0000);//fixed'(0.5 * FRACTIONAL_MUL)) ? 1'b1 : 1'b0;
    LED[5] <= (egout >= 48'h6000_0000);//fixed'(0.375 * FRACTIONAL_MUL)) ? 1'b1 : 1'b0;
    LED[6] <= (egout >= 48'h4000_0000);//fixed'(0.25 * FRACTIONAL_MUL)) ? 1'b1 : 1'b0;
    LED[7] <= (egout >= 48'h2000_0000);//fixed'(0.125 * FRACTIONAL_MUL)) ? 1'b1 : 1'b0;
  end
  always @(posedge audio_clock) begin
    GPIO[ 5] <= egout[FRACTIONAL_BITS];//osc_out[0];
    GPIO[ 6] <= egout[FRACTIONAL_BITS-1];//osc_out[1];
    GPIO[ 7] <= egout[FRACTIONAL_BITS-2];//osc_out[2];
    GPIO[ 8] <= egout[FRACTIONAL_BITS-3];//osc_out[3];
    GPIO[ 9] <= egout[FRACTIONAL_BITS-4];//osc_out[4];
    GPIO[10] <= egout[FRACTIONAL_BITS-5];//osc_out[5];
    GPIO[11] <= egout[FRACTIONAL_BITS-6];//osc_out[6];
    GPIO[12] <= egout[FRACTIONAL_BITS-7];//osc_out[7];
    GPIO[13] <= egout[FRACTIONAL_BITS-8];//osc_out[8];
    GPIO[14] <= egout[FRACTIONAL_BITS-9];//osc_out[9];
    GPIO[15] <= egout[FRACTIONAL_BITS-10];//osc_out[10];
    GPIO[16] <= egout[FRACTIONAL_BITS-11];//osc_out[11];
  end
endmodule:top
