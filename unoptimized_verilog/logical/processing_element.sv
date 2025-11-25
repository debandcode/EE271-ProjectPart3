`include "defines.sv"

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

    // START IMPLEMENTATION
    // Your Code Here
    
    // Internal reg for accumulation and output
    logic signed [`PE_ACCUMULATION_BITWIDTH-1:0] acc_reg;
    logic signed [`PE_ACCUMULATION_BITWIDTH-1:0] acc_next;

    // logic [`PE_OUTPUT_BITWIDTH-1:0] out_reg;
    logic [`PE_OUTPUT_BITWIDTH-1:0] out_next;

    // Combinational next state logic 
    always_comb begin
	    acc_next = acc_reg;
	    // out_next = out_reg;


  	    if (pe_inst_valid) begin
		    case (pe_inst.opcode)
			    `PE_MAC_OPCODE: begin
				    case (pe_inst.value)
					    // MAC
					    `PE_MAC_VALUE: begin
							logic signed [31:0] mul32_a, mul32_b;
							logic signed [63:0] mul32_p;
							logic signed [63:0] mul32_acc;
							logic signed [63:0] mul32_res;

							logic signed [15:0] mul16_a;
							logic signed [15:0] mul16_b;
							logic signed [31:0] mul16_p;
							logic signed [31:0] mul16_acc;
							logic signed [31:0] mul16_res;

							logic signed [7:0]  mul8_a [1:0];
							logic signed [7:0]  mul8_b [1:0];
							logic signed [15:0] mul8_p [1:0];
							logic signed [15:0] mul8_acc [1:0];
							logic signed [15:0] mul8_res [1:0];
						    case (pe_inst.mode)
							    `MODE_INT8: begin
								    for (int i=0; i< `PE_INPUT_BITWIDTH/8; i++) begin
									    if (i<=1) begin
											mul8_a[i] = vector_input[8*i +: 8];
											mul8_b[i] = matrix_input[8*i +: 8];
											mul8_acc[i] = acc_reg[16*i +: 16];
											mul8_p[i] = mul8_a[i]*mul8_b[i];
											mul8_res[i] = mul8_p[i] + mul8_acc[i];
											acc_next[16*i +:16] = mul8_res[i];
										end
										else if (i==2) begin
											mul16_a = vector_input[8*i +: 8];
											mul16_b = matrix_input[8*i +: 8];
											mul16_acc = acc_reg[16*i +: 16];
											mul16_p = mul16_a*mul16_b;
											mul16_res = mul16_p + mul16_acc;
											acc_next[16*i +:16] = mul16_res;
										end
										else begin 
											mul32_a = vector_input[8*i +: 8];
											mul32_b = matrix_input[8*i +: 8];
											mul32_acc = acc_reg[16*i +: 16];
											mul32_p = mul32_a*mul32_b;
											mul32_res = mul32_p + mul32_acc;
											acc_next[16*i +:16] = mul32_res;
										end
									
										// logic signed [7:0] a_s;
									    // logic signed [7:0] b_s;
									    // logic signed [15:0] acc_s;
									    // logic signed [15:0] mul_s;
									    // logic signed [15:0] res_s;

									    // a_s = vector_input[8*i +: 8];
									    // b_s = matrix_input[8*i +: 8];
									    // acc_s = acc_reg[16*i +: 16];
									    // mul_s = a_s*b_s;
									    // res_s = mul_s + acc_s;

									    // acc_next[16*i +:16] = res_s;
								    end
							    end

							    `MODE_INT16: begin
									mul16_a = vector_input[16*0 +: 16];
									mul16_b = matrix_input[16*0 +: 16];
									mul16_acc = acc_reg[32*0 +: 32];
									mul16_p = mul16_a*mul16_b;
									mul16_res = mul16_p + mul16_acc;
									acc_next[32*0 +:32] = mul16_res;
									
									mul32_a = vector_input[16*1 +: 16];
									mul32_b = matrix_input[16*1 +: 16];
									mul32_acc = acc_reg[32*1 +: 32];
									mul32_p = mul32_a*mul32_b;
									mul32_res = mul32_p + mul32_acc;
									acc_next[32*1 +:32] = mul32_res;

								    // for (int i=0; i< `PE_INPUT_BITWIDTH/16; i++) begin
									//     logic signed [15:0] a_s;
									//     logic signed [15:0] b_s;
									//     logic signed [31:0] acc_s;
									//     logic signed [31:0] mul_s;
									//     logic signed [31:0] res_s;
									    
									//     a_s = vector_input[16*i +: 16];
									//     b_s = matrix_input[16*i +: 16];
									//     acc_s = acc_reg[32*i +: 32];
									//     mul_s = a_s*b_s;
									//     res_s = mul_s + acc_s;
									    
									//     acc_next[32*i +:32] = res_s;
								end

							    `MODE_INT32: begin
									mul32_a = vector_input;
									mul32_b = matrix_input;
									mul32_acc = acc_reg;
									mul32_p = mul32_a*mul32_b;
									mul32_res = mul32_p + mul32_acc;
									acc_next = mul32_res;
								    // logic signed [31:0] a_s;
								    // logic signed [31:0] b_s;
								    // logic signed [63:0] acc_s;
								    // logic signed [63:0] mul_s;
								    // logic signed [63:0] res_s;

								    // a_s = vector_input;
								    // b_s = matrix_input;
								    // acc_s = acc_reg;
								    // mul_s = a_s*b_s;
								    // res_s = acc_s + mul_s;

								    // acc_next = res_s;
							    end

							    default: begin
						    	end
					    	endcase
				    	end

				    	// NOP
				    	`PE_NOP_VALUE:begin
				    		// do nothing
				    	end

						// OUT
						`PE_OUT_VALUE :begin
							case (pe_inst.mode)
								`MODE_INT8: begin
									for (int i = 0; i < `PE_INPUT_BITWIDTH / 8; i++) begin
										out_next[8*i +: 8] = acc_reg[16*i +: 8];
									end
								end

								`MODE_INT16: begin
									for (int i = 0; i < `PE_INPUT_BITWIDTH / 16; i++) begin
										out_next[16*i +: 16] = acc_reg[32*i +: 16];
									end
								end

								`MODE_INT32: begin
									out_next = acc_reg;
								end

								default: begin
								end
							endcase
						end

				    	// PASS
                        `PE_PASS_VALUE: begin
                            case (pe_inst.mode)
                                `MODE_INT8: begin
                                    for (int i=0; i<`PE_INPUT_BITWIDTH/8; i++) begin
					acc_next[16*i +: 16] = vector_input[8*i +: 8];
                                    end
                                end

                                `MODE_INT16: begin
                                    for (int i=0; i<`PE_INPUT_BITWIDTH/16; i++) begin
					acc_next[32*i +: 32] = vector_input[16*i +: 16];
                                    end
                                end

                                `MODE_INT32: begin
                                    acc_next = vector_input;
                                end

                                default: begin
                                end
                            endcase
                        end


						// CLR
						`PE_CLR_VALUE: begin
							acc_next = '0;
							out_next = '0;
						end

				    	default: begin
				    	end
					endcase
				end

				// RND
				`PE_RND_OPCODE: begin
					int unsigned shift;
					shift = pe_inst.value;

					case (pe_inst.mode)
						`MODE_INT8 :begin
							for (int i=0; i<`PE_INPUT_BITWIDTH/8; i++) begin
								logic signed [15:0] acc_s;
								logic signed [15:0] res_s;

								acc_s = acc_reg[16*i +: 16];
								res_s = acc_s >>> shift;
								acc_next[16*i +:16] = res_s;
							end
						end

						`MODE_INT16: begin
							for (int i=0; i<`PE_INPUT_BITWIDTH/16; i++) begin
								logic signed [31:0] acc_s;
								logic signed [31:0] res_s;

								acc_s = acc_reg[32*i +: 32];
								res_s = acc_s >>> shift;
								acc_next[32*i +:32] = res_s;
							end
						end

						`MODE_INT32: begin
							logic signed [63:0] acc_s;
							logic signed [63:0] res_s;

							acc_s = acc_reg;
							res_s = acc_s >>> shift;
							acc_next = res_s;
						end

						default: begin
						end
					endcase
				end
				

				default: begin
				end

			endcase 
		end 
	end




    // Sequential state update
    always_ff @(posedge clk or negedge rst_n) begin
	    if (!rst_n) begin
		    acc_reg <= '0;
	    end else begin
		    acc_reg <= acc_next;
	    end
    end
    
	assign vector_output = out_next;
    // assign out_reg = out_next;

			    

 //END IMPLEMETATION
									    
endmodule
