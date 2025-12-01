// `include "defines.sv"
`include "../synth/defines.sv"  
`define FF(out, in) always @(posedge clk, negedge rst_n) out <= (rst_n == '0) ? '0 : in;

// // Handling "MAC" Instruction
// `define MAC_MACRO(val,acc_reg,vec_in,mat_in) \
//     for(int i = 0;i < `PE_INPUT_BITWIDTH;i+=val) \
//     acc_reg[(2*i)+:2*val] <= (signed'(vec_in[i+:val]) * signed'(mat_in[i+:val])) + signed'(acc_reg[(2*i)+:2*val]);

localparam int VEC_W = `PE_INPUT_BITWIDTH;

`define HANDLE_MAC_COMB(vec_in,mat_in,mode) \
    case (mode) \
        `MODE_INT8: begin \
            mul8_0_a = signed'(vec_in[7:0]); \
            mul8_0_b = signed'(mat_in[7:0]); \
            mul8_1_a = signed'(vec_in[15:8]); \
            mul8_1_b = signed'(mat_in[15:8]); \
            mul16_a  = {{8{vec_in[23]}}, vec_in[23:16]}; \
            mul16_b  = {{8{mat_in[23]}}, mat_in[23:16]}; \
            mul32_a  = {{24{vec_in[31]}}, vec_in[31:24]}; \
            mul32_b  = {{24{mat_in[31]}}, mat_in[31:24]}; \
        end \
        `MODE_INT16: begin \
            mul16_a  = signed'(vec_in[15:0]); \
            mul16_b  = signed'(mat_in[15:0]); \
            mul32_a  = {{16{vec_in[31]}}, vec_in[31:16]}; \
            mul32_b  = {{16{mat_in[31]}}, mat_in[31:16]}; \
            mul8_0_a = '0; mul8_0_b = '0; \
            mul8_1_a = '0; mul8_1_b = '0; \
        end \
        `MODE_INT32: begin \
            mul32_a  = signed'(vec_in[31:0]); \
            mul32_b  = signed'(mat_in[31:0]); \
            mul16_a  = '0; mul16_b  = '0; \
            mul8_0_a = '0; mul8_0_b = '0; \
            mul8_1_a = '0; mul8_1_b = '0; \
        end \
    endcase


// `define HANDLE_MAC(acc_reg,mode)  \
//     case(mode) \
//         `MODE_INT8: begin \ 
//             accumulation_register[15:0]   <= signed'(accumulation_register[15:0])   + {{8{mul8_0_p[7]}}, mul8_0_p}; \
//             accumulation_register[31:16]  <= signed'(accumulation_register[31:16])  + {{8{mul8_1_p[7]}}, mul8_1_p}; \
//             accumulation_register[47:32]  <= signed'(accumulation_register[47:32])  + mul16_p[15:0]; \ 
//             accumulation_register[63:48]  <= signed'(accumulation_register[63:48])  + mul32_p[15:0]; \
//         end\
//         `MODE_INT16: begin \
//             accumulation_register[31:0] <= signed'(accumulation_register[31:0]) + mul16_p; \
//             accumulation_register[63:32] <= signed'(accumulation_register[63:32]) + mul32_p[31:0]; \
//         end\
//         `MODE_INT32: begin \
//             accumulation_register[63:0] <= signed'(accumulation_register[63:0]) + mul32_p; \
//         end\
//     endcase;



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
    // Multipliers
    logic signed [31:0] mul32_a, mul32_b;
    logic signed [15:0] mul16_a, mul16_b;
    logic signed  [7:0] mul8_0_a, mul8_0_b;
    logic signed  [7:0] mul8_1_a, mul8_1_b;
    logic signed [63:0] mul32_p;
    logic signed [31:0] mul16_p;
    logic signed [15:0] mul8_0_p, mul8_1_p; 
    // set up multiplier 
    assign mul32_p   = mul32_a * mul32_b; 
    assign mul16_p   = mul16_a * mul16_b; 
    assign mul8_0_p  = mul8_0_a * mul8_0_b; 
    assign mul8_1_p  = mul8_1_a * mul8_1_b; 
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

    // MAC Hardware Reuse Logic
    always_comb begin
        // default to zero to avoid latches
        mul32_a  = '0; mul32_b  = '0;
        mul16_a  = '0; mul16_b  = '0;
        mul8_0_a = '0; mul8_0_b = '0;
        mul8_1_a = '0; mul8_1_b = '0;

        // Only drive multipliers when doing a MAC
        if (pe_inst_valid_reg == '1 &&
            pe_inst_reg.opcode == '0 &&
            pe_inst_reg.value  == `PE_MAC_VALUE) begin
            `HANDLE_MAC_COMB(vector_input, matrix_input, pe_inst_reg.mode)
        end
    end


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
                                case(pe_inst_reg.mode) 
                                    `MODE_INT8: begin 
                                        accumulation_register[15:0]   <= signed'(accumulation_register[15:0])   + mul8_0_p;
                                        accumulation_register[31:16]  <= signed'(accumulation_register[31:16])  + mul8_1_p; 
                                        accumulation_register[47:32]  <= signed'(accumulation_register[47:32])  + mul16_p[15:0]; 
                                        accumulation_register[63:48]  <= signed'(accumulation_register[63:48])  + mul32_p[15:0]; 
                                    end
                                    `MODE_INT16: begin 
                                        accumulation_register[31:0] <= signed'(accumulation_register[31:0]) + mul16_p; 
                                        accumulation_register[63:32] <= signed'(accumulation_register[63:32]) + mul32_p[31:0];
                                    end
                                    `MODE_INT32: begin 
                                        accumulation_register[63:0] <= signed'(accumulation_register[63:0]) + mul32_p; 
                                    end
                                endcase;
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
