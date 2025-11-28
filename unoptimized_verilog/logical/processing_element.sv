`include "defines.sv"
`define FF(out, in) always @(posedge clk, negedge rst_n) out <= (rst_n == '0) ? '0 : in;

// Handling "MAC" Instruction
`define MAC_MACRO(val,acc_reg,vec_in,mat_in) \
    for(int i = 0;i < `PE_INPUT_BITWIDTH;i+=val) \
    acc_reg[(2*i)+:2*val] <= (signed'(vec_in[i+:val]) * signed'(mat_in[i+:val])) + signed'(acc_reg[(2*i)+:2*val]);
`define HANDLE_MAC(acc_reg,vec_in,mat_in,mode) \
    case(mode) \
        `MODE_INT8:  `MAC_MACRO(8,acc_reg,vec_in,mat_in) \
        `MODE_INT16: `MAC_MACRO(16,acc_reg,vec_in,mat_in) \
        `MODE_INT32: `MAC_MACRO(32,acc_reg,vec_in,mat_in) \
    endcase;

// Handling "OUT" Instruction
`define OUT_MACRO(val,vec_out,acc_reg) \
    for(int i = 0;i < `PE_INPUT_BITWIDTH;i+=val) \
    vec_out[i+:val] <= signed'(acc_reg[(2*i)+:val]);
`define HANDLE_OUT(vec_out,acc_reg,mode) \
    case(mode) \
        `MODE_INT8:  `OUT_MACRO(8,vec_out,acc_reg) \
        `MODE_INT16: `OUT_MACRO(16,vec_out,acc_reg) \
        `MODE_INT32: `OUT_MACRO(32,vec_out,acc_reg) \
    endcase;

// Handling "PASS" Instruction
`define PASS_MACRO(val,acc_reg,vec_in) \
    for(int i = 0;i < `PE_INPUT_BITWIDTH;i+=val) \
    acc_reg[(2*i)+:2*val] <= { {val{vec_in[i+val-1]}} ,vec_in[i+:val]};
`define HANDLE_PASS(acc_reg,vec_in,mode) \
    case(mode) \
        `MODE_INT8:  `PASS_MACRO(8,acc_reg,vec_in) \
        `MODE_INT16: `PASS_MACRO(16,acc_reg,vec_in) \
        `MODE_INT32: `PASS_MACRO(32,acc_reg,vec_in) \
    endcase;

// Handling "RND" Instruction
`define RND_MACRO(val,acc_reg,shift_amt) \
    for(int i = 0;i < `PE_INPUT_BITWIDTH;i+=val) \
    acc_reg[(2*i)+:2*val] <= acc_reg[(2*i)+:2*val] >>> shift_amt;
`define HANDLE_RND(acc_reg,value,mode) \
    case(mode) \
        `MODE_INT8:  `RND_MACRO(8,acc_reg,value) \
        `MODE_INT16: `RND_MACRO(16,acc_reg,value) \
        `MODE_INT32: `RND_MACRO(32,acc_reg,value) \
    endcase;


module processing_element(

    // Clock and Reset Inputs
    input wire clk,
    input wire rst_n,

    // Input Instruction
    input pe_inst_t     pe_inst,
    input logic         pe_inst_valid,

    // Input Operands
    input logic [`PE_INPUT_BITWIDTH-1:0] vector_input,
    input logic [`PE_INPUT_BITWIDTH-1:0] matrix_input,

    // Output Operand
    output logic [`PE_OUTPUT_BITWIDTH-1:0] vector_output


);

    // Creating the Accumulation Vector
    logic [`PE_ACCUMULATION_BITWIDTH-1:0] accumulation_register;

    // Registering Inputs for Timing Reasons
    // It takes one cycle for the output of the
    // buffer to be valid.
    pe_inst_t     pe_inst_reg;
    logic         pe_inst_valid_reg;
    `FF(pe_inst_reg, pe_inst)
    `FF(pe_inst_valid_reg, pe_inst_valid)

    // Decode Logic
    always @(posedge clk, negedge rst_n) begin
        if(rst_n == '0) begin
            accumulation_register <='0;
            vector_output <= '0;
        end else begin
            if(pe_inst_valid_reg == '1) begin

                // Decoding Instruction and Executing
                if(pe_inst.opcode == '0) begin
                    case(pe_inst.value)
                        `PE_MAC_VALUE:  begin
                            `HANDLE_MAC(accumulation_register, vector_input, matrix_input, pe_inst.mode)
                        end
                        `PE_OUT_VALUE:  begin
                            `HANDLE_OUT(vector_output, accumulation_register, pe_inst.mode)
                        end
                        `PE_PASS_VALUE: begin
                            `HANDLE_PASS(accumulation_register, vector_input, pe_inst.mode)
                        end
                        `PE_CLR_VALUE:  accumulation_register <= '0;
                    endcase;
                end else begin
                    case(pe_inst.opcode)
                        `PE_RND_OPCODE: begin
                            `HANDLE_RND(accumulation_register, pe_inst.value, pe_inst.mode);
                        end
                    endcase;
                end

            end
        end
    end



endmodule
