//`timescale 1ns/1ps

module misr (
output reg [15:0] misr_out,
input in,
input enable,
input clk,
input reset
);

//reg [15:0] misr;
wire linear_feedback;
assign linear_feedback = misr_out[15];

initial begin
  misr_out <= 16'hffff;
end

always @(posedge clk) begin
  if (reset) 
    misr_out <= 16'hffff;
  else if (enable) begin
      misr_out[0] <= linear_feedback ^ in;
      misr_out[1] <= misr_out[0];
      misr_out[2] <= misr_out[1];
      misr_out[3] <= misr_out[2];
      misr_out[4] <= misr_out[3] ^ linear_feedback;
      misr_out[5] <= misr_out[4] ^ linear_feedback; 
      misr_out[6] <= misr_out[5] ^ linear_feedback;
      misr_out[7] <= misr_out[6];
      misr_out[8] <= misr_out[7];
      misr_out[9] <= misr_out[8];
      misr_out[10] <= misr_out[9];
      misr_out[11] <= misr_out[10];
      misr_out[12] <= misr_out[11];
      misr_out[13] <= misr_out[12];
      misr_out[14] <= misr_out[13];
      misr_out[15] <= misr_out[14];
  end
end
endmodule
