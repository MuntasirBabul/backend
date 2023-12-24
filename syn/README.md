# Synthesis Flow
This is the basic simple synthesis flow


```
set_db /                .library    <list of liberty files>
set_db /            .lef_library    <list of lef files>
read_hdl                            <list of RTL files>
set_db /      .information_level    7
set_db hdl_track_filename_row_col true
```

```
# Check the Design for any unresolved reference, blackbox's.
check_design -all
# Create Default Timing Mode
create_mode -default -name FUNCTIONAL
# Set Timing and Design Constraints
read_sdc -mode FUNCTIONAL ../design_data/constraints/8T_funcRBB0_SSG.sdc
```
