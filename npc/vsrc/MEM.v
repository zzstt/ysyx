module MEM (
    input           clk,
    input           resetn,
    output          mem_allow,
    input           exe_to_mem_valid,
    input   [102:0] exe_to_mem_data,
    output          mem_to_wb_valid,
    input           wb_allow,
    output  [101:0] mem_to_wb_data,
    input   [ 31:0] data_sram_rdata,
    output  [ 5:0]  mem_wr
);
    reg             mem_valid;
    wire            mem_ready;
    wire    [ 31:0] mem_pc;
    wire    [ 31:0] mem_inst;
    reg     [102:0] reg_exe_to_mem_data;
    wire            gr_we;
    wire            res_from_mem;
    wire    [  4:0] dest;
    wire    [ 31:0] alu_result;
    wire    [ 31:0] final_result;
    
    //state
    assign  mem_ready = 1'b1;
    assign  mem_to_wb_valid = mem_ready & mem_valid;
    assign  mem_allow = mem_to_wb_valid & wb_allow | ~mem_valid;
    always @(posedge clk ) begin
        if (~resetn) begin
            mem_valid <= 1'b0;
        end
        else if(mem_allow) begin
            mem_valid <= exe_to_mem_valid;
        end
    end
    
    //data
    always @(posedge clk ) begin
        if (exe_to_mem_valid & mem_allow) begin
            reg_exe_to_mem_data <= exe_to_mem_data;
        end
    end
    assign {gr_we, res_from_mem, dest,mem_pc, mem_inst, alu_result} = reg_exe_to_mem_data;
    assign  final_result = res_from_mem ? data_sram_rdata : alu_result;
    assign  mem_to_wb_data = {gr_we, mem_pc, mem_inst, final_result, dest};
    
    //wr
    assign mem_wr = {(mem_valid & gr_we), dest};
endmodule