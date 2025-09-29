
module instruction_memory(

    // Clock and Reset
    input wire clk,
    input wire rst_n,

    // Input Instruction
    output instruction_t                   inst,
    output logic                           inst_valid,
    input  logic                           advance_pointer,
    input  logic [`IMEM_ADDR_WIDTH-1:0] instruction_count
);

    // Internal Program Counter
    logic [`IMEM_ADDR_WIDTH-1:0] program_counter;
    logic [`IMEM_ADDR_WIDTH-1:0] memory_address;

    // Internal Instruction Memory
    array #(
        .DW(`FULL_INSTRUCTION_BITWIDTH), 
        .NW(`IMEM_DEPTH), 
        .AW(`IMEM_ADDR_WIDTH)
    ) u_instruction_memory (
        .clk(clk),
        .cen('0),
        .wen('1),
        .gwen('1),
        .a(memory_address),
        .d('0),
        .q(inst)
    );

    // Assigning Inst Valid
    assign inst_valid = (~rst_n) ? '0 : program_counter < instruction_count;
    assign memory_address = ((advance_pointer == '1) && (program_counter < instruction_count)) ? program_counter + 1 : program_counter;

    // Initializing Program Counter to Zero and Incrementing on Advance Pointer
    always_ff @(posedge clk, negedge rst_n) begin
        if(rst_n == '0) begin
            program_counter <= '0;
        end else begin
            program_counter <= ((advance_pointer == '1) && (program_counter < instruction_count)) ? program_counter + 1 : program_counter;
        end
    end




endmodule