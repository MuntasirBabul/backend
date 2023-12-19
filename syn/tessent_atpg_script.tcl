# Select Muxed scan style
set_context pattern -scan
# Read gate level
read_verilog {}
read_cell_library {}
set_current_design  <design_name>
# read dofile generated from genus
dofile  <dofile path>
#set_test_logic -clock on -reset on ;# for set_context dft -scan
set_fault_type stuck
report_environment
check_design_rules
write_patterns serialpatterns_stuck.v -verilog -serial -replace
write_patterns parallelpatterns_stuck.v -verilog -parallel -replace
create_patterns
exit
