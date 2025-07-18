module EXE (
    input           clk,
    input           resetn,
    output          exe_allow,
    input           id_to_exe_valid,
    input   [179:0] id_to_exe_data,
    output          exe_to_mem_valid,
    input           mem_allow,
    output  [102:0] exe_to_mem_data,
    output          data_sram_en,
    output  [ 3:0]  data_sram_we,
    output  [31:0]  data_sram_addr,
    output  [31:0]  data_sram_wdata,
    output  [ 5:0]  exe_wr
);
    reg             exe_valid;
    wire            exe_ready;
    wire    [ 31:0] exe_inst;
    wire    [ 31:0] exe_pc;
    reg     [179:0] reg_id_to_exe_data;
    
    assign  exe_ready = 1'b1;
    assign  exe_to_mem_valid = exe_ready & exe_valid;
    assign  exe_allow = exe_to_mem_valid & mem_allow | ~exe_valid;
    always @(posedge clk ) begin
        if (~resetn) begin
            exe_valid <= 1'b0;
        end
        else if(exe_allow) begin
            exe_valid <= id_to_exe_valid;
        end
    end
    always @(posedge clk ) begin
        if (id_to_exe_valid & exe_allow) begin
            reg_id_to_exe_data <= id_to_exe_data; 
        end
    end
    
    //data
    wire            gr_we;
    wire            mem_we;
    wire            res_from_mem;
    wire    [11:0]  alu_op;
    wire    [31:0]  alu_src1;
    wire    [31:0]  alu_src2;
    wire    [ 4:0]  dest;
    wire    [31:0]  rkd_value;
    wire    [31:0]  alu_result;
    assign {gr_we, mem_we, res_from_mem,alu_op, alu_src1, alu_src2,dest, rkd_value, exe_inst, exe_pc} = reg_id_to_exe_data;
    assign  data_sram_en = 1'b1;
    assign  data_sram_we = {4{mem_we}};
    assign  data_sram_addr = alu_result;
    assign  data_sram_wdata = rkd_value;
    assign exe_to_mem_data = {gr_we, res_from_mem, dest,exe_pc, exe_inst, alu_result};

    //alu
    alu my_alu (
        .alu_op(alu_op),
        .alu_src1(alu_src1),
        .alu_src2(alu_src2),
        .alu_result(alu_result)
    );
    
    //wr
    assign exe_wr = {(exe_valid & gr_we), dest};
endmodule