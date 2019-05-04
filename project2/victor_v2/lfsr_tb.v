//------------Test File: 16-bit lfsr -------------

module top;

reg  lfsr_enable, clk , reset;

wire cut_scanmode; 
wire cut_sdi;
wire bistdone, bistpass;

reg [15:0] lfsr_out;
reg bistmode;
reg cut_sdo;

parameter CYCLE = 10;


bist_controller u1 (
       cut_scanmode,
       cut_sdi,
       bistdone, 
       bistpass,
       clk, 
       reset,
       bistmode,
       cut_sdo
    );




initial

begin

     #5 reset = 1; 
     #5 bistmode = 0;
     #10 reset = 0;
     #25 reset = 1; bistmode = 1;
     //#160 bistmode = 0;
     #1000 $stop;
     #1000 $finish;

end

//always @(out)
//begin
//  lfsr_out = out;
//end

initial clk = 0;

always #(CYCLE/2) clk = ~clk;

always @(posedge clk) begin
 cut_sdo = cut_sdi;
end

endmodule


     
          
