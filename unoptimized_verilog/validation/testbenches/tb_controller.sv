`timescale 1ns / 1ps
`include "defines.sv"

`define CLK_PERIOD   10 
`define RESET_CYCLES  5
    

module tb_controller;
    
    // Top Level Inputs
    reg clk;
    reg rst_n;
    reg [`IMEM_ADDR_WIDTH-1:0] instruction_count;

    // Misc. Variables for Loading Memory
    string instruction_file;
    
    // =========================================================================
    // DUT Instantiation
    // =========================================================================
    top_controller dut (
        .clk(clk),
        .rst_n(rst_n),
        .instruction_count(instruction_count)
    );

    //---------------------------------------------------------
    // Tasks
    //---------------------------------------------------------
    // Checks if file exists and bombs out if not
    task check_file_exists(input string file_name);
        integer file_id;
        file_id = $fopen(file_name,"r");
        if(!file_id) begin
            $display("%t: ERROR: Cannot open file: %s", $time, file_name);
            $fclose(file_id);
            $finish;
        end
        $fclose(file_id);
    endtask

    // Ends Simulation
    task end_simulation();
        $assertkill();
        #2 $finish;
    endtask

    // =========================================================================
    // Clock Generation
    // =========================================================================
    initial begin
        clk = 0;
        forever #(`CLK_PERIOD/2) clk = ~clk;
    end
    
    // =========================================================================
    // Reset Generation
    // =========================================================================
    initial begin
        rst_n = 0;
        #(`CLK_PERIOD * `RESET_CYCLES);
        rst_n = 1;
        $display("[%0t] Reset released", $time);
    end

    // =========================================================================
    // Run-Time Flags
    // =========================================================================
    initial begin
        if($test$plusargs("NODUMP")) begin
            $display("[%0t] %m: VCD/VPD DUMP OFF.",$time);
        end else begin
            $vcdpluson;
            $vcdplusmemon;
            $display("[%0t] %m: VCD/VPD DUMP ON.",$time);
        end
    end
    initial begin
        if($test$plusargs("INST_COUNT")) begin
            $value$plusargs("INST_COUNT=%d", instruction_count);
            $display("[%0t] %m: INST_COUNT IS %0d.",$time, instruction_count);
        end else begin
            $fatal("[%0t] %m: INST_COUNT IS NOT DEFINED.",$time);
        end
    end
    initial begin
        if($test$plusargs("INST_FILE")) begin
            $value$plusargs("INST_FILE=%s", instruction_file);
            $display("[%0t] %m: INST_FILE IS %0s.",$time, instruction_file);
            check_file_exists(instruction_file);
            dut.u_instruction_memory.u_instruction_memory.loadmem(instruction_file);
        end else begin
            $fatal("[%0t] %m: INST_FILE IS NOT DEFINED.",$time);
        end
    end

    // =========================================================================
    // Determining Whether to End the Simulation
    // =========================================================================
    logic simulation_complete;
    assign simulation_complete = (dut.u_instruction_memory.program_counter == instruction_count) && ~dut.pe_inst_valid && ~dut.buf_inst_valid;    
    always @(posedge simulation_complete) begin
        #(`CLK_PERIOD)
        $display("Computation Complete, Ending Simulation.");
        $assertkill();
        #2 $finish;
    end

    // Timeout to help debug when something locks up
    integer TIMEOUT = 0;
    initial begin
        if($test$plusargs("TIMEOUT")) begin
            $value$plusargs("TIMEOUT=%d", TIMEOUT);
            $display("[%0t] %m: TIMEOUT IS %0d.",$time, TIMEOUT);
            #(TIMEOUT)
            $display("[%0t] ERROR: Timeout!",$time);
            end_simulation();
        end
    end


    // =========================================================================
    // Starting Test
    // =========================================================================
    initial begin
        wait(rst_n == 1'b1);
        repeat(2) @(posedge clk);
        $display("=== Starting Controller Testbench ===");
    end

endmodule