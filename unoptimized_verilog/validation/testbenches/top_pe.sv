`include "defines.sv"

module top_pe(

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
    wire [`PE_INPUT_BITWIDTH-1:0]  vector_input;
    wire [`PE_INPUT_BITWIDTH-1:0]  matrix_input;
    wire [`PE_OUTPUT_BITWIDTH-1:0] vector_output;
    assign matrix_input = 32'hfcfcfcfc;
    assign vector_input = 32'hfe000302;

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

    processing_element u_processing_element (
        .clk(clk),
        .rst_n(rst_n),
        .pe_inst(pe_inst),
        .pe_inst_valid(pe_inst_valid),
        .vector_input(vector_input),
        .matrix_input(matrix_input),
        .vector_output(vector_output)
    );

endmodule
