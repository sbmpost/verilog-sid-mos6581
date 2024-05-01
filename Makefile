# Project setup
PROJ      = sid_top
BUILD     = ./build
DEVICE    = 8k
FOOTPRINT = ct256

# Files
FILES = sid_top.sv sid_mem16.sv mos6581.sv sid_voice.sv clk_div.sv reset_filter.sv sid_acc.sv sid_env.sv sid_filter.sv sid_wave.sv sigma_delta.sv uart_rx.sv pll.sv

.PHONY: all clean burn

#	yosys -p "synth_ice40 -top sid_top -blif $(BUILD)/$(PROJ).blif" $(FILES)
#	arachne-pnr -d $(DEVICE) -P $(FOOTPRINT) -o $(BUILD)/$(PROJ).asc -p sid_top.pcf $(BUILD)/$(PROJ).blif

all:
	# if build folder doesn't exist, create it
	mkdir -p $(BUILD)
	# synthesize using Yosys
	yosys -q -p "synth_ice40 -top sid_top -json $(BUILD)/$(PROJ).json" $(FILES)
	# Place and route using Nextpnr
	nextpnr-ice40 --hx8k --package $(FOOTPRINT) --json $(BUILD)/$(PROJ).json --asc $(BUILD)/$(PROJ).asc --pcf sid_top.pcf
	# Convert to bitstream using IcePack
	icepack $(BUILD)/$(PROJ).asc $(BUILD)/$(PROJ).bin

burn:
	iceprog -S $(BUILD)/$(PROJ).bin

clean:
	rm -f build/*
