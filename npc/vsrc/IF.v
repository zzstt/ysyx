module IF (
    input           clk,
    input           resetn,
    input           id_allow,
    output          if_to_id_valid,
    output  [63:0]  if_to_id_data,//if_pc+if_inst
    input   [32:0]  id_to_if_data,//br_taken+br_target
    output          inst_sram_en,
    output  [3:0]   inst_sram_we,
    output  [31:0]  inst_sram_addr,
    output  [31:0]  inst_sram_wdata,
    input   [31:0]  inst_sram_rdata
);
    reg             if_valid;
    wire            if_ready;
    wire            if_allow;
    wire            br_taken;
    reg     [31:0]  if_pc;
    wire    [31:0]  if_inst;
    wire    [31:0]  seq_pc;
    wire    [31:0]  next_pc;
    wire    [31:0]  br_target;

    //state
    assign  if_ready = 1'b1;
    assign  if_allow = ~resetn | if_ready & id_allow;
    always @(posedge clk ) begin
        if(~resetn)begin
            if_valid <= 1'b0;
        end
        else if(if_allow)begin
            if_valid <= 1'b1;
        end
        else if(br_taken)begin
            if_valid <= 1'b0;
        end
    end
    assign  if_to_id_valid = if_ready & if_valid;
    assign  if_to_id_data = { if_pc, if_inst };

    //pc
    assign  seq_pc = if_pc + 3'h4;
    assign  { br_taken, br_target } = id_to_if_data;
    assign  next_pc = br_taken ? br_target : seq_pc;
    always @(posedge clk ) begin
        if(~resetn)begin
            if_pc <= 32'h1bfffffc;
        end
        else if(if_allow)begin
            if_pc <= next_pc;
        end
    end

    //inst
    assign  inst_sram_en = if_allow;
    assign  inst_sram_addr = next_pc;
    assign  if_inst = inst_sram_rdata;
    assign  inst_sram_we = 4'b0;
    assign  inst_sram_wdata = 32'b0;
endmodule