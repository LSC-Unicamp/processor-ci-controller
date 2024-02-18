set_device -name GW2AR-18C GW2AR-LV18QN88C8/I7
add_file fpga/tangnano20k/pinout.cst
add_file fpga/tangnano20k/top.sdc
add_file fpga/tangnano20k/main.v

set_option -use_mspi_as_gpio 1
set_option -use_sspi_as_gpio 1
set_option -use_ready_as_gpio 1
set_option -use_done_as_gpio 1
set_option -rw_check_on_ram 1
run all