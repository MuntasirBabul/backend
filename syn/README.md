# Synthesis Flow
This is the basic simple synthesis flow


Read lib, lef and RTL files
```
set_db /                .library    <list of liberty files>
set_db /            .lef_library    <list of lef files>
read_hdl                            <list of RTL files>
set_db /      .information_level    7
set_db hdl_track_filename_row_col true
```

Check the Design for any unresolved reference, blackbox's.
```
check_design -all
```
Set Constraints
```
create_mode -default -name FUNCTIONAL
read_sdc -mode FUNCTIONAL <sdc file path>
```

```
elaborate
syn_generic
syn_map
write_do_lec -golden_design rtl -revised_design fv_map -logfile LOG/rtl2intermediate.lec.log     > OUTPUT/rtl2intermediate.lec.do
syn_opt
```

```
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
write_do_lec -golden_design fv_map -revised_design OUTPUT/opt/${DESIGN}_opt.v -logfile LOG/intermediate2final.lec.log > OUTPUT/intermediate2final.lec.do
write_do_lec -golden_design rtl    -revised_design OUTPUT/opt/${DESIGN}_opt.v -logfile LOG/rtl2final.lec.log          > OUTPUT/rtl2final.lec.do
