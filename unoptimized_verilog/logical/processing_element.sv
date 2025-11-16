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

    logic [`PE_OUTPUT_BITWIDTH-1:0] out_reg;
    logic [`PE_OUTPUT_BITWIDTH-1:0] out_next;

    assign vector_output = out_reg;

    // Combinational next state logic 
    always_comb begin
	    acc_next = acc_reg;
	    out_next = acc_next;

  	    if (pe_inst_valid) begin
		    case (pe_inst.opcode)
			    `PE_MAC_OPCODE: begin
				    case (pe_inst.value)

					    //MAC
					    `PE_MAC_VALUE: begin
						    case (pe_inst.mode)
							    `MODE_INT8: begin
								    for (int i=0; i< `PE_INPUT_BITWIDTH/8; i++) begin
									    logic signed [7:0] a_s;
									    logic signed [7:0] b_s;
									    logic signed [15:0] acc_s;
									    logic signed [15:0] mul_s;
									    logic signed [15:0] res_s;

									    a_s = vector_input[8*i +: 8];
									    b_s = matrix_input[8*i +: 8];
									    acc_s = acc_reg[16*i +: 16];
									    mul_s = a_s*b_s;
									    res_s = mul_s + acc_s;

									    acc_next[16*i +:16] = res_s;
								    end
							    end

							    `MODE_INT16: begin
								    for (int i=0; i< `PE_INPUT_BITWIDTH/16; i++) begin
                                                                            logic signed [15:0] a_s;
                                                                            logic signed [15:0] b_s;
                                                                            logic signed [31:0] acc_s;
                                                                            logic signed [31:0] mul_s;
                                                                            logic signed [31:0] res_s;

                                                                            a_s = vector_input[16*i +: 16];
                                                                            b_s = matrix_input[16*i +: 16];
                                                                            acc_s = acc_reg[32*i +: 32];
                                                                            mul_s = a_s*b_s;
                                                                            res_s = mul_s + acc_s;

									    acc_next[32*i +:32] = res_s;
								    end
							    end

							    `MODE_INT32: begin
								    logic signed [31:0] a_s;
								    logic signed [31:0] b_s;
								    logic signed [63:0] acc_s;
								    logic signed [63:0] mul_s;
								    logic signed [63:0] res_s;

								    a_s = vector_input;
								    b_s = matrix_input;
								    acc_s = acc_reg;
								    mul_s = a_s*b_s;
								    res_s = acc_s + mul_s;

								    acc_next = res_s;
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
									for (int i=0; i< `PE_INPUT_BITWIDTH/8; i++) begin
										out_next[8*i +: 8] = acc_reg[16*i +: 8];
									end
								end

								`MODE_INT16: begin
									for (int i=0; i<`PE_INPUT_BITWIDTH/16; i++) begin
										out_next[16*i +: 16] = acc_reg[32*i +: 16];
									end
								end

								`MODE_INT32: begin
									out_next = acc_reg[31:0];
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
										logic signed [7:0] a_s;
										logic signed [15:0] acc_s;

										a_s = vector_input[8*i +: 8];
										acc_s = {{8{a_s[7]}}, a_s};

										acc_next[16*i +: 16] = acc_s;
									end
								end

								`MODE_INT16: begin
									for (int i=0; i<`PE_INPUT_BITWIDTH/16; i++) begin
									logic signed [15:0] a_s;
									logic signed [31:0] acc_s;

									a_s = vector_input[16*i +: 16];
									acc_s = {{16{a_s[15]}}, a_s};

									acc_next[32*i +: 32] = acc_s;
									end
								end

								`MODE_INT32: begin
									logic signed [31:0] a_s;
									logic signed [63:0] acc_s;

									a_s = vector_input;
									acc_s = {{32{a_s[31]}}, a_s};

									acc_next = acc_s;
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
		    out_reg <= '0;
	    end else begin
		    acc_reg <= acc_next;
		    out_reg <= out_next;
	    end
    end
    

			    

 //END IMPLEMETATION
									    
endmodule
