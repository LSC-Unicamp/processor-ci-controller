


read_verilog -sv main.sv


set_param general.maxThreads 16

read_xdc "pinout.xdc"
set_property PROCESSING_ORDER EARLY [get_files pinout.xdc]

# synth
synth_design -top "top" -part "xc7z020clg484-1"

# place and route
opt_design
place_design

report_utilization -hierarchical -file reports/utilization_hierarchical_place.rpt
report_utilization               -file reports/utilization_place.rpt
report_io                        -file reports/io.rpt
report_control_sets -verbose     -file reports/control_sets.rpt
report_clock_utilization         -file reports/clock_utilization.rpt


route_design

report_timing_summary -no_header -no_detailed_paths
report_route_status                            -file reports/route_status.rpt
report_drc                                     -file reports/drc.rpt
report_timing_summary -datasheet -max_paths 10 -file reports/timing.rpt
report_power                                   -file reports/power.rpt


# write bitstream
write_bitstream -force "./build/out.bit"
