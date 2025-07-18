`include "param.vh"
module cpu(
    input         clk,
    input         rst,
    output[`w(`ADDR_WIDTH)]     pc,
    input[`w(`DATA_WIDTH)]      inst,

    input [`w(`DATA_WIDTH)]     rdata,
    output[`w(`DATA_WIDTH)]     wdata,
    output[`w(4)]               wmask,
    output[`w(`ADDR_WIDTH)]     addr,
    output                      mem_wen,
    output                      mem_valid
);
    reg [`w(`ADDR_WIDTH)]pc_reg;
    wire[`w(`ADDR_WIDTH)]pc_jump,pc_next,pc_4;
    always @(posedge clk ) begin
        if(rst)
            pc_reg <= 32'b0;
        else begin
            pc_reg <= pc_next;
        end 
    end
    
    assign pc = pc_reg;
    assign pc_4 = pc + 32'd4;
    assign pc_next = (inst_jalr)? pc_jump :pc_4;
    
    //ID

    wire[6:0] opcode ;
    wire[2:0] func3;
    wire[4:0] rs1,rs2,rd;
    wire[6:0] func7;
    wire[11:0] I_imm,S_imm;
    wire[31:0] U_imm;

    assign func3 = inst[14:12];
    assign opcode = inst[6:0];
    assign func7 = inst[31:25];
    assign rs1 = inst[19:15];
    assign rs2 = inst[24:20];
    assign rd  = inst[11:7];
    assign I_imm = inst[31:20];
    assign S_imm = {inst[31:25],inst[11:7]};
    assign U_imm = {inst[31:12],12'b0};
    
    
    wire inst_addi; 
    assign inst_addi = (opcode == 7'b0010011) && (func3 == 3'b000);
    wire inst_jalr;
    assign inst_jalr = (opcode == 7'b1100111) && (func3 == 3'b000);
    wire inst_add,inst_sub;
    assign inst_add =  (opcode == 7'b0110011) && (func3 == 3'b000) && (func7 == 0);
    assign inst_sub =  (opcode == 7'b0110011) && (func3 == 3'b000) && (func7 == 7'b0100000);
    wire inst_lui;
    assign inst_lui =  (opcode == 7'b0110111);
    wire inst_lw, inst_lbu;
    assign inst_lw =   (opcode == 7'b0000011) && (func3 == 3'b010);
    assign inst_lbu =  (opcode == 7'b0000011) && (func3 == 3'b100);
    wire inst_sw,inst_sh,inst_sb;
    assign inst_sw =   (opcode == 7'b0100011) && (func3 == 3'b010);
    assign inst_sb =   (opcode == 7'b0100011) && (func3 == 3'b000);
    wire inst_ebreak;//引用c函数
    assign inst_ebreak = inst == 32'h00100073;
    import "DPI-C" function void ebreak(input int inst);
    always @(*) begin
        if(inst_ebreak)ebreak(inst);
    end
    

    wire inst_I,inst_R,inst_S,inst_B,inst_U,inst_J;
    assign inst_U = opcode[4:0] == 5'b10111;
    assign inst_I = ({opcode[5],opcode[3:0]} == 5'b00011) | inst_jalr;
    assign inst_S = opcode == 7'b0100011;
    assign inst_B = opcode == 7'b1100011;
    assign inst_J = opcode == 7'b1101111;
    assign inst_R = opcode == 7'b0110011;

    wire inst_load;
    assign inst_load = opcode == 7'b0000011;

    //regfile
    wire rf_wen;
    wire[`w(`REG_ADDR_WIDTH)] rf_waddr,rf_raddr1,rf_raddr2;
    wire[`w(`DATA_WIDTH)] rf_wdata,rf_rdata1,rf_rdata2;
    assign rf_raddr1 = rs1;
    assign rf_raddr2 = rs2;
     
    regfile #(
        .REG_ADDR_WIDTH 	(5   ),
        .DATA_WIDTH     	(32  ),
        .REG_NUM        	(32  ))
    u_regfile(
        .clk    	(clk     ),
        .rst    	(rst     ),
        .wen    	(rf_wen     ),
        .waddr  	(rf_waddr   ),
        .wdata  	(rf_wdata   ),
        .raddr1 	(rf_raddr1  ),
        .rdata1 	(rf_rdata1  ),
        .raddr2 	(rf_raddr2  ),
        .rdata2 	(rf_rdata2  )
    );
    


    //ALU
    wire[`w(`DATA_WIDTH)] alu_src1,alu_src2,alu_result;
    wire[2:0]   alu_op;
    assign alu_src1 =  {32{inst_R | inst_I | inst_S}} & rf_rdata1
        ;
    assign alu_src2 = {32{inst_I}} & `EXTEND(I_imm,5'd12,1'd1)
        |{32{inst_R}} & rf_rdata2
        ;
    assign alu_op = inst_S|inst_load ? 3'b000:
        inst_sub ? 3'b101 :func3;//可能出错
    alu my_alu (
        .src1(alu_src1),
        .src2(alu_src2),
        .alu_op(alu_op), 
        .result(alu_result)
    );
    assign pc_jump = {alu_result[31:1],1'b0};
    
    //MEM
    assign mem_wen = inst_S;
    assign mem_valid = inst_load | inst_S;
    // assign addr = {32{inst_S | inst_load}} & {alu_result[31:2],2'b0};
    assign addr = {32{inst_S}} & alu_result
        |   {32{inst_load}} & {alu_result[31:2],2'b0};
    assign wdata = rf_rdata2;
    wire [`w(4)] wmask_b,wmask_h;
    assign wmask_b = {4{alu_result[1:0] == 2'b0}} & 4'b0001
        | {4{alu_result[1:0] == 2'b1}} & 4'b0010
        | {4{alu_result[1:0] == 2'b10}} & 4'b0100
        | {4{alu_result[1:0] == 2'b11}} & 4'b1000;
    assign wmask_h = {4{alu_result[1]}} & 4'b1100
        | {4{~alu_result[1]}} & 4'b0011;
    assign wmask = {4{inst_sb}} & wmask_b
        | {4{inst_sh}} & wmask_h
        | {4{inst_sw}} & 4'b1111;
    wire [31:0] load_data;
    assign load_data = {32{inst_lbu}} & `EXTEND(rdata[7:0],6'd8,1'b0)
        | {32{inst_lw}} & rdata;

    //WB
    assign rf_wen = inst_I | inst_lui;
    assign rf_waddr = (inst_I|inst_lui) ? rd :0;
    assign rf_wdata = inst_addi ? alu_result:
        inst_jalr ? pc_4:
        inst_load ? load_data:
        inst_lui  ? U_imm:0;
endmodule
