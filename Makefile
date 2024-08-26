all:controller

controller: buildFolder src/controller.v tests/controller_test.v
	@echo "Testing controller"
	iverilog -o build/controller.o -s controller_tb src/clk_divider.v src/controller.v src/fifo.v \
	src/interpreter.v src/memory.v src/reset.v src/uart_rx.v src/uart_tx.v src/uart.v tests/controller_test.v
	vvp build/controller.o

fifo: buildFolder src/fifo.v tests/fifo_test.v
	@echo "Testing fifo"
	iverilog -o build/fifo.o -s fifo_tb src/fifo.v tests/fifo_test.v
	vvp build/fifo.o

clk_divider: buildFolder src/clk_divider.v tests/clk_divider_test.v
	@echo "Testing clk_divider"
	iverilog -o build/clk_divider.o -s clk_divider_tb src/clk_divider.v tests/clk_divider_test.v
	vvp build/clk_divider.o

reset_test: buildFolder src/reset.v tests/reset_test.v
	@echo "Testing reset"
	iverilog -o build/reset.o -s reset_tb src/reset.v tests/reset_test.v
	vvp build/reset.o

buildFolder:
	mkdir -p build

clean:
	rm -rf build