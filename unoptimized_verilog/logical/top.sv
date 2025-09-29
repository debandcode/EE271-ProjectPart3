`include "defines.sv"

module top(

    // Clock and Reset Inputs
    input wire clk,
    input wire rst_n,

    // Controls How Many Instructions Will be Executed
    input logic [`IMEM_ADDR_WIDTH-1:0] instruction_count
);

    // Top Level Signals
    instruction_t inst;
    wire          inst_valid;
    wire          inst_exec_begins;

    instruction_memory u_instruction_memory (
        .clk(clk),
        .rst_n(rst_n),
        .inst(inst),
        .inst_valid(inst_valid),
        .advance_pointer(inst_exec_begins),
        .instruction_count(instruction_count)
    );

    // START IMPLEMENTATION
    // Your Code Here
    // END IMPLEMENTATION


endmodule
