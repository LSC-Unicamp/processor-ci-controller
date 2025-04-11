all: ./build/colorlight_i9.bit

./build/colorlight_i9.bit: ./build/colorlight_i9.config
	ecppack --compress --input ./build/colorlight_i9.config  --bit ./build/colorlight_i9.bit

./build/colorlight_i9.config: ./build/colorlight_i9.json
	nextpnr-ecp5 --json ./build/colorlight_i9.json --write ./build/colorlight_i9_pnr.json --45k \
		--lpf pinout.lpf --textcfg ./build/colorlight_i9.config --package CABGA381 \
		--speed 6 --lpf-allow-unconstrained

./build/colorlight_i9.json: buildFolder
	synlig -c run.tcl

clean:
	rm -rf build

load:
	openFPGALoader -b colorlight-i9 ./build/colorlight_i9.bit


buildFolder:
	mkdir -p build


run_all: colorlight_i9.bit load