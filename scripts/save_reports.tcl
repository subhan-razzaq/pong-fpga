# save_reports.tcl
# Usage (in the Tcl Console, after implementation):
#   source C:/pong/scripts/save_reports.tcl
#   save_reports 01_vga_test_pattern

proc save_reports {milestone} {
    # Open the implemented design if it isn't already open
    if {[catch {current_design}]} {
        open_run impl_1
    }

    # Build the output path from the project location
    set proj_dir [get_property DIRECTORY [current_project]]
    set rpt_dir  [file normalize $proj_dir/../reports/$milestone]
    file mkdir $rpt_dir

    report_utilization    -file $rpt_dir/util.rpt
    report_timing_summary -file $rpt_dir/timing.rpt

    puts "Reports saved to $rpt_dir"
}