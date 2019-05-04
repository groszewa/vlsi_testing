`timescale 1ns/1ps

module lfsr (
output reg[15:0] out,
input enable,
input clk,
input reset,
output lfsr_out
);

wire linear_feedback;
assign linear_feedback = out[15];
assign lfsr_out = out[0];

always @(posedge clk)
if (reset) begin
  out <= 16'hffff;
end else if (enable) begin
    out[0] <= out[15];
    out[1] <= out[0];
    out[2] <= out[1];
    out[3] <= out[2];
    out[4] <= out[3] ^ linear_feedback;
    out[5] <= out[4] ^ linear_feedback; 
    out[6] <= out[5] ^ linear_feedback;
    out[7] <= out[6];
    out[8] <= out[7];
    out[9] <= out[8];
    out[10] <= out[9];
    out[11] <= out[10];
    out[12] <= out[11];
    out[13] <= out[12];
    out[14] <= out[13];
    out[15] <= out[14];
end
endmodule
