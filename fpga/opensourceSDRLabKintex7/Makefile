ifndef VIVADO_PATH
	VIVADO=vivado
else
	VIVADO=$(VIVADO_PATH)/vivado
endif

ifndef BISTREAM
	BISTREAM=./build/out.bit
else
	BISTREAM=$(BISTREAM)
endif

all: $(BISTREAM)

$(BISTREAM): buildFolder
	@echo "Building the project and Generate Bitstream..."
	$(VIVADO) -mode batch -nolog -nojournal -source run.tcl
	if [ -n "$(BISTREAM)" ] && [ "$(BISTREAM)" != "./build/out.bit" ]; then mv ./build/out.bit "$(BISTREAM)"; fi
	@echo "Bitstream generated at $(BISTREAM)"
	
buildFolder:
	@echo "Creating build and reports directories..."
	mkdir -p build
	mkdir -p reports

clean:
	@echo "Cleaning up build artifacts..."
	rm -rf build
	rm -rf clockInfo.txt
	rm -rf .Xil
	rm -rf reports

load:
	@echo "Loading the bitstream onto the FPGA..."
	openFPGALoader -b opensourceSDRLabKintex7 $(BISTREAM)

flash:
	@echo "Flashing the bitstream onto the FPGA..."
	openFPGALoader -b opensourceSDRLabKintex7 -f $(BISTREAM)

remote:
	@echo "Uploading the bitstream to a remote server..."
	./upload_remote.sh $(BISTREAM)
	@echo "Bitstream uploaded to remote server"

generate_ips:
	@echo "Generating IPs using vivado"
	mkdir -p ip
	$(VIVADO) -mode batch -nolog -nojournal -source generate_ip.tcl

remove_ips:
	@echo "Deleting IPs"
	rm -rf ip ip_project

help:
	@echo "Usage: make [target]"
	@echo "Targets:"
	@echo "  all         - Build the project and generate the bitstream"
	@echo "  clean       - Remove build artifacts"
	@echo "  load        - Load the bitstream onto the FPGA"
	@echo "  flash       - Flash the bitstream onto the FPGA"
	@echo "  remote      - Upload the bitstream to a remote server"
	@echo "  generate_ip - Generate IPs used in project"
	@echo "  help        - Show this help message"

run_all: $(BISTREAM) load
