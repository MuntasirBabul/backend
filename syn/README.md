# Synthesis Flow
This is the basic simple synthesis flow
`

```set_db /                .library    $LIB_FILES
set_db /            .lef_library    $LEF_FILES
read_hdl                            $RTL_FILES
set_db /      .information_level    7
set_db hdl_track_filename_row_col true```
