//`timescale 1ns/1ps

module lfsr (
output reg out,
input enable,
input clk,
input reset
);

reg [15:0] lfsr;
wire linear_feedback;
assign linear_feedback = lfsr[15];

initial begin
  lfsr <= 16'hffff;
end

     
always @(posedge clk) begin
  out <= lfsr[0]; 
  if (reset) begin
    lfsr <= 16'hffff;
  end else if (enable) begin
      lfsr[0] <= linear_feedback;
      lfsr[1] <= lfsr[0];
      lfsr[2] <= lfsr[1];
      lfsr[3] <= lfsr[2];
      lfsr[4] <= lfsr[3] ^ linear_feedback;
      lfsr[5] <= lfsr[4] ^ linear_feedback; 
      lfsr[6] <= lfsr[5] ^ linear_feedback;
      lfsr[7] <= lfsr[6];
      lfsr[8] <= lfsr[7];
      lfsr[9] <= lfsr[8];
      lfsr[10] <= lfsr[9];
      lfsr[11] <= lfsr[10];
      lfsr[12] <= lfsr[11];
      lfsr[13] <= lfsr[12];
      lfsr[14] <= lfsr[13];
      lfsr[15] <= lfsr[14];
  end
end
endmodule
