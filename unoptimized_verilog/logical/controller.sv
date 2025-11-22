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

    typedef enum logic [1:0] {IDLE, ISSUE, WAIT_DATA, EXECUTING} fsm_t; 
    fsm_t state; // current state register, updated in always_ff

    // START IMPLEMENTATION
    // Reg/latched version of instructions and counts
    pe_inst_t pe_inst_r;
    buf_inst_t buf_inst_r;

    logic [`CONTROLLER_COUNT_BITWIDTH-1:0] count_r; // inst.count
    logic [`CONTROLLER_COUNT_BITWIDTH-1:0] iter_count_r; // count current iteration, 0 to count_r
    
    logic [`CONTROLLER_MEMA_INC_BITWIDTH-1:0] mema_inc_r; // inst.mema_inc
    logic [`CONTROLLER_MEMB_INC_BITWIDTH-1:0] memb_inc_r; // inst.memb_inc

    logic pe_inst_valid_r;
    // ////////////////////logic buf_inst_valid_r;
    /////////////////logic inst_exec_begins_r;

    // Drive outputs
    assign pe_inst = pe_inst_r;
    assign buf_inst = buf_inst_r;
    assign pe_inst_valid = pe_inst_valid_r;
    // //////////////////////assign buf_inst_valid = buf_inst_valid_r;
    ////////////////////assign inst_exec_begins = inst_exec_begins_r;

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
            buf_inst_valid <= 1'b0;
            inst_exec_begins <= 1'b0;
        end else begin
            // default assignments: de-assert signals unless explicitly asserted in the FSM
            pe_inst_valid_r <= 1'b0;
            buf_inst_valid <= 1'b0;
            inst_exec_begins <= 1'b0;

            case (state) 
                IDLE: begin
                    if (inst_valid) begin
                        buf_inst_r <= inst.buf_instruction;
                        pe_inst_r <= inst.pe_instruction;
                        count_r <= inst.count;
                        mema_inc_r <= inst.mema_inc;
                        memb_inc_r <= inst.memb_inc;
                        iter_count_r <= '0;
                        buf_inst_valid <= 1'b1;           // buffer instruction valid can be set at the same time as mem address
                        state <= ISSUE;                   
                    end
                end

                ISSUE: begin
                    // Launch buffer read/write request
                    // buf_inst_valid <= 1'b1;
                    state <= EXECUTING;
                end

                EXECUTING: begin
                    // PE consumes operands produced by the last ISSUE state
                    pe_inst_valid_r <= 1'b1;
                    if (iter_count_r == count_r) begin
                        inst_exec_begins <= 1'b1;
                        buf_inst_valid <= 1'b0;       
                        state <= IDLE;
                    end else begin
                        iter_count_r <= iter_count_r + 1'b1;
                        buf_inst_r.mema_offset <= buf_inst_r.mema_offset + mema_inc_r;
                        buf_inst_r.memb_offset <= buf_inst_r.memb_offset + memb_inc_r;
                        buf_inst_valid <= 1'b1;                      // set inst_valid same time as mem
                        state <= ISSUE;                         
                    end
                end

                default: state <= IDLE;

            endcase
        end
    end

    // END IMPLEMENTATION

endmodule
