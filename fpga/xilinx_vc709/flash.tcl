# Inicializar o hardware
open_hw
connect_hw_server
open_hw_target

#current_hw_target [get_hw_targets */210203A7C2EE*]

# Programar a FPGA com o bitstream
set_property PROGRAM.FILE ./build/out.bit [current_hw_device]
program_hw_devices [current_hw_device]

# Fechar conexões e projeto
close_hw_target
close_hw