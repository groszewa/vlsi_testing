module bist_controller (
	output reg cut_scanmode,
	output reg cut_sdi,
	output reg bistdone, bistpass,
	input clk, rst, bistmode,
	input cut_sdo
);

reg ff_iter;
reg out_ready;
reg [2:0] state;
//reg pattern_out;
//reg total_bits_to_sc;
reg lfsr_en;
reg misr_en;
//reg misr_in;

reg [15:0] misr_signature;
reg [15:0] golden_signature;

wire out;
wire [15:0] out_misr;

integer sdi_count;
integer sdo_count;
integer pattern_out;

parameter SCAN_CHAIN_LENGTH = 16;
parameter LFSR_R = 16;
parameter TOTAL_PATTERNS = 64;
 
parameter START = 3'b000;
parameter  SHIFT_IN = 3'b001;
parameter EVAL_PAT = 3'b010;
parameter SHIFT_OUT_LAST = 3'b011;
parameter DONE = 3'b100;

lfsr u1 (
         out,
         lfsr_en,
         clk,
         (rst && ~bistmode)
         );

misr u2 (out_misr,
         cut_sdo,
         misr_en,
         clk,
         (rst && ~bistmode)
         ); 
         

always @(posedge clk) begin
   
   if (rst && bistmode) 
     begin
        case (state)
           
          START: begin
             if (pattern_out < TOTAL_PATTERNS) begin
               cut_scanmode <= 1;
               sdi_count <= 0;
               sdo_count <= 0;
               //total_bits_to_sc <= 0;
               bistdone <= 0;
               lfsr_en <= 1; 
               cut_sdi <= out;
               //if (out_ready == 1) begin
               //  misr_en <= 1;
               //  misr_in <= cut_sdo; 
               //end
               state <= SHIFT_IN;
              end //end if
             else begin
                state <= DONE;
             end
          end
           
          SHIFT_IN: begin
              if (sdi_count < (SCAN_CHAIN_LENGTH - 1)) begin
                sdi_count <= sdi_count + 1; 
                cut_sdi <= out;
                //if (sdi_count >= (SCAN_CHAIN_LENGTH -2)) begin
                //  lfsr_en <= 0; 
                //  cut_scanmode <= 0;
                //end
                if (out_ready == 1) begin
                  misr_en <= 1;
                  //misr_in <= cut_sdo;
                  sdo_count <= sdo_count + 1;
                end
                state <= SHIFT_IN;
               end 
              else begin
                lfsr_en <= 0;
                misr_en <= 0;
                out_ready <= 0;
                cut_scanmode <= 0;
                pattern_out <= pattern_out + SCAN_CHAIN_LENGTH;
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
                 cut_sdi <= out;
                 //misr_in <= cut_sdo;
                 state <= SHIFT_IN; 
                end //endif
               else begin
                  cut_scanmode <= 1;
                  sdi_count <= 0;
                  sdo_count <= 0;
                  out_ready <= 1;
                  misr_en <=1;
                  lfsr_en <= 1;
                  cut_sdi <= out; 
                  //misr_in <= cut_sdo;
                  state = SHIFT_OUT_LAST;
                  //misr_signature = out_misr;
                  //if (ff_iter == 1) begin
                  //  golden_signature = out_misr;
                  //  ff_iter = 0;
                  //end
                  //if (misr_signature != golden_signature)
                  //  bistpass <= 0;
                  //else
                  //  bistpass <= 1;
                  
                  //bistdone <= 1; 
                  //state <= DONE;
               end
          end
                
          SHIFT_OUT_LAST: begin
              if (sdi_count < (SCAN_CHAIN_LENGTH - 1)) begin
                sdi_count <= sdi_count + 1; 
                cut_sdi <= out;
                if (out_ready == 1) begin
                  misr_en <= 1;
                  //misr_in <= cut_sdo;
                  sdo_count <= sdo_count + 1;
                end
                state <= SHIFT_OUT_LAST;
               end
              else begin 
                lfsr_en <= 0; 
                misr_en <= 0;
                out_ready <=0;
                misr_signature = out_misr;
                if (ff_iter == 1) begin
                  golden_signature = out_misr;
                  ff_iter = 0;
                end
                if (misr_signature != golden_signature)
                  bistpass <= 0;
                else 
                  bistpass <= 1;
 
                bistdone <= 1;
                cut_scanmode <= 0;
                state <= DONE;
              end
     
          end          

          DONE: begin
             bistdone <=1; 
          end

        endcase /*endcase*/ 
     end /*end if*/
end

always @(posedge bistmode) begin
   ff_iter = 1;
   out_ready = 0;
   state = START;
   pattern_out = 0;
end

endmodule
      
