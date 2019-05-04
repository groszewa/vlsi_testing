module bist_hardware(clk,rst,bistmode,bistdone,bistpass,cut_scanmode,
                     cut_sdi,cut_sdo);
  input          clk;
  input          rst;
  input          bistmode;
  output         bistdone;
  output         bistpass;
  output         cut_scanmode;
  output         cut_sdi;
  input          cut_sdo;


// Add your code here

bist_controller u1 (
       cut_scanmode,
       cut_sdi,
       bistdone, 
       bistpass,
       clk, 
       rst,
       bistmode,
       cut_sdo
    );

endmodule  

module bist_controller (
	output reg cut_scanmode,
	output cut_sdi, 
	output reg bistdone, bistpass,
	input clk, rst, bistmode,
	input cut_sdo
);

reg ff_iter;
reg out_ready;
reg [2:0] state;
reg lfsr_en;
reg misr_en;
reg lfsr_rst;
reg misr_rst;

reg [15:0] misr_signature;
reg [15:0] golden_signature;
reg init;

wire out;
wire [15:0] out_misr;

wire start_fsm;

integer sdi_count;
integer sdo_count;
integer pattern_out;
integer last_shift_out_count;
integer total_sdo_count;

parameter SCAN_CHAIN_LENGTH = 228;
parameter LFSR_R = 16;
parameter TOTAL_PATTERNS = 2000;
 
parameter INIT = 3'b000;
parameter START = 3'b001;
parameter  SHIFT_IN = 3'b010;
parameter EVAL_PAT = 3'b011;
parameter SHIFT_OUT_LAST = 3'b100;
parameter EVAL_RES = 3'b101;
parameter DONE = 3'b110;

lfsr u1 (
         out,
         lfsr_en,
         clk,
         lfsr_rst 
         );

misr u2 (out_misr,
         cut_sdo,
         misr_en,
         clk,
         misr_rst 
         ); 

assign start_fsm = rst & bistmode;
assign cut_sdi = out;
         

always @(posedge clk) begin
    
   if (bistmode) 
     begin
        case (state)
         INIT: begin		 
             out_ready <= 0;
             pattern_out <= 0;
             cut_scanmode <= 0;
             bistdone <= 0;
             bistpass <= 0;
	     if (init) begin
	       lfsr_rst <= 0;
	       misr_rst <= 0;
	       state <= START;
	     end
	     else begin
	       lfsr_rst <= 1;
               misr_rst <= 1;
	       state <= INIT;
	     end
         end
          START: begin
               sdo_count <= 0;
               total_sdo_count <= 0;
               lfsr_en <= 1; 
               sdi_count <= 0;
               state <= SHIFT_IN;
          end
           
          SHIFT_IN: begin
              if (sdi_count <= (SCAN_CHAIN_LENGTH)) begin
                sdi_count <= sdi_count + 1; 
                cut_scanmode <= 1;
                if (out_ready == 1) begin
                  misr_en <= 1;
                  sdo_count <= sdo_count + 1;
                end
                state <= SHIFT_IN;
               end 
              else begin
                lfsr_en <= 0;
                misr_en <= 1;
                out_ready <= 0;
                cut_scanmode <= 0;
                pattern_out <= pattern_out + 1;
                if (out_ready == 1)
                  total_sdo_count <= total_sdo_count + sdo_count + 1;
                state <= EVAL_PAT;
              end
          end

          EVAL_PAT: begin
               if (pattern_out < TOTAL_PATTERNS) begin
                 cut_scanmode <= 1;
                 sdi_count <= 0;
                 sdo_count <= 0;
                 out_ready <= 1;
                 misr_en <= 1;
                 lfsr_en <= 1;
                 state <= SHIFT_IN; 
                end //endif
               else begin
                  sdi_count <= 0;
                  sdo_count <= 0;
                  out_ready <= 1;
                  misr_en <=1;
                  lfsr_en <= 1;
                  state = SHIFT_OUT_LAST;
               end
          end
                
          SHIFT_OUT_LAST: begin
              if (sdi_count <= SCAN_CHAIN_LENGTH) begin 
                sdi_count <= sdi_count + 1; 
                cut_scanmode <= 1;
                if (out_ready == 1) begin
                  misr_en <= 1;
                  sdo_count <= sdo_count + 1;
                end
                state <= SHIFT_OUT_LAST;
               end
              else begin 
                lfsr_en <= 0; 
                misr_en <= 0;
                out_ready <= 0;
                total_sdo_count <= total_sdo_count + sdo_count + 1;
                misr_signature <= out_misr;
                if (ff_iter == 1) begin
                  golden_signature <= out_misr;
                  ff_iter = 0;
                end
                cut_scanmode <= 0;
                state <= EVAL_RES;
              end
     
          end          

          EVAL_RES: begin
                if (misr_signature != golden_signature)
                  bistpass = 0;
                else 
                  bistpass = 1;
                state <= DONE;
          end

          DONE: begin
             bistdone <= 1; 
             init <= 0;
             out_ready <= 0;
             state <= INIT; 
             pattern_out <= 0;
             lfsr_rst <= 1; 
	     misr_rst <= 1;
          end

        endcase /*endcase*/ 
     end /*end if*/
end

initial begin
     ff_iter = 1;
     state = INIT;
     init = 0;
     lfsr_rst = 1;
     misr_rst = 1;
end

always @(posedge start_fsm)
    init = 1;
endmodule

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
  lfsr <= 16'haaaa;
end

     
always @(posedge clk) begin
  out <= lfsr[0]; 
  if (reset) begin
    lfsr <= 16'haaaa;
    out <= 1;
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

module misr (
output reg [15:0] misr_out,
input in,
input enable,
input clk,
input reset
);

wire linear_feedback;
assign linear_feedback = misr_out[15];

initial begin
  misr_out <= 16'haaaa;
end

always @(posedge clk) begin
  if (reset) 
    misr_out <= 16'haaaa;
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



module chip(clk,rst,pi,po,bistmode,bistdone,bistpass);
  input          clk;
  input          rst;
  input	 [34:0]  pi;
  output [48:0]  po;
  input          bistmode;
  output         bistdone;
  output         bistpass;

  wire           cut_scanmode,cut_sdi,cut_sdo;

  reg x;
  wire w_x;
  assign w_x = x;

  scan_cut circuit(bistmode,cut_scanmode,cut_sdi,cut_sdo,clk,rst,
         pi[0],pi[1],pi[2],pi[3],pi[4],pi[5],pi[6],pi[7],pi[8],pi[9],
         pi[10],pi[11],pi[12],pi[13],pi[14],pi[15],pi[16],pi[17],pi[18],pi[19],
         pi[20],pi[21],pi[22],pi[23],pi[24],pi[25],pi[26],pi[27],pi[28],pi[29],
         pi[30],pi[31],pi[32],pi[33],pi[34],
         po[0],po[1],po[2],po[3],po[4],po[5],po[6],po[7],po[8],po[9],
         po[10],po[11],po[12],po[13],po[14],po[15],po[16],po[17],po[18],po[19],
         po[20],po[21],po[22],po[23],po[24],po[25],po[26],po[27],po[28],po[29],
         po[30],po[31],po[32],po[33],po[34],po[35],po[36],po[37],po[38],po[39],
         po[40],po[41],po[42],po[43],po[44],po[45],po[46],po[47],po[48]);
  bist_hardware bist( clk,rst,bistmode,bistdone,bistpass,cut_scanmode,
                     cut_sdi,cut_sdo);
  
endmodule
