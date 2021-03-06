//------------Test File: 16-bit lfsr -------------

module top;

reg  lfsr_enable, clk , reset;

wire cut_scanmode; 
wire cut_sdi;
wire bistdone, bistpass;

reg [15:0] lfsr_out;
wire [15:0] out;
reg bistmode;
reg cut_sdo;
wire alex;

parameter CYCLE = 10;


//bist_controller u1 (
//       cut_scanmode,
//       cut_sdi,
//       bistdone, 
//      bistpass,
//       clk, 
//       reset,
//       bistmode,
//       cut_sdo
//    );

lfsr ilfsr (
	out,
	bistmode,
	clk,
	reset,
	alex
	);



initial

begin

     #5 reset = 1;  
     bistmode = 1;
     //#5 bistmode = 0;
     #10 reset = 0;
     #30 bistmode = 1;
     #160 bistmode = 0;
     #200 $stop;
     #200 $finish;

end

//always @(out)
//begin
//  lfsr_out = out;
//end

initial clk = 0;

always #(CYCLE/2) clk = ~clk;

endmodule


     
          
