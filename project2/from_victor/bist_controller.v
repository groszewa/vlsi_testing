module bist_controller (
       output reg cut_scanmode,
       output reg cut_sdi,
       output bistdone, bistpass,
       input clk, rst, bistmode,
       input cut_sdo
);

reg lfsr_enable;
reg [15:0] tmp;

wire [15:0] out;
wire lfsr_out;

integer i;

lfsr u1 (
         out,
         lfsr_enable,
         clk,
         (rst && ~bistmode),
	 lfsr_out
         );

initial
  begin
         tmp = 16'haaaa;
  end

always @(posedge clk)
   // if (rst) begin
   //   tmp = 16'haaaa;
   // end
    if (rst && bistmode)
      begin
        lfsr_enable = 0; 
        cut_scanmode = 1;
       
        if (i < 16) 
          begin
           cut_sdi <= out[i];
         
           if (i == 15)
            begin
              cut_scanmode = 0; 
            end

          i = i + 1;
         end

      end
    else
      begin
        i = 0;
        lfsr_enable = 1;
        cut_scanmode = 0;
      end
        
endmodule    
