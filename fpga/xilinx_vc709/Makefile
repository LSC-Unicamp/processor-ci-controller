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

# openFPGALoader funciona apenas na versão nightly, a versão estavel atual não suporta a vc709 ainda
flash:
	@echo "Flashing the FPGA..."
	openFPGALoader -b vc709 ./build/out.bit
#$(VIVADO_PATH)/vivado  -mode batch -nolog -nojournal -source flash.tcl

run_all: ./build/out.bit flash