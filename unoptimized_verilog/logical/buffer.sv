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

    // Decode the buffer opcode into read/write enables
    logic rd_func, wr_func;
    always_comb begin
        rd_func = 1'b0;
        wr_func = 1'b0;
        if (buf_inst_valid) begin
            unique case (buf_inst.opcode)
                `BUF_READ : rd_func = 1'b1;
                `BUF_WRITE: wr_func = 1'b1;
                default;
            endcase
        end
    end

    // Word addresses for MEM0/MEM2 (matrix/output memories)
    logic [`MEM0_ADDR_WIDTH-1:0] mem0_addr;
    logic [`MEM2_ADDR_WIDTH-1:0] mem2_addr;
    assign mem0_addr = buf_inst.mema_offset[`MEM0_ADDR_WIDTH-1:0];
    assign mem2_addr = buf_inst.mema_offset[`MEM2_ADDR_WIDTH-1:0];

    // Matrix memory (read-only)
    logic [`MEM0_BITWIDTH-1:0] mem0_q;
    array #(
        .DW(`MEM0_BITWIDTH),
        .NW(`MEM0_DEPTH),
        .AW(`MEM0_ADDR_WIDTH)
    ) u_matrix_mem (
        .clk (clk),
        .cen (1'b0),
        .wen ({`MEM0_BITWIDTH{1'b1}}),
        .gwen(1'b1),
        .a   (mem0_addr),
        .d   ('0),
        .q   (mem0_q)
    );

    // Vector memory (read-only) – address produced by vector_decoder
    logic [`MEM1_ADDR_WIDTH-1:0] mem1_addr;
    logic [`MEM1_BITWIDTH-1:0]   mem1_q;
    array #(
        .DW(`MEM1_BITWIDTH),
        .NW(`MEM1_DEPTH),
        .AW(`MEM1_ADDR_WIDTH)
    ) u_vector_mem (
        .clk (clk),
        .cen (1'b0),
        .wen ({`MEM1_BITWIDTH{1'b1}}),
        .gwen(1'b1),
        .a   (mem1_addr),
        .d   ('0),
        .q   (mem1_q)
    );

    // Output memory (write port)
    logic write_control_n;
    assign write_control_n = ~wr_func;
    array #(
        .DW(`MEM2_BITWIDTH),
        .NW(`MEM2_DEPTH),
        .AW(`MEM2_ADDR_WIDTH),
        .INITIALIZE_MEMORY(1)
    ) u_output_mem (
        .clk (clk),
        .cen (1'b0),
        .wen ({`MEM2_BITWIDTH{1'b0}}),
        .gwen(write_control_n),
        .a   (mem2_addr),
        .d   (output_data),
        .q   ()
    );

    // Pipeline registers to align the synchronous memories with the PE inputs
    logic rd_func_d;
    logic [`BUF_MEMB_OFFSET_BITWIDTH-1:0] memb_offset_reg;
    logic [`MEM0_BITWIDTH-1:0]            matrix_data_reg;
    logic [`MEM1_BITWIDTH-1:0]            vector_data_reg;
    logic [`BUF_MODE_BITWIDTH-1:0] mode_reg;

    // Vector decoder output (combinational)
    logic [`MEM1_BITWIDTH-1:0]      vector_data_wire;
    vector_decoder u_vector_decoder (
        .data_from_mem(mem1_q),
        .addr_from_controller(buf_inst.memb_offset),
        .addr_from_controller_reg(memb_offset_reg),
        .mode(mode_reg),
        .data_to_pe(vector_data_wire),
        .addr_to_mem(mem1_addr)
    );

    // Pipeline stage: capture request info and aligned data
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_func_d       <= 1'b0;
            memb_offset_reg <= '0;
            matrix_data_reg <= '0;
            vector_data_reg <= '0;
	    mode_reg <= '0;
        end else begin
            rd_func_d <= rd_func;

            if (rd_func) begin
                memb_offset_reg <= buf_inst.memb_offset;
		mode_reg <= buf_inst.mode;
            end

            if (rd_func_d) begin
                matrix_data_reg <= mem0_q;
                vector_data_reg <= vector_data_wire;
            end
        end
    end

    assign matrix_data = matrix_data_reg;
    assign vector_data = vector_data_reg;

    // END IMPLEMENTATION
endmodule
