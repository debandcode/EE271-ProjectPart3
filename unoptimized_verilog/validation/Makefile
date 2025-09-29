.PHONY: compile compile_hw compile_sw run_sim debug clean

# Default Variables
TB_NAME:=top
INST_COUNT:=3
TIMEOUT:=10000000

# Compiler Defines
CC=ivd-cc
MG=ivd-mg
AS=ivd-as
VG=ivd-gv
SW_DIR=software

# VCS Compile Options
VCS = vcs
VCS_FLAGS= -sverilog -full64 -timescale=1ns/1ps -debug
VCS_GEN_FILES=simv simv.daidir DVEfiles csrc ucli.key vcdplus.vpd

# Directories/Files
SOFTWARE_DIR=software
MATRIX=matrix.npy
VECTOR=vector.npy
INSTRUCTIONS=inst.bits
ASM_FILE=mat_mul.asm
MEM0_CONFIG=mem0.bits
MEM1_CONFIG=mem1.bits
TEST:=not_pe_test



# Bash Functions for Checking if Variables are Defined
check_defined = \
    $(strip $(foreach 1,$1, \
        $(call __check_defined,$1,$(strip $(value 2)))))
__check_defined = \
	$(if $(value $1),, \
      $(error Undefined $1$(if $2, ($2))))

compile: compile_hw compile_sw

compile_hw:
	@:$(call check_defined, TB_NAME, The testbench to be run)
	$(VG) --out defines.sv
	$(VCS) $(VCS_FLAGS) -f ./files/tb_$(TB_NAME).f -top tb_$(TB_NAME)


ifeq ($(TB_NAME),pe)
compile_sw:
	mkdir -p $(SOFTWARE_DIR)
	cd $(SOFTWARE_DIR) && $(AS) ../testbenches/pe_test.asm --out $(INSTRUCTIONS)
else ifeq ($(TB_NAME),buffer_wb)
compile_sw:
	mkdir -p $(SOFTWARE_DIR)
	cd $(SOFTWARE_DIR) && $(AS) ../testbenches/buffer_wb_test.asm --out $(INSTRUCTIONS)
else
compile_sw:
	mkdir -p $(SOFTWARE_DIR)
	cd $(SOFTWARE_DIR) && $(MG) 10 5 -5 5 --out $(MATRIX)
	cd $(SOFTWARE_DIR) && $(MG)  5 1 -5 5 --out $(VECTOR) --seed 12345
	cd $(SOFTWARE_DIR) && $(CC) $(MATRIX) $(VECTOR) INT8 --out_mem0 $(MEM0_CONFIG) --out_mem1 $(MEM1_CONFIG) --out_asm $(ASM_FILE)
	cd $(SOFTWARE_DIR) && $(AS) $(ASM_FILE) --out $(INSTRUCTIONS)
endif


run_sim:
	./simv +INST_COUNT=$(INST_COUNT) +INST_FILE=./$(SOFTWARE_DIR)/$(INSTRUCTIONS) +MEM0_FILE=./$(SOFTWARE_DIR)/$(MEM0_CONFIG) +MEM1_FILE=./$(SOFTWARE_DIR)/$(MEM1_CONFIG) +TIMEOUT=$(TIMEOUT)

debug:
	dve -vpd vcdplus.vpd -full64

clean:
	rm -rf $(VCS_GEN_FILES)
	rm -rf $(SW_DIR)
	rm -f  defines.sv
