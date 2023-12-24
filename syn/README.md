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
syn_generic
syn_map
syn_opt

