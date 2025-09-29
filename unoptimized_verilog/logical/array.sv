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


logic     [DW-1:0]  data [0:NW-1];        // RAM data
logic     [DW-1:0]  read_data;
//logic	  [DW-1:0]  writeEnable;
integer             i;                       // Loop counter

// optionally initialize RAM, as done in non-generic models

initial begin
  #0
  if(INITIALIZE_MEMORY==1) begin
      for (i=0;i<NW;i=i+1) begin
        data[i] = {DW{1'b0}};
      end
  end
end

// write
always @(posedge clk)
begin
  if (~cen & ~gwen)
  begin
    data[a[AW-1:0]] = (data[a[AW-1:0]] & wen) | (~wen & (wen | d));
  end
end

// read
always @(posedge clk)
begin
  if (~cen)
  begin
    read_data = data[a[AW-1:0]];
  end
end

// latch output
always @(read_data or cen or gwen)
begin
  if (~cen)
  begin
    q = read_data;
  end
end

task loadmem; //load mem from binary file, compatible with tb
  input string fname; //name of binary file
  reg [DW-1:0] memld [0:NW-1];
  integer i;
  reg [DW-1:0] word;
  begin
    $readmemb(fname, memld);
    for (i=0; i<NW; i = i+1) begin
        assign word = memld[i];
        data[i] = word;
    end
  end
endtask

task dumpmem; //dump data to binary file, compatible with tb
  input string fname;
  reg [DW-1:0] word;
  integer i;
  integer fd; //get type of file to dump to, hex or binary

  begin
    fd = $fopen(fname, "w");
    for (i=0; i<NW; i= i+1) begin
        assign word = data[i];
        $fdisplay(fd, "%b", word);
    end
    $fclose(fd);
  end

endtask

task loadaddr;
  input [AW-1:0] load_addr;
  input [DW-1:0] load_data;
  reg [DW-1:0] word;
  begin
    if (cen)
    begin
      assign word = load_data;
      data[i] = word;
    end
  end
endtask

task dumpaddr;
  output [DW-1:0] dump_data;
  input [AW-1:0] dump_addr;
  reg [DW-1:0] word;
  begin
    if (cen)
    begin
      assign word = data[dump_addr];
      dump_data = word;
    end
  end
endtask

endmodule
