read_verilog "main.v"
read_verilog ../../modules/uart.v
read_verilog ../../modules/UART/rtl/uart_rx.v
read_verilog ../../modules/UART/rtl/uart_tx.v
read_verilog ../../src/fifo.v
read_verilog ../../src/reset.v
read_verilog ../../src/clk_divider.v
read_verilog ../../src/memory.v
read_verilog ../../src/interpreter.v
read_verilog ../../src/controller.v


read_xdc "digilent_nexys4_ddr.xdc"
set_property PROCESSING_ORDER EARLY [get_files digilent_nexys4_ddr.xdc]

# synth
synth_design -top "top" -part "xc7a100tcsg324-1"

# place and route
opt_design
place_design

report_utilization -hierarchical -file digilent_nexys4ddr_utilization_hierarchical_place.rpt
report_utilization -file digilent_nexys4ddr_utilization_place.rpt
report_io -file digilent_nexys4ddr_io.rpt
report_control_sets -verbose -file digilent_nexys4ddr_control_sets.rpt
report_clock_utilization -file digilent_nexys4ddr_clock_utilization.rpt

route_design

report_timing_summary -no_header -no_detailed_paths
report_route_status -file digilent_nexys4ddr_route_status.rpt
report_drc -file digilent_nexys4ddr_drc.rpt
report_timing_summary -datasheet -max_paths 10 -file digilent_nexys4ddr_timing.rpt
report_power -file digilent_nexys4ddr_power.rpt

# write bitstream
write_bitstream -force "./build/out.bit"