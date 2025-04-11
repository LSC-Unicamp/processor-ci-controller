yosys read_systemverilog -defer -I./ -I/eda/processadores/Grande-Risco-5/rtl/core ../../modules/Grande-Risco-5/rtl/core/grande_risco5_types.sv
yosys read_systemverilog -defer -I./ -I/eda/processadores/Grande-Risco-5/rtl/core ../../modules/Grande-Risco-5/rtl/core/alu_control.sv
yosys read_systemverilog -defer -I./ -I/eda/processadores/Grande-Risco-5/rtl/core ../../modules/Grande-Risco-5/rtl/core/alu.sv
yosys read_systemverilog -defer -I./ -I/eda/processadores/Grande-Risco-5/rtl/core ../../modules/Grande-Risco-5/rtl/core/bmu.sv
yosys read_systemverilog -defer -I./ -I/eda/processadores/Grande-Risco-5/rtl/core ../../modules/Grande-Risco-5/rtl/core/branch_prediction.sv
yosys read_systemverilog -defer -I./ -I/eda/processadores/Grande-Risco-5/rtl/core ../../modules/Grande-Risco-5/rtl/core/cache_request_multiplexer.sv
yosys read_systemverilog -defer -I./ -I/eda/processadores/Grande-Risco-5/rtl/core ../../modules/Grande-Risco-5/rtl/core/core.sv
yosys read_systemverilog -defer -I./ -I/eda/processadores/Grande-Risco-5/rtl/core ../../modules/Grande-Risco-5/rtl/core/csr_unit.sv
yosys read_systemverilog -defer -I./ -I/eda/processadores/Grande-Risco-5/rtl/core ../../modules/Grande-Risco-5/rtl/core/d_cache.sv
yosys read_systemverilog -defer -I./ -I/eda/processadores/Grande-Risco-5/rtl/core ../../modules/Grande-Risco-5/rtl/core/forwarding_unit.sv
yosys read_systemverilog -defer -I./ -I/eda/processadores/Grande-Risco-5/rtl/core ../../modules/Grande-Risco-5/rtl/core/fpu.sv
yosys read_systemverilog -defer -I./ -I/eda/processadores/Grande-Risco-5/rtl/core ../../modules/Grande-Risco-5/rtl/core/Grande_Risco5.sv
yosys read_systemverilog -defer -I./ -I/eda/processadores/Grande-Risco-5/rtl/core ../../modules/Grande-Risco-5/rtl/core/i_cache.sv
yosys read_systemverilog -defer -I./ -I/eda/processadores/Grande-Risco-5/rtl/core ../../modules/Grande-Risco-5/rtl/core/immediate_generator.sv
yosys read_systemverilog -defer -I./ -I/eda/processadores/Grande-Risco-5/rtl/core ../../modules/Grande-Risco-5/rtl/core/ir_decomp.sv
yosys read_systemverilog -defer -I./ -I/eda/processadores/Grande-Risco-5/rtl/core ../../modules/Grande-Risco-5/rtl/core/mdu.sv
yosys read_systemverilog -defer -I./ -I/eda/processadores/Grande-Risco-5/rtl/core ../../modules/Grande-Risco-5/rtl/core/mux.sv
yosys read_systemverilog -defer -I./ -I/eda/processadores/Grande-Risco-5/rtl/core ../../modules/Grande-Risco-5/rtl/core/registers.sv
yosys read_systemverilog -defer -I./ -I/eda/processadores/Grande-Risco-5/rtl/core ../../modules/Grande-Risco-5/rtl/core/IFID.sv
yosys read_systemverilog -defer -I./ -I/eda/processadores/Grande-Risco-5/rtl/core ../../modules/Grande-Risco-5/rtl/core/IDEX.sv
yosys read_systemverilog -defer -I./ -I/eda/processadores/Grande-Risco-5/rtl/core ../../modules/Grande-Risco-5/rtl/core/EXMEM.sv
yosys read_systemverilog -defer -I./ -I/eda/processadores/Grande-Risco-5/rtl/core ../../modules/Grande-Risco-5/rtl/core/MEMWB.sv
yosys read_systemverilog -defer -I./ -I/eda/processadores/Grande-Risco-5/rtl/core ../../modules/Grande-Risco-5/rtl/core/invalid_ir_check.sv
yosys read_systemverilog -defer -I./ -I/eda/processadores/Grande-Risco-5/rtl/core ../../examples/Grande-Risco-5.sv


yosys read_systemverilog -defer -I./ -I/eda/processadores/Grande-Risco-5/rtl/core main.sv
yosys read_systemverilog -defer -I./ -I/eda/processadores/Grande-Risco-5/rtl/core ../../modules/uart.sv
yosys read_systemverilog -defer -I./ -I/eda/processadores/Grande-Risco-5/rtl/core ../../modules/UART/rtl/uart_rx.v
yosys read_systemverilog -defer -I./ -I/eda/processadores/Grande-Risco-5/rtl/core ../../modules/UART/rtl/uart_tx.v
yosys read_systemverilog -defer -I./ -I/eda/processadores/Grande-Risco-5/rtl/core ../../rtl/fifo.sv
yosys read_systemverilog -defer -I./ -I/eda/processadores/Grande-Risco-5/rtl/core ../../rtl/reset.sv
yosys read_systemverilog -defer -I./ -I/eda/processadores/Grande-Risco-5/rtl/core ../../rtl/clk_divider.sv
yosys read_systemverilog -defer -I./ -I/eda/processadores/Grande-Risco-5/rtl/core ../../rtl/memory.sv
yosys read_systemverilog -defer -I./ -I/eda/processadores/Grande-Risco-5/rtl/core ../../rtl/interpreter.sv
yosys read_systemverilog -defer -I./ -I/eda/processadores/Grande-Risco-5/rtl/core ../../rtl/controller.sv

yosys read_systemverilog -link

yosys synth_ecp5 -json ./build/colorlight_i9.json -top top -abc9