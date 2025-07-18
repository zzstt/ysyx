# File: npc/Makefile

# 基本配置
VERILATOR = verilator
TOP_MODULE = top
VSRC_DIR = vsrc
CSRC_DIR = csrc
OBJ_DIR = obj_dir
INCLUDE_DIR = include  # 头文件目录

# 自动查找源文件 - 使用 shell find 替代 wildcard
VERILOG_SOURCES = $(shell find $(VSRC_DIR) -name "*.v" 2>/dev/null)
VERILOG_HEADERS = $(shell find $(INCLUDE_DIR) -name "*.vh" 2>/dev/null)  # 只查找 include 目录
CPP_HEADERS = $(shell find $(INCLUDE_DIR) -name "*.h" 2>/dev/null)  # C++ 头文件
CSRC_SOURCES = $(shell find $(CSRC_DIR) -name "*.cpp" 2>/dev/null)

# 获取包含路径
INCLUDE_PATHS = -I$(VSRC_DIR) -I$(INCLUDE_DIR)
CFLAGS = -I$(CSRC_DIR) -I$(INCLUDE_DIR)

# Verilator 编译选项
VERILATOR_FLAGS = --trace-fst --timescale 1ps/1ps --cc
VERILATOR_FLAGS += --exe
# 添加头文件搜索路径
VERILATOR_FLAGS += $(INCLUDE_PATHS)  # Verilog 头文件路径
VERILATOR_FLAGS += -CFLAGS "$(CFLAGS)"  # C++ 头文件路径
VERILATOR_FLAGS += -LDFLAGS "-lz"

# 调试目标 - 显示找到的文件
debug:
	@echo "INCLUDE_DIR: $(INCLUDE_DIR)"
	@echo "VERILOG_HEADERS: $(VERILOG_HEADERS)"
	@echo "CPP_HEADERS: $(CPP_HEADERS)"
	@echo "CSRC_SOURCES: $(CSRC_SOURCES)"
	@echo "VERILOG_SOURCES: $(VERILOG_SOURCES)"

# 默认目标
all:
	@echo "Use 'make sim' to run simulation"
	@echo "Use 'make wave' to view waveforms"
	@echo "Clean with 'make clean'"
	@echo "Use 'make debug' to show file paths"

# 仿真目标
sim: $(OBJ_DIR)/V$(TOP_MODULE)
	@echo "Starting simulation..."
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	@$(OBJ_DIR)/V$(TOP_MODULE) 2>&1 | tee sim.log
	@echo "Simulation complete. Output in sim.log"

# 构建 Verilator 可执行文件
$(OBJ_DIR)/V$(TOP_MODULE): $(VERILOG_SOURCES) $(VERILOG_HEADERS) $(CSRC_SOURCES) $(CPP_HEADERS)
	@echo "Building with Verilator..."
	@echo "Verilog headers found: $(words $(VERILOG_HEADERS)) files"
	@echo "C++ headers found: $(words $(CPP_HEADERS)) files"
	$(VERILATOR) $(VERILATOR_FLAGS) \
		--top-module $(TOP_MODULE) \
		$(VERILOG_SOURCES) \
		$(CSRC_SOURCES)
	$(MAKE) -C $(OBJ_DIR) -f V$(TOP_MODULE).mk

# 查看波形
wave:
	gtkwave wave.fst &

# 清理
clean:
	rm -rf $(OBJ_DIR) sim.log wave.fst wave.vcd

# 包含上级 Makefile
include ../Makefile

.PHONY: all sim wave clean debug