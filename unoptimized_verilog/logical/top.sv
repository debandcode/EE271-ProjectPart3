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
    pe_inst_t  pe_inst;
    logic      pe_inst_valid;
    buf_inst_t buf_inst;
    logic      buf_inst_valid;
    controller u_controller(
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

    logic [`MEM0_BITWIDTH-1:0] matrix_data;
    logic [`MEM1_BITWIDTH-1:0] vector_data;
    logic [`MEM2_BITWIDTH-1:0] output_data;
    buffer u_buffer(
        .clk(clk),
        .rst_n(rst_n),
        .buf_inst(buf_inst),
        .buf_inst_valid(buf_inst_valid),
        .matrix_data(matrix_data),
        .vector_data(vector_data),
        .output_data(output_data)
    );

    logic [`PE_OUTPUT_BITWIDTH-1:0] pe_outputs [`PE_COUNT-1:0];
    logic [`MEM2_BITWIDTH-1:0]      pe_outputs_concat;
    logic                           pe_out_valid_d;

    genvar i;
    generate
        for (i=0; i< `PE_COUNT; i=i+1) begin : PE_ARRAY
            processing_element u_pe (
                .clk(clk),
                .rst_n(rst_n),
                .pe_inst(pe_inst),
                .pe_inst_valid(pe_inst_valid),
                .matrix_input(matrix_data[(i+1)*`PE_INPUT_BITWIDTH-1 -: `PE_INPUT_BITWIDTH]),
                .vector_input(vector_data),
                .vector_output(pe_outputs[i])
            );
            assign pe_outputs_concat[(i+1)*`PE_OUTPUT_BITWIDTH-1 -: `PE_OUTPUT_BITWIDTH] = pe_outputs[i];
        end 
        
    endgenerate

    wire pe_out_pulse = pe_inst_valid &&
                        (pe_inst.opcode == `PE_OUT_OPCODE) &&
                        (pe_inst.value  == `PE_OUT_VALUE);

    // Register PE outputs one cycle after an OUT instruction
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            output_data    <= '0;
            pe_out_valid_d <= 1'b0;
        end else begin
            pe_out_valid_d <= pe_out_pulse;
            if (pe_out_valid_d) begin
                output_data <= pe_outputs_concat;
            end
        end
    end

endmodule
