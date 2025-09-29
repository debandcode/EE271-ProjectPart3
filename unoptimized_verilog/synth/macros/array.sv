module array
# (
parameter DW=32,               // Data width (nbits)
parameter NW=32,               // Number of words
parameter AW=$clog2(NW),       // Address width (nbits)
parameter INITIALIZE_MEMORY=0  // Do not initialize memory by default.
) (
input logic clk,            // clock
input logic cen,            // enable active low
input logic [DW-1:0] wen,            // write active low (read high)
input logic gwen,	    //global write enable active low
input logic [AW-1:0] a,              // address
input logic [DW-1:0] d,              // write data
output logic [DW-1:0] q               // read data
);

endmodule
