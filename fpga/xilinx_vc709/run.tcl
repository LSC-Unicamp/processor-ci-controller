read_verilog "main.v"
read_verilog ../src/uart.v
read_verilog ../src/uart_rx.v
read_verilog ../src/uart_tx.v
read_verilog ../src/fifo.v
read_verilog ../src/reset.v
read_verilog ../src/clk_divider.v
read_verilog ../src/memory.v
read_verilog ../src/interpreter.v
read_verilog ../src/controller.v

read_xdc "pinout.xdc"
set_property PROCESSING_ORDER EARLY [get_files pinout.xdc]

# synth
synth_design -top "top" -part "xc7vx690tffg1761-2"

# place and route
opt_design
place_design

report_utilization -hierarchical -file virtex_utilization_hierarchical_place.rpt
report_utilization -file virtex_utilization_place.rpt
report_io -file virtex_io.rpt
report_control_sets -verbose -file virtex_control_sets.rpt
report_clock_utilization -file virtex_clock_utilization.rpt

route_design

report_timing_summary -no_header -no_detailed_paths
report_route_status -file virtex_route_status.rpt
report_drc -file virtex_drc.rpt
report_timing_summary -datasheet -max_paths 10 -file virtex_timing.rpt
report_power -file virtex_power.rpt

# write bitstream
write_bitstream -force "./build/out.bit"

exit