VIVADO_PATH = ${VIVADO_PATH}

all: ./build/out.bit

./build/out.bit: buildFolder
	$(VIVADO_PATH)/vivado  -mode batch -nolog -nojournal -source run.tcl
buildFolder:
	mkdir -p build

clean:
	rm -rf build

flash:
	$(VIVADO_PATH)/vivado  -mode batch -nolog -nojournal -source flash.tcl

run_all: ./build/out.bit flash