ifndef VIVADO_PATH
	VIVADO=vivado
else
	VIVADO=$(VIVADO_PATH)/vivado
endif

all: ./build/out.bit

./build/out.bit: buildFolder
	$(VIVADO) -mode batch -nolog -nojournal -source run.tcl
buildFolder:
	mkdir -p build
	mkdir -p reports

clean:
	rm -rf build
	rm -rf clockInfo.txt
	rm -rf .Xil
	rm -rf reports

load:
	openFPGALoader -b nexys_a7_100 ./build/out.bit

flash:
	openFPGALoader -b nexys_a7_100 -f ./build/out.bit

run_all: ./build/out.bit load
