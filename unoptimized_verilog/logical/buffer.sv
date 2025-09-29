`include "defines.sv"

module buffer (
    // Clock and Reset
    input wire clk,
    input wire rst_n,

    // Input Instruction
    input buf_inst_t    buf_inst,
    input logic         buf_inst_valid,

    // Outputs
    output logic [`MEM0_BITWIDTH-1:0] matrix_data,
    output logic [`MEM1_BITWIDTH-1:0] vector_data,
    input  logic [`MEM2_BITWIDTH-1:0] output_data
);

    // START IMPLEMENTATION
    // Your Code Here
    
    array #(
        .DW(`MEM0_BITWIDTH),
        .NW(`MEM0_DEPTH),
        .AW(`MEM0_ADDR_WIDTH)
    ) u_matrix_mem (
        .clk(clk),
        .cen('0),
        .wen('1),
        .gwen('1),
        .a(),
        .d(),
        .q()
    );

    array #(
        .DW(`MEM1_BITWIDTH),
        .NW(`MEM1_DEPTH),
        .AW(`MEM1_ADDR_WIDTH)
    ) u_vector_mem (
        .clk(clk),
        .cen('0),
        .wen('1),
        .gwen('1),
        .a(),
        .d(),
        .q()
    );

    logic write_control_n;
    array #(
        .DW(`MEM2_BITWIDTH),
        .NW(`MEM2_DEPTH),
        .AW(`MEM2_ADDR_WIDTH),
        .INITIALIZE_MEMORY(1)
    ) u_output_mem (
        .clk(clk),
        .cen('0),
        .wen('0),
        .gwen(write_control_n),
        .a(),
        .d(),
        .q()
    );


    // END IMPLEMENTATION


endmodule
