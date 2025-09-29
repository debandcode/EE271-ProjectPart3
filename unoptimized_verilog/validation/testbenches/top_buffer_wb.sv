`include "defines.sv"

module top_buffer_wb(

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
    pe_inst_t     pe_inst;
    wire          pe_inst_valid;
    buf_inst_t    buf_inst;
    wire          buf_inst_valid;
    wire [`MEM0_BITWIDTH-1:0] matrix_data;
    wire [`MEM1_BITWIDTH-1:0] vector_data;

    // Instruction Memory
    instruction_memory u_instruction_memory (
        .clk(clk),
        .rst_n(rst_n),
        .inst(inst),
        .inst_valid(inst_valid),
        .advance_pointer(inst_exec_begins),
        .instruction_count(instruction_count)
    );

    controller u_controller (
        .clk(clk),
        .rst_n(rst_n),
        .inst(inst),
        .inst_valid(inst_valid),
        .inst_exec_begins(inst_exec_begins),
        .pe_inst(pe_inst),
        .pe_inst_valid(pe_inst_valid),
        .buf_inst(buf_inst),
        .buf_inst_valid(buf_inst_valid)
    );

    buffer u_buffer (
        .clk(clk),
        .rst_n(rst_n),
        .buf_inst(buf_inst),
        .buf_inst_valid(buf_inst_valid),
        .matrix_data(matrix_data),
        .vector_data(vector_data),
        .output_data(32'hABCD0123)
    );

endmodule
