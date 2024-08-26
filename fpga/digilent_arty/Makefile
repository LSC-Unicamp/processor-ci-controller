all: ./build/out.bit

./build/out.bit: buildFolder
	@echo "Building project..."
	vivado -mode batch -nolog -nojournal -source run.tcl
buildFolder:
	mkdir -p build

clean:
	@echo "Cleaning project..."
	rm -rf build
	rm -rf clockInfo.txt

flash:
	@echo "Flashing project..."
	openFPGALoader -b arty_a7_100t ./build/out.bit
# openFPGALoader -b arty_a7_100t ./build/out.bit --ftdi-serial 210319B57A9B

run_all: ./build/out.bit flash
	@echo "Running project..."