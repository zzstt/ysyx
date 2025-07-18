module mycpu_top(
    input  wire        clk,
    input  wire        resetn,
    output wire        inst_sram_en,
    output wire [ 3:0] inst_sram_we,
    output wire [31:0] inst_sram_addr,
    output wire [31:0] inst_sram_wdata,
    input  wire [31:0] inst_sram_rdata,
    output wire        data_sram_en,
    output wire [ 3:0] data_sram_we,
    output wire [31:0] data_sram_addr,
    output wire [31:0] data_sram_wdata,
    input  wire [31:0] data_sram_rdata,
    output wire [31:0] debug_wb_pc,
    output wire [ 3:0] debug_wb_rf_we,
    output wire [ 4:0] debug_wb_rf_wnum,
    output wire [31:0] debug_wb_rf_wdata
);
    wire            id_allow;
    wire            if_to_id_valid;
    wire    [ 63:0] if_to_id_data;
    wire    [ 32:0] id_to_if_data;
    wire            exe_allow;
    wire            id_to_exe_valid;
    wire    [179:0] id_to_exe_data;
    wire    [ 37:0] wb_to_id_data;
    wire    [102:0] exe_to_mem_data;
    wire            exe_to_mem_valid;
    wire            mem_allow;
    wire            mem_to_wb_valid;
    wire    [101:0] mem_to_wb_data;
    wire            wb_allow;
    wire    [  5:0] exe_wr;
    wire    [  5:0] mem_wr;
    wire    [  5:0] wb_wr;

    IF my_IF (
        .clk(clk),
        .resetn(resetn),
        .id_allow(id_allow),
        .if_to_id_valid(if_to_id_valid),
        .if_to_id_data(if_to_id_data),
        .id_to_if_data(id_to_if_data),
        .inst_sram_en(inst_sram_en),
        .inst_sram_we(inst_sram_we),
        .inst_sram_addr(inst_sram_addr),
        .inst_sram_rdata(inst_sram_rdata),
        .inst_sram_wdata(inst_sram_wdata)
    );

    ID my_ID (
        .clk(clk),
        .resetn(resetn),
        .if_to_id_valid(if_to_id_valid),
        .id_allow(id_allow),
        .if_to_id_data(if_to_id_data),
        .id_to_if_data(id_to_if_data),
        .exe_allow(exe_allow),
        .id_to_exe_valid(id_to_exe_valid),
        .id_to_exe_data(id_to_exe_data),
        .wb_to_id_data(wb_to_id_data),
        .exe_wr(exe_wr),
        .mem_wr(mem_wr),
        .wb_wr(wb_wr)
    );

    EXE my_EXE (
        .clk(clk),
        .resetn(resetn),
        .exe_allow(exe_allow),
        .id_to_exe_valid(id_to_exe_valid),
        .id_to_exe_data(id_to_exe_data),
        .exe_to_mem_valid(exe_to_mem_valid),
        .mem_allow(mem_allow),
        .exe_to_mem_data(exe_to_mem_data),
        .data_sram_en(data_sram_en),
        .data_sram_we(data_sram_we),
        .data_sram_addr(data_sram_addr),
        .data_sram_wdata(data_sram_wdata),
        .exe_wr(exe_wr)
    );

    MEM my_MEM (
        .clk(clk),
        .resetn(resetn),
        .mem_allow(mem_allow),
        .exe_to_mem_valid(exe_to_mem_valid),
        .exe_to_mem_data(exe_to_mem_data),
        .mem_to_wb_valid(mem_to_wb_valid),
        .wb_allow(wb_allow),
        .mem_to_wb_data(mem_to_wb_data),
        .data_sram_rdata(data_sram_rdata),
        .mem_wr(mem_wr)
    );

    WB my_WB (
        .clk(clk),
        .resetn(resetn),
        .wb_allow(wb_allow),
        .mem_to_wb_valid(mem_to_wb_valid),
        .mem_to_wb_data(mem_to_wb_data),
        .wb_to_id_data(wb_to_id_data),
        .debug_wb_pc(debug_wb_pc),
        .debug_wb_rf_we(debug_wb_rf_we),
        .debug_wb_rf_wnum(debug_wb_rf_wnum),
        .debug_wb_rf_wdata(debug_wb_rf_wdata),
        .wb_wr(wb_wr)
    );
endmodule