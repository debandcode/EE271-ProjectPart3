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
    
    // execute_instruction()
    logic rd_func, wr_func;
    always_comb begin
        rd_func = 1'b0;
        wr_func = 1'b0;
        if (buf_inst_valid) begin
            case (buf_inst.opcode)
                `BUF_READ: rd_func = 1'b1;
                `BUF_WRITE: wr_func = 1'b1;
                default;
            endcase
        end
    end

    logic [`MEM0_ADDR_WIDTH-1:0] mem0_addr;
    logic [`MEM1_ADDR_WIDTH-1:0] mem1_addr;
    logic [`MEM2_ADDR_WIDTH-1:0] mem2_addr;
    
    // set mem0 and mem2
    always_comb begin
	    mem0_addr = buf_inst.mema_offset[`MEM0_ADDR_WIDTH-1:0];
	    mem2_addr = buf_inst.mema_offset[`MEM2_ADDR_WIDTH-1:0];
    end

    // set mem1
    always_comb begin
        mem1_addr = '0;
        case (buf_inst.mode)
            `MODE_INT8: begin // int(MEMB_BITWIDTH/4) == MEMB_BITWIDTH>>2 == index of 32-bits word
                mem1_addr = buf_inst.memb_offset[`BUF_MEMB_OFFSET_BITWIDTH-1:2]; 
            end
            `MODE_INT16: begin
                mem1_addr = buf_inst.memb_offset[`BUF_MEMB_OFFSET_BITWIDTH-1:1];
            end
            `MODE_INT32: begin
                mem1_addr = buf_inst.memb_offset[`BUF_MEMB_OFFSET_BITWIDTH-1:0];
            end
            default: mem1_addr = '0;
        endcase
    end

    logic [`MEM0_BITWIDTH-1:0] mem0_q;
    array #(
        .DW(`MEM0_BITWIDTH),
        .NW(`MEM0_DEPTH),
        .AW(`MEM0_ADDR_WIDTH)
    ) u_matrix_mem (
        .clk(clk),
        .cen('0),
        .wen('1),
        .gwen('1),
        .a(mem0_addr),
        .d('0),
        .q(mem0_q)
    );

    logic [`MEM1_BITWIDTH-1:0] mem1_q;
    array #(
        .DW(`MEM1_BITWIDTH),
        .NW(`MEM1_DEPTH),
        .AW(`MEM1_ADDR_WIDTH)
    ) u_vector_mem (
        .clk(clk),
        .cen('0),
        .wen('1),
        .gwen('1),
        .a(mem1_addr),
        .d('0),
        .q(mem1_q)
    );

    logic write_control_n;
    assign write_control_n = ~wr_func;
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
        .a(mem2_addr),
        .d(output_data),
        .q()
    );

    // handle_read()
    logic [`MEM1_BITWIDTH-1:0] next_out_data;
    always_comb begin
        case (buf_inst.mode)
            `MODE_INT8: begin
                logic [7:0] elem;
                case (buf_inst.memb_offset[1:0]) // MIGHT BE ABLE TO OPTIMIZE?!!!!!!!!!!
                    2'd0: elem = mem1_q[7:0];
                    2'd1: elem = mem1_q[15:8];
                    2'd2: elem = mem1_q[23:16];
                    2'd3: elem = mem1_q[31:24];
                    default: elem = 8'b0;
                endcase
                next_out_data = {4{elem}}; // repeat 4 times
            end
            `MODE_INT16: begin
                logic [15:0] elem;
                unique case (buf_inst.memb_offset[0])
                    1'd0: elem = mem1_q[15:0];
                    1'd1: elem = mem1_q[31:16];
                    default: elem = 16'b0;
                endcase
                next_out_data = {2{elem}};   // broadcast 16-bit elem twice
            end

            `MODE_INT32: begin
                next_out_data = mem1_q;
            end
            default: next_out_data = '0;
        endcase
    end

    // Output Reg
    always_ff @(posedge clk or negedge rst_n)begin
        if (!rst_n) begin 
            matrix_data <= '0;
            vector_data <= '0;
        end else if (rd_func) begin
            matrix_data <= mem0_q;
            vector_data <= next_out_data;
        end
    end

    // END IMPLEMENTATION
endmodule
