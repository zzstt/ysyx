VERILATOR = verilator
TOP_MODULE = top
VSRC_DIR = vsrc
CSRC_DIR = csrc
OBJ_DIR = obj_dir
INCLUDE_DIR = include

VERILOG_SOURCES = $(shell find $(VSRC_DIR) -name "*.v" 2>/dev/null)
VERILOG_HEADERS = $(shell find $(INCLUDE_DIR) -name "*.vh" 2>/dev/null)
CPP_HEADERS = $(shell find $(INCLUDE_DIR) -name "*.h" 2>/dev/null)
CSRC_SOURCES = $(shell find $(CSRC_DIR) -name "*.cpp" 2>/dev/null)

INCLUDE_PATHS = -I$(VSRC_DIR) -I$(INCLUDE_DIR)
CFLAGS = -I$(CSRC_DIR) -I$(INCLUDE_DIR)

VERILATOR_FLAGS = --trace-fst --timescale 1ps/1ps --cc
VERILATOR_FLAGS += --exe

VERILATOR_FLAGS += $(INCLUDE_PATHS)
VERILATOR_FLAGS += -CFLAGS "$(CFLAGS)"
VERILATOR_FLAGS += -LDFLAGS "-lz"

debug:
	@echo "INCLUDE_DIR: $(INCLUDE_DIR)"
	@echo "VERILOG_HEADERS: $(VERILOG_HEADERS)"
	@echo "CPP_HEADERS: $(CPP_HEADERS)"
	@echo "CSRC_SOURCES: $(CSRC_SOURCES)"
	@echo "VERILOG_SOURCES: $(VERILOG_SOURCES)"

all:
	@echo "Use 'make sim' to run simulation"
	@echo "Use 'make wave' to view waveforms"
	@echo "Clean with 'make clean'"
	@echo "Use 'make debug' to show file paths"

sim: $(OBJ_DIR)/V$(TOP_MODULE)
	@echo "Starting simulation..."
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	@$(OBJ_DIR)/V$(TOP_MODULE) 2>&1 | tee sim.log
	@echo "Simulation complete. Output in sim.log"

$(OBJ_DIR)/V$(TOP_MODULE): $(VERILOG_SOURCES) $(VERILOG_HEADERS) $(CSRC_SOURCES) $(CPP_HEADERS)
	@echo "Building with Verilator..."
	@echo "Verilog headers found: $(words $(VERILOG_HEADERS)) files"
	@echo "C++ headers found: $(words $(CPP_HEADERS)) files"
	$(VERILATOR) $(VERILATOR_FLAGS) \
		--top-module $(TOP_MODULE) \
		$(VERILOG_SOURCES) \
		$(CSRC_SOURCES)
	$(MAKE) -C $(OBJ_DIR) -f V$(TOP_MODULE).mk

wave:
	gtkwave wave.fst &

clean:
	rm -rf $(OBJ_DIR) sim.log wave.fst wave.vcd

include ../Makefile

.PHONY: all sim wave clean debug