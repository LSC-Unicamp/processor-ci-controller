read_verilog -sv ../../modules/Grande-Risco-5/rtl/core/grande_risco5_types.sv
read_verilog -sv ../../modules/Grande-Risco-5/rtl/core/alu_control.sv
read_verilog -sv ../../modules/Grande-Risco-5/rtl/core/alu.sv
read_verilog -sv ../../modules/Grande-Risco-5/rtl/core/bmu.sv
read_verilog -sv ../../modules/Grande-Risco-5/rtl/core/branch_prediction.sv
read_verilog -sv ../../modules/Grande-Risco-5/rtl/core/cache_request_multiplexer.sv
read_verilog -sv ../../modules/Grande-Risco-5/rtl/core/core.sv
read_verilog -sv ../../modules/Grande-Risco-5/rtl/core/csr_unit.sv
read_verilog -sv ../../modules/Grande-Risco-5/rtl/core/d_cache.sv
read_verilog -sv ../../modules/Grande-Risco-5/rtl/core/forwarding_unit.sv
read_verilog -sv ../../modules/Grande-Risco-5/rtl/core/fpu.sv
read_verilog -sv ../../modules/Grande-Risco-5/rtl/core/Grande_Risco5.sv
read_verilog -sv ../../modules/Grande-Risco-5/rtl/core/i_cache.sv
read_verilog -sv ../../modules/Grande-Risco-5/rtl/core/immediate_generator.sv
read_verilog -sv ../../modules/Grande-Risco-5/rtl/core/ir_decomp.sv
read_verilog -sv ../../modules/Grande-Risco-5/rtl/core/mdu.sv
read_verilog -sv ../../modules/Grande-Risco-5/rtl/core/mux.sv
read_verilog -sv ../../modules/Grande-Risco-5/rtl/core/registers.sv
read_verilog -sv ../../modules/Grande-Risco-5/rtl/core/IFID.sv
read_verilog -sv ../../modules/Grande-Risco-5/rtl/core/IDEX.sv
read_verilog -sv ../../modules/Grande-Risco-5/rtl/core/EXMEM.sv
read_verilog -sv ../../modules/Grande-Risco-5/rtl/core/MEMWB.sv
read_verilog -sv ../../modules/Grande-Risco-5/rtl/core/invalid_ir_check.sv


read_verilog -sv main.sv
read_verilog -sv ../../modules/uart.sv
read_verilog ../../modules/UART/rtl/uart_rx.v
read_verilog ../../modules/UART/rtl/uart_tx.v
read_verilog -sv ../../rtl/fifo.sv
read_verilog -sv ../../rtl/reset.sv
read_verilog -sv ../../rtl/clk_divider.sv
read_verilog -sv ../../rtl/memory.sv
read_verilog -sv ../../rtl/interpreter.sv
read_verilog -sv ../../rtl/controller.sv
read_verilog -sv ../../rtl/timer.sv

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

exit
