module WB (
    input           clk,
    input           resetn,
    output          wb_allow,
    input           mem_to_wb_valid,
    input   [101:0] mem_to_wb_data,
    output  [ 37:0] wb_to_id_data,
    output  [ 31:0] debug_wb_pc,
    output  [  3:0] debug_wb_rf_we,
    output  [  4:0] debug_wb_rf_wnum,
    output  [ 31:0] debug_wb_rf_wdata,
    output  [ 5:0]  wb_wr
);
    reg             wb_valid;
    reg     [101:0] reg_mem_to_wb_data;
    wire            wb_ready;
    wire            gr_we;
    wire            rf_we;
    wire    [ 31:0] wb_pc;
    wire    [ 31:0] wb_inst;
    wire    [ 31:0] final_result;
    wire    [  4:0] rf_waddr;
    wire    [ 31:0] rf_wdata;
    wire    [  4:0] dest;

    //state
    assign wb_ready = 1'b1;
    assign wb_allow = wb_ready | ~wb_valid;
    always @(posedge clk ) begin
        if (~resetn) begin
            wb_valid <= 1'b0;
        end
        else if (wb_allow) begin
            wb_valid <= mem_to_wb_valid;
        end
    end

    //data
    always @(posedge clk ) begin
        if (mem_to_wb_valid & wb_allow) begin
            reg_mem_to_wb_data <= mem_to_wb_data;
        end
    end
    assign  {gr_we, wb_pc, wb_inst, final_result, dest} = reg_mem_to_wb_data;
    assign  rf_we = wb_valid & gr_we;
    assign  rf_waddr = dest; 
    assign  rf_wdata = final_result;
    assign  wb_to_id_data = {rf_we, rf_waddr, rf_wdata};

    //debug
    assign  debug_wb_pc = wb_pc;
    assign  debug_wb_rf_we = {4{rf_we}};
    assign  debug_wb_rf_wnum = rf_waddr;
    assign  debug_wb_rf_wdata = final_result;
    
    //wr
    assign wb_wr = {(wb_valid & gr_we), dest};
endmodule