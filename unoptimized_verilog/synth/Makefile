
# Tools
VG=ivd-gv

# Parameters to Run Synthesis With
CLK_PERIOD=2.000;   # Target Clock Period (ns)
TARGET_AREA=150000; # Target Area (um^2)
DESIGN_TARGET=top;  # Design Name

SET_SYNTH_PARAMS = 	\
			set DESIGN_TARGET  $(DESIGN_TARGET);  \
			set CLK_PERIOD     $(CLK_PERIOD); 	  \
			set TARGET_AREA    $(TARGET_AREA);	


DC_COMMAND_STRING = "$(SET_SYNTH_PARAMS) source -echo -verbose dc_synth.tcl"


synthesize:
	@# Generating defines.sv
	$(VG) --out defines.sv
	dc_shell-t -64bit -x $(DC_COMMAND_STRING) 2>&1 | tee -i compile.log

clean:
	rm -f  *.log
	rm -rf reports
	rm -rf netlist
	rm -f  default.svf
	rm -f  results.txt
	rm -f  defines.sv
	rm -rf FreePDK_45nm
	rm -rf alib-52