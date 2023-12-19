#########################################################################
# Genus Synthesis Tutorial                                              #
#                                                                       #
# Engineer:     Muntasir Babul                                          #
# Company:      Dynamic Solution Innovators                             #
# Description:  Synthesis + DFT(scan chain, atpg) Flow                  #
#                                                                       #
#########################################################################

# Variables/Paths
set DESIGN          ""
# All required inputs is kept in design data
set LIB_PATH        "../design_data/tech/lib"
set LEF_PATH        "../design_data/tech/lef"
set RTL_PATH        "../design_data/rtl"
set PRIM_PATH       "../design_data/tech/prim"
# set tool effort
set GEN_EFF         "medium"
set MAP_EFF         "high"
set OPT_EFF         "high"
# Enable dft flow
set DFT_FLOW        "true"
set DFT_TOOL        "modus"
                 

if {![file exists LOG]} {
    file mkdir LOG
    puts "Creating directory LOG"
}

if {![file exists OUTPUT]} {
    file mkdir OUTPUT
    puts "Creating directory OUTPUT"
}

if {![file exists RPT]} {
    file mkdir RPT
    puts "Creating directory RPT"
}

# Read Target Libraries
set LIB_FILES       ""
# Lef dependencies # First Tech lef, then lef
set LEF_FILES       ""
# Read Hdl
set RTL_FILES       ""
# Verilog files	    
set PRIMITIVES      ""

set_db /                .library    $LIB_FILES
set_db /            .lef_library    $LEF_FILES
read_hdl                            $RTL_FILES
set_db /      .information_level    7
set_db hdl_track_filename_row_col true

#----------------------------------------------------------------------------------------------------
# ELABORATE 
#----------------------------------------------------------------------------------------------------

set STAGE                           "elaborate"
$STAGE $DESIGN
time_info $STAGE
check_design -all

# Create Default Timing Mode
create_mode -default -name FUNCTIONAL
# Set Timing and Design Constraints
read_sdc -mode FUNCTIONAL ../design_data/constraints/8T_funcRBB0_SSG.sdc
if { $DFT_FLOW } {
set_db                                              dft_scan_style      {muxed_scan}
set_db                                                  dft_prefix      {DFT_}
set_db                          dft_identify_top_level_test_clocks      {false}
set_db                                   dft_identify_test_signals      {true}
set_db                                   dft_apply_sdc_constraints      {true}
set_db                                    non_dft_timing_mode_name      {FUNCTIONAL}

set_db [current_design]               .dft_scan_output_preference      {auto}
set_db [current_design]                        .dft_scan_map_mode      {tdrc_pass}
set_db [current_design] .dft_connect_scan_data_pins_during_mapping     {loopback}
set_db [current_design]   .dft_connect_shift_enable_during_mapping     {tie_off}

define_shift_enable     -name           shift_enable     \
                        -active         high        \
                        -lec_value      auto        \
                        -create_port    SE          \
                        -test_only

define_test_clock       -name           SCAN_CLK    \
                        -period         1000000     \
                        -function       test_clock  \
                        -create_port    SCAN_CLK

define_test_mode        -name           TEST_MODE   \
                        -active         high        \
                        -lec_value      auto        \
                        -create_port    TM          \

define_test_mode        -name           RST_MODE \
                        -active         low         \
                        -lec_value      auto        \
                        -create_port    reset_n     \
                        -scan_shift

check_design -all
}

puts "The number of exceptions is [llength [vfind "design:$DESIGN" -exception *]]"
# Path group define
define_cost_group -name in2out  -weight 1 -design $DESIGN
define_cost_group -name in2reg  -weight 1 -design $DESIGN
define_cost_group -name reg2out -weight 1 -design $DESIGN
define_cost_group -name reg2reg -weight 1 -design $DESIGN

path_group -from [all_inputs -no_clock] -to [all_outputs]   -group in2out   -name in2out   -view FUNCTIONAL
path_group -from [all_registers]        -to [all_outputs]   -group reg2out  -name reg2out  -view FUNCTIONAL
path_group -from [all_inputs -no_clock] -to [all_registers] -group in2reg   -name in2reg   -view FUNCTIONAL
path_group -from [all_registers]        -to [all_registers] -group reg2reg  -name reg2reg  -view FUNCTIONAL

#----------------------------------------------------------------------------------------------------
# GENERIC 
#----------------------------------------------------------------------------------------------------

set STAGE                       "generic"
set_db / .syn_${STAGE}_effort $GEN_EFF
syn_${STAGE}
time_info $STAGE

# Reports
report_timing -group in2out  > RPT/$STAGE/${DESIGN}_${STAGE}.timing_in2out.rpt
report_timing -group in2reg  > RPT/$STAGE/${DESIGN}_${STAGE}.timing_in2_reg.rpt
report_timing -group reg2reg > RPT/$STAGE/${DESIGN}_${STAGE}.timing_reg2reg.rpt
report_timing -group reg2out > RPT/$STAGE/${DESIGN}_${STAGE}.timing_reg2out.rpt
report_dp                    > RPT/$STAGE/${DESIGN}_${STAGE}.datapath.rpt
report_qor                   > RPT/$STAGE/${DESIGN}_${STAGE}.qor.rpt
report_timing                > RPT/$STAGE/${DESIGN}_${STAGE}.timing.rpt
write_snapshot -outdir         RPT/$STAGE -tag ${DESIGN}_${STAGE}
# Outputs
write_hdl                    > OUTPUT/$STAGE/${DESIGN}_${STAGE}.v
# Summary
report_summary -directory      RPT/$STAGE

#----------------------------------------------------------------------------------------------------
# MAPPING
#----------------------------------------------------------------------------------------------------

set STAGE                       "map"
set_db / .syn_${STAGE}_effort $MAP_EFF
syn_${STAGE}
time_info $STAGE

# Invokes Modus to perform Automatic Test Pattern Generator (ATPG) based testability analysis in either assume or fullscan mode
analyze_atpg_testability -directory atpg -atpg_log ../LOG/modus -library $PRIMITIVES

# Reports
report_timing -group in2out  > RPT/$STAGE/${DESIGN}_${STAGE}.timing_in2out.rpt
report_timing -group in2reg  > RPT/$STAGE/${DESIGN}_${STAGE}.timing_in2_reg.rpt
report_timing -group reg2reg > RPT/$STAGE/${DESIGN}_${STAGE}.timing_reg2reg.rpt
report_timing -group reg2out > RPT/$STAGE/${DESIGN}_${STAGE}.timing_reg2out.rpt
report_dp                    > RPT/$STAGE/${DESIGN}_${STAGE}.datapath.rpt
report_qor                   > RPT/$STAGE/${DESIGN}_${STAGE}.qor.rpt
report_timing                > RPT/$STAGE/${DESIGN}_${STAGE}.timing.rpt
write_snapshot -outdir         RPT/$STAGE -tag $STAGE
write_snapshot -outdir         RPT/$STAGE -tag ${DESIGN}_${STAGE}
# Outputs
write_hdl                    > OUTPUT/$STAGE/${DESIGN}_${STAGE}.v
# Summary
report_summary -directory      RPT/$STAGE
# LEC
if { $DFT_FLOW } {
write_do_lec -golden_design rtl -revised_design fv_map -logfile LOG/rtl2intermediate.dft.lec.log > OUTPUT/rtl2intermediate.dft.lec.do
} else {
write_do_lec -golden_design rtl -revised_design fv_map -logfile LOG/rtl2intermediate.lec.log     > OUTPUT/rtl2intermediate.lec.do
}

#----------------------------------------------------------------------------------------------------
# OPTIMIZATION
#----------------------------------------------------------------------------------------------------

set STAGE                       "opt"
set_db / .syn_${STAGE}_effort $OPT_EFF
syn_${STAGE}
time_info $STAGE

if { $DFT_FLOW } {
convert_to_scan                                                                                                                                                                     
check_dft_rules -advanced
define_scan_chain   -name           SCAN_CHAIN  \
                    -sdi            SI          \
                    -sdo            SO          \
                    -domain         SCAN_CLK    \
                    -shift_enable   SCAN_EN     \
                    -create_ports

connect_scan_chains -preview
connect_scan_chains -auto_create_chains
report_scan_chains
syn_${STAGE} -incr
}

check_design -all            > RPT/$STAGE/${DESIGN}_${STAGE}.check_design.rpt
check_timing_intent -verbose > RPT/$STAGE/${DESIGN}_${STAGE}.timing_intent.rpt

# Reports
report_timing -group in2out  > RPT/$STAGE/${DESIGN}_${STAGE}.timing_in2out.rpt
report_timing -group in2reg  > RPT/$STAGE/${DESIGN}_${STAGE}.timing_in2_reg.rpt
report_timing -group reg2reg > RPT/$STAGE/${DESIGN}_${STAGE}.timing_reg2reg.rpt
report_timing -group reg2out > RPT/$STAGE/${DESIGN}_${STAGE}.timing_reg2out.rpt
if { $DFT_FLOW } {
report_timing -group in2out  -view DFT_SHIFT_MODE > RPT/dft/$STAGE/${DESIGN}_${STAGE}.timing_in2out.rpt
report_timing -group in2reg  -view DFT_SHIFT_MODE > RPT/dft/$STAGE/${DESIGN}_${STAGE}.timing_in2_reg.rpt
report_timing -group reg2reg -view DFT_SHIFT_MODE > RPT/dft/$STAGE/${DESIGN}_${STAGE}.timing_reg2reg.rpt
report_timing -group reg2out -view DFT_SHIFT_MODE > RPT/dft/$STAGE/${DESIGN}_${STAGE}.timing_reg2out.rpt
report_timing                -view DFT_SHIFT_MODE > RPT/dft/$STAGE/${DESIGN}_${STAGE}.timing.rpt
}
report_dp                    > RPT/$STAGE/${DESIGN}_${STAGE}.datapath.rpt
report_qor                   > RPT/$STAGE/${DESIGN}_${STAGE}.qor.rpt
report_timing                > RPT/$STAGE/${DESIGN}_${STAGE}.timing.rpt
report_gates -power	     > RPT/$STAGE/${DESIGN}_${STAGE}.gates.rpt
report_dp 		     > RPT/$STAGE/${DESIGN}_${STAGE}.datapath.rpt
report_power -view $pwrView -unit nW > $RPT/$STAGE/${DESIGN}_${STAGE}.power.rpt
report_power -view $pwrView -unit nW -by_libcell > $RPT/$STAGE/${DESIGN}_${STAGE}.power_by_libcell.rpt
report_power -view $pwrView -unit nW -by_func_type > $RPT/$STAGE/${DESIGN}_${STAGE}.power_by_functype.rpt
report_scan_setup            > RPT/$STAGE/${DESIGN}_${STAGE}.scan_setup.rpt

# QOR, area, gates, and timing reports
write_reports -dir ${_REPORTS_PATH} -tag $tag
write_snapshot -outdir         RPT/$STAGE -tag ${DESIGN}_${STAGE}
# Summary
report_summary -directory      RPT/$STAGE
# Outputs
if { $DFT_FLOW } {
write_hdl                        > OUTPUT/$STAGE/${DESIGN}_${STAGE}.dft.v
write_sdc -mode FUNCTIONAL       > OUTPUT/${DESIGN}_${STAGE}.pnr.sdc
write_sdc -mode DFT_SHIFT_MODE   > OUTPUT/${DESIGN}_${STAGE}.shift.dft.sdc
write_sdc -mode DFT_CAPTURE_MODE > OUTPUT/${DESIGN}_${STAGE}.capture.dft.sdc
write_scandef                    > OUTPUT/$STAGE/${DESIGN}_${STAGE}.dft.scanDEF
write_dft_atpg -directory atpg -library $PRIMITIVES
write_dft_abstract_model
write_hdl -abstract
write_script -analyze_all_scan_chains
} else {
write_hdl                        > OUTPUT/$STAGE/${DESIGN}_${STAGE}.v
write_sdc -view FUNCTIONAL       > OUTPUT/${DESIGN}_${STAGE}.pnr.sdc
}
# Final LEC
if { $DFT_FLOW } {
write_do_lec -golden_design fv_map -revised_design OUTPUT/opt/${DESIGN}_opt.dft.v -logfile LOG/intermediate2final.dft.lec.log > OUTPUT/intermediate2final.dft.lec.do
write_do_lec -golden_design rtl    -revised_design OUTPUT/opt/${DESIGN}_opt.dft.v -logfile LOG/rtl2final.dft.lec.log          > OUTPUT/rtl2final.dft.lec.do
} else {
write_do_lec -golden_design fv_map -revised_design OUTPUT/opt/${DESIGN}_opt.v -logfile LOG/intermediate2final.lec.log > OUTPUT/intermediate2final.lec.do
write_do_lec -golden_design rtl    -revised_design OUTPUT/opt/${DESIGN}_opt.v -logfile LOG/rtl2final.lec.log          > OUTPUT/rtl2final.lec.do
}

if { $DFT_FLOW } {
exec >&@stdout modus -f ./atpg/runmodus.atpg.tcl
exec >&@stdout ./atpg/run_fullscan_sim
exit
} else {
exit
}

