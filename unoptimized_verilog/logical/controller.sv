`include "defines.sv"

module controller(

    // Clock and Reset
    input wire clk,
    input wire rst_n,

    // Input Instruction
    input  instruction_t inst,
    input  logic         inst_valid,
    output logic         inst_exec_begins,

    // Output Instructions to PEs/Buffer
    output pe_inst_t     pe_inst,
    output logic         pe_inst_valid,
    output buf_inst_t    buf_inst,
    output logic         buf_inst_valid

);

    typedef enum {IDLE, EXECUTING} fsm_t; 
    fsm_t state; // Current state register (updated in always_ff)

    // START IMPLEMENTATION
    // Latched/Reg versions of instructions and counts
    pe_inst_t  pe_inst_r;
    buf_inst_t buf_inst_r;

    logic [`CONTROLLER_COUNT_BITWIDTH-1:0]    count_r;        // inst.count
    logic [`CONTROLLER_COUNT_BITWIDTH-1:0]    iter_count_r;   // count current iteration, 0 to count_r
    
    logic [`CONTROLLER_MEMA_INC_BITWIDTH-1:0] mema_inc_r;     // inst.mema_inc
    logic [`CONTROLLER_MEMB_INC_BITWIDTH-1:0] memb_inc_r;     // inst.memb_inc

    logic pe_inst_valid_r;
    logic buf_inst_valid_r;
    logic inst_exec_begins_r;

    // Drive outputs
    assign pe_inst            = pe_inst_r;
    assign buf_inst           = buf_inst_r;
    assign pe_inst_valid      = pe_inst_valid_r;
    assign buf_inst_valid     = buf_inst_valid_r;
    assign inst_exec_begins   = inst_exec_begins_r;

    // Sequential logic for FSM 
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Asyn, reset all state
            state <= IDLE;
            pe_inst_r <= '0;
            buf_inst_r <= '0;
            count_r <= '0;
            iter_count_r <= '0;
            mema_inc_r <= '0;
            memb_inc_r <= '0;
            pe_inst_valid_r <= 1'b0;
            buf_inst_valid_r <= 1'b0;
            inst_exec_begins_r <= 1'b0;
        end else begin
            pe_inst_valid_r <= 1'b0;
            buf_inst_valid_r <= 1'b0;
            inst_exec_begins_r <= 1'b0;

            case (state)
                IDLE: begin
                    if (inst_valid) begin
                        buf_inst_r <= inst.buf_instruction;
                        pe_inst_r <= inst.pe_instruction;
                        count_r <= inst.count;
                        mema_inc_r <= inst.mema_inc;
                        memb_inc_r <= inst.memb_inc;
                        iter_count_r <= '0;
                        
                        state <= EXECUTING;
                    end
                end

                EXECUTING: begin
                    pe_inst_valid_r <= 1'b1;
                    buf_inst_valid_r <= 1'b1;

                    // check if this is the final iteration
                    if (iter_count_r == count_r) begin
                        state <= IDLE; // completed, back to IDLE
                        inst_exec_begins_r <= 1'b1; // pulse the instruction memory to fetch the next instruction
                    end else begin
                        iter_count_r <= iter_count_r + 1'b1;
                        buf_inst_r.mema_offset <= buf_inst_r.mema_offset + mema_inc_r;
                        buf_inst_r.memb_offset <= buf_inst_r.memb_offset + memb_inc_r;

                        state <= EXECUTING;
                    end
                end

                default:
			state <= IDLE;

            endcase
        end
    end

    // END IMPLEMENTATION

endmodule
