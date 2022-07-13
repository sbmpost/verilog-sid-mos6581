# Project setup
PROJ      = sid_top
BUILD     = ./build
DEVICE    = 8k
FOOTPRINT = ct256

# Files
FILES = sid_top.sv mos6581.sv clk_div.sv reset_filter.sv sid_acc.sv sid_env.sv sid_filter.sv sid_wave.sv sigma_delta.sv uart_rx.sv pll.sv

.PHONY: all clean burn

all:
	# if build folder doesn't exist, create it
	mkdir -p $(BUILD)
	# synthesize using Yosys
	yosys -p "synth_ice40 -top sid_top -blif $(BUILD)/$(PROJ).blif" $(FILES)
	# Place and route using arachne
	arachne-pnr -d $(DEVICE) -P $(FOOTPRINT) -o $(BUILD)/$(PROJ).asc -p sid_top.pcf $(BUILD)/$(PROJ).blif
	# Convert to bitstream using IcePack
	icepack $(BUILD)/$(PROJ).asc $(BUILD)/$(PROJ).bin

burn:
	iceprog -S $(BUILD)/$(PROJ).bin

clean:
	rm -f build/*
