`ifndef ACCEL_DEFINES_H
`define ACCEL_DEFINES_H

//Top Level Parameters
`define PE_COUNT 16
`define CONTROLLER_COUNTER_BITWIDTH 16

// Buffer Parameters
`define MEM0_BITWIDTH   512
`define MEM0_DEPTH      65536
`define MEM0_ADDR_WIDTH 16
`define MEM1_BITWIDTH   32
`define MEM1_DEPTH      16384
`define MEM1_ADDR_WIDTH 14
`define MEM2_BITWIDTH   512
`define MEM2_DEPTH      65536
`define MEM2_ADDR_WIDTH 16

// Mode Parameters
`define MODE_INT8 2'd0
`define MODE_INT16 2'd1
`define MODE_INT32 2'd2

//Processing Element Parameters
`define PE_INPUT_BITWIDTH        32
`define PE_ACCUMULATION_BITWIDTH 64
`define PE_OUTPUT_BITWIDTH       32

// PE Instruction Parameters
`define PE_OPCODE_BITWIDTH  2
`define PE_MODE_BITWIDTH    2
`define PE_VALUE_BITWIDTH   5
`define PE_MAC_OPCODE 2'd0
`define PE_MAC_VALUE 5'd0
`define PE_NOP_OPCODE 2'd0
`define PE_NOP_VALUE 5'd1
`define PE_OUT_OPCODE 2'd0
`define PE_OUT_VALUE 5'd2
`define PE_PASS_OPCODE 2'd0
`define PE_PASS_VALUE 5'd3
`define PE_CLR_OPCODE 2'd0
`define PE_CLR_VALUE 5'd4
`define PE_RND_OPCODE 2'd1


// Buffer Instruction Parameters
`define BUF_OPCODE_BITWIDTH      2
`define BUF_MODE_BITWIDTH        2
`define BUF_MEMA_OFFSET_BITWIDTH 16
`define BUF_MEMB_OFFSET_BITWIDTH 16
`define BUF_READ 0
`define BUF_WRITE 1
`define BUF_NOP 2


// Controller Instruction Parameters
`define CONTROLLER_COUNT_BITWIDTH    16
`define CONTROLLER_MEMA_INC_BITWIDTH 1
`define CONTROLLER_MEMB_INC_BITWIDTH 1
`define FULL_INSTRUCTION_BITWIDTH    63
`define IMEM_DEPTH                   128
`define IMEM_ADDR_WIDTH              7

// Helpful Structs for Packing Instructions
typedef struct packed {
    logic [`PE_OPCODE_BITWIDTH-1:0] opcode;
    logic [`PE_MODE_BITWIDTH-1:0]   mode;
    logic [`PE_VALUE_BITWIDTH-1:0]  value;
} pe_inst_t;

typedef struct packed {
    logic [`BUF_OPCODE_BITWIDTH-1:0]      opcode;
    logic [`BUF_MODE_BITWIDTH-1:0]        mode;
    logic [`BUF_MEMA_OFFSET_BITWIDTH-1:0] mema_offset;
    logic [`BUF_MEMB_OFFSET_BITWIDTH-1:0] memb_offset;
} buf_inst_t;

typedef struct packed {
    buf_inst_t buf_instruction;
    pe_inst_t  pe_instruction;
    logic       [`CONTROLLER_COUNT_BITWIDTH-1:0]    count;
    logic       [`CONTROLLER_MEMA_INC_BITWIDTH-1:0] mema_inc;
    logic       [`CONTROLLER_MEMB_INC_BITWIDTH-1:0] memb_inc;
} instruction_t;


module vector_decoder (
    input  logic [`MEM1_BITWIDTH-1:0]            data_from_mem,
    input  logic [`BUF_MEMB_OFFSET_BITWIDTH-1:0] addr_from_controller,
    input  logic [`BUF_MEMB_OFFSET_BITWIDTH-1:0] addr_from_controller_reg,
    input  logic [`BUF_MODE_BITWIDTH-1:0]        mode,
    output logic [`MEM1_BITWIDTH-1:0]            data_to_pe,
    output logic [`MEM1_ADDR_WIDTH-1:0]          addr_to_mem
);
    always_comb begin
        case (mode)
            `MODE_INT8: begin
                addr_to_mem = addr_from_controller[`BUF_MEMB_OFFSET_BITWIDTH-1:2];
                case (addr_from_controller_reg[1:0])
                    2'd0: data_to_pe = {4{data_from_mem[7:0]}};
                    2'd1: data_to_pe = {4{data_from_mem[15:8]}};
                    2'd2: data_to_pe = {4{data_from_mem[23:16]}};
                    2'd3: data_to_pe = {4{data_from_mem[31:24]}};
                endcase
            end
            `MODE_INT16: begin
                addr_to_mem = addr_from_controller[`BUF_MEMB_OFFSET_BITWIDTH-2:1];
                case (addr_from_controller_reg[0:0])
                    1'd0: data_to_pe = {2{data_from_mem[15:0]}};
                    1'd1: data_to_pe = {2{data_from_mem[31:16]}};
                endcase
            end
            `MODE_INT32: begin
                addr_to_mem = addr_from_controller[`BUF_MEMB_OFFSET_BITWIDTH-3:0];
                data_to_pe = data_from_mem;
            end
        endcase
    end
endmodule


`endif
