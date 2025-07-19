module top(
    input        clk,
    input        rst,

    //Instruction request channel
    output [31:0] PC,
    output        Inst_Req_Valid,
    input         Inst_Req_Ready,

    //Instruction response channel
    input  [31:0] Instruction,
    input         Inst_Valid,
    output        Inst_Ready,

    //Memory request channel
    output [31:0] Address,
    output        MemWrite,
    output [31:0] Write_data,
    output [3:0]  Write_strb,
    output        MemRead,
    input         Mem_Req_Ready,

    //Memory data response channel
    input  [31:0] Read_data,
    input         Read_data_Valid,
    output        Read_data_Ready,

    input         intr,
);

//important wire
reg [31:0] Valid_Instruction;
wire [6:0] funct7 = Valid_Instruction[31:25];
wire [4:0] rs2 = Valid_Instruction[24:20];
wire [4:0] rs1 = Valid_Instruction[19:15];
wire [2:0] funct3 = Valid_Instruction[14:12];
wire [4:0] rd = Valid_Instruction[11:7];
wire [6:0] opcode = Valid_Instruction[6:0];
wire [31:0] I_imm = {{20{Valid_Instruction[31]}},Valid_Instruction[31:20]};
wire [31:0] S_imm = {{20{Valid_Instruction[31]}},Valid_Instruction[31:25],Valid_Instruction[11:7]};
wire [31:0] B_imm = {{20{Valid_Instruction[31]}},Valid_Instruction[7],Valid_Instruction[30:25],Valid_Instruction[11:8],1'b0};
wire [31:0] U_imm = {Valid_Instruction[31:12],12'b0};
wire [31:0] J_imm = {{12{Valid_Instruction[31]}},Valid_Instruction[19:12],Valid_Instruction[20],Valid_Instruction[30:25],Valid_Instruction[24:21],1'b0};
always @ (posedge clk) begin
    Valid_Instruction <= (Inst_Ready && Inst_Valid)? Instruction : Valid_Instruction;
end

//interpretation
wire op_R = (opcode === 7'b0110011);
wire op_R_shift = op_R && (funct3[1:0] === 2'b01);
wire op_R_calculate = op_R && ~op_R_shift;
wire op_as = op_R_calculate && (funct3 === 3'b000);//add/sub
wire op_ao = op_R_calculate && (funct3[2:1] === 2'b11);//and/or
wire op_xor = op_R_calculate && (funct3 === 3'b100);//xor
wire op_slt = op_R_calculate && (funct3[2:1] === 2'b01);//slt/sltu
wire op_I = op_I_cs || op_I_load || op_jalr;
wire op_I_cs = (opcode === 7'b0010011);//I-type calculate/shift
wire op_I_shift = op_I_cs && (funct3[1:0] === 2'b01);
wire op_shift = op_R_shift || op_I_shift;
wire op_I_nshift = op_I_cs && ~op_shift;
wire op_I_calculate = op_I_cs && ~op_shift;
wire op_calculate = op_R_calculate || op_I_calculate;
wire op_addi = op_I_calculate && (funct3 === 3'b000);//addi
wire op_noi = op_I_calculate && (funct3[2:1] === 2'b11);//andi/ori
wire op_xori = op_I_calculate && (funct3 === 3'b100);//xori
wire op_slti = op_I_calculate && (funct3[2:1] === 2'b01);//slti/sltu
wire op_I_load = (opcode === 7'b0000011);
wire op_lb = op_I_load && (funct3 === 3'b000);
wire op_lh = op_I_load && (funct3 === 3'b001);
wire op_lw = op_I_load && (funct3 === 3'b010);
wire op_lbu = op_I_load && (funct3 === 3'b100);
wire op_lhu = op_I_load && (funct3 === 3'b101);
wire op_mem = op_I_load || op_S;//load/store
wire op_I_nload = op_I && ~op_I_load;//I-type not load
wire op_jalr = (opcode === 7'b1100111);//I-type not jump
wire op_S = (opcode === 7'b0100011);
wire op_sb = op_S && (funct3 === 3'b000);
wire op_sh = op_S && (funct3 === 3'b001);
wire op_sw = op_S && (funct3 === 3'b010);
wire op_B = (opcode === 7'b1100011);
wire op_be = op_B && (funct3[2:1] === 2'b00);//beq/bne
wire op_blg = op_B && (funct3[2] === 1'b1);//blt/bge/bltu/bgeu
wire op_J = (opcode === 7'b1101111);
wire op_Jump = op_jal || op_jalr;//jal/jalr
wire op_U = (opcode[4:0] === 5'b01101);
wire op_lui = op_U && (opcode[5] === 1'b1);//lui
wire op_auipc = op_U && (opcode[5] === 1'b0);//auipc
wire nop = (Valid_Instruction === 32'b0);

//state machine
localparam s_INIT = 9'b000000001,
           s_IF = 9'b000000010,
           s_IW = 9'b000000100,
           s_ID = 9'b000001000,
           s_EX = 9'b000010000,
           s_LD = 9'b000100000,
           s_ST = 9'b001000000,
           s_RDW = 9'b010000000,
           s_WB = 9'b100000000;

reg [8:0] curr_state;
reg [8:0] next_state;

always @ (posedge clk) begin
    if (rst) begin
        curr_state <= s_INIT;
    end
    else begin
        curr_state <= next_state;
    end
end

always @ (*) begin
case (curr_state)
    s_INIT:begin
            next_state = s_IF;
    end
    s_IF:begin
            if (Inst_Req_Ready)
                next_state = s_IW;
            else
                next_state = s_IF;
    end
    s_IW:begin
            if (Inst_Valid)
                next_state = s_ID;
            else
                next_state = s_IW;
    end
    s_ID:begin
            if (nop)
                next_state = s_IF;
            else
                next_state = s_EX;
    end
    s_EX:begin
            next_state = ({9{op_R || op_Jump || op_I_load || op_U}} & s_WB) |
                         ({9{op_I_load}} & s_LD) |
                         ({9{op_B}} & s_IF) |
                         ({9{op_S}} & s_ST);
    end
    s_ST:begin
            if (Mem_Req_Ready)
                next_state = s_IF;
            else
                next_state = s_ST;
    end
    s_LD:begin
            if (Mem_Req_Ready)
                next_state = s_RDW;
            else
                next_state = s_LD;
    end
    s_RDW:begin
            if (Read_data_Valid)
                next_state = s_WB;
            else
                next_state = s_RDW;
    end
    s_WB:begin
            next_state = s_IF;
    end
    default:begin
            next_state = curr_state;
    end
endcase
end

//valid/ready signals
assign Inst_Req_Valid = (curr_state === s_IF) ? 1'b1 : 1'b0;
assign Inst_Ready = (curr_state === s_INIT || curr_state === s_IW) ? 1'b1 : 1'b0;
assign Read_data_Ready = (curr_state === s_INIT || curr_state === s_RDW) ? 1'b1 : 1'b0;

//reg_file
wire                   RF_wen;
wire [4:0]             RF_waddr;
wire [31:0]            RF_wdata;
wire [31:0]            RF_rdata1;
wire [31:0]            RF_rdata2;

assign RF_wen = (curr_state === s_WB);
assign RF_waddr = rd;
assign RF_wdata = {32{op_shift}} & shifter_result |
                  {32{op_calculate}} & ALU_result |
                  {32{op_lui}} & U_imm |
                  {32{op_auipc}} & ALU_result |
                  {32{op_Jump}} & (cal_PC + 32'd4) |
                  {32{op_I_load}} & data_load;

reg_file reg_file_module(
    .clk(clk),
    .waddr(RF_waddr),
    .raddr1(rs1),
    .raddr2(rs2),
    .wen(RF_wen),
    .wdata(RF_wdata),
    .rdata1(RF_rdata1),
    .rdata2(RF_rdata2)
);

//ALU
wire [2:0] ALUop;
wire [31:0] ALU_num1;
wire [31:0] ALU_num2;
wire [31:0] ALU_result;
wire Overflow;
wire Carryout;
wire Zero;

assign ALUop = {3{op_as}} & {funct7[5],2'b10} //add/sub
               {3{op_ao || op_aoi}} & ~funct3 //and/or
               {3{op_xor || op_xori}} & 3'b100 //xor
               {3{op_slt || op_slti}} & {~funct3[0],2'b11} //slt/sltu
               {3{op_addi || op_mem || op_auipc || op_Jump}} & 3'b010 //addi/load/store/auipc/jal/jalr
               {3{op_be}} & 3'b110 //beq/bne
               {3{op_blg}} & {~funct3[1],2'b11};//blt/bge/bltu/bgeu

assign ALU_num1 = {32{op_R || op_I || op_S || op_B}} & RF_rdata1 |
                  {32{op_jal || op_auipc}} & cal_PC;
assign ALU_num2 = {32{op_R || op_B}} & RF_rdata2 |
                  {32{op_I_shift}} & {{27{1'b0}},rs2} |
                  {32{op_I_nshift}} & I_imm |
                  {32{op_S}} & S_imm |
                  {32{op_jal}} & J_imm |
                  {32{op_U}} & U_imm;

alu alu_module(
    .A(ALU_num1),
    .B(ALU_num2),
    .ALUop(ALUop),
    .Overflow(Overflow),
    .CarryOut(Carryout),
    .Result(ALU_result),
    .Zero(Zero)
);

//shifter
wire [1:0] shifttop;
wire [31:0] shifter_result;
wire [4:0] shifter_num;

assign shifttop = {funct3[2], funct7[5]};
assign shifter_num = opcode[5] ? RF_rdata2[4:0] : rs2;

shifter shifter_module(
    .A(RF_rdata1),
    .B(shifter_num),
    .Shifttop(shifttop),
    .Result(shifter_result)
);

//jump
wire [31:0] jump_addr;
wire jump_wen;

assign jump_addr = ALU_result;
assign jump_wen = op_Jump;

//branch
wire [31:0] branch_addr;
wire branch_wen;

assign branch_addr = cal_PC + B_imm;
assign branch_wen = op_be & (Zero ^ funct3[0]) |
                    op_blg & (ALU_result[0] ^ funct3[0]);

//PC
reg [31:0] curr_PC;
wire [31:0] next_PC;
wire [31:0] PC_4;
reg [31:0] cal_PC;

assign PC = curr_PC;
assign next_PC = (jump_wen || branch_wen)? ({32{jump_wen}} & jump_addr | {32{branch_wen}} & branch_addr) : PC_4;
assign PC_4 = PC + 32'd4;

always @(posedge clk) begin
    if(rst) begin
        curr_PC <= 32'b0;
    end
    else if (curr_state === s_EX) begin
        curr_PC <= next_PC;
    end
    else if (Inst_Ready && Inst_Valid && (curr_state === s_ID) && (nop)) begin
        curr_PC <= PC_4;
    end
    else begin
        curr_PC <= curr_PC;
    end
end

always @ (posedge clk) begin
    cal_PC <= (curr_state === s_IF)? PC : cal_PC;
end

//mem
assign Address = {ALU_result[31:2],2'b00};

//load
wire [31:0] data_load;
wire [15:0] data_h;
wire [7:0] data_b;
reg [31:0] Valid_Read_data;

always @ (posedge clk) begin
    Valid_Read_data <= (Read_data_Ready && Read_data_Valid)? Read_data : Valid_Read_data;
end

assign MemRead = (curr_state === s_LD)? 1'b1 : 1'b0;
assign data_b = {8{ALU_result[1] & ALU_result[0]}} & Valid_Read_data[31:24] |
                {8{ALU_result[1] & ~ALU_result[0]}} & Valid_Read_data[23:16] |
                {8{~ALU_result[1] & ALU_result[0]}} & Valid_Read_data[15:8] |
                {8{~ALU_result[1] & ~ALU_result[0]}} & Valid_Read_data[7:0];
assign data_h = (~ALU_result[1] & ~ALU_result[0])? Valid_Read_data[15:0] : Valid_Read_data[31:16];
assign data_load = {32{op_lb}} & {{24{data_b[7]}},data_b} |//lb
                   {32{op_lh}} & {{16{data_h[15]}},data_h} |//lh
                   {32{op_lw}} & Valid_Read_data |//lw
                   {32{op_lbu}} & {24'b0,data_b} |//lbu
                   {32{op_lhu}} & {16'b0,data_h};//lhu

//store
assign MemWrite = (curr_state === s_ST)? 1'b1 : 1'b0;
assign Write_strb = {4{op_sb}} & (4'b1000 >> ~ALU_result[1:0]) |//sb
                    {4{op_sh}} & {{2{ALU_result[1]}},{2{~ALU_result[1]}}} |//sh
                    {4{op_sw}} & 4'b1111;//sw
assign Write_data = {32{op_sb}} & ({32{Write_strb[3]}} & {RF_rdata2[7:0],24'b0} | {32{Write_strb[2]}} & {8'b0,RF_rdata2[7:0],16'b0} | {32{Write_strb[1]}} & {16'b0,RF_rdata2[7:0],8'b0} | {32{Write_strb[0]}} & {24'b0,RF_rdata2[7:0]}) |//sb
                    {32{op_sh}} & ((Write_strb[3] & Write_strb[2])? {RF_rdata2[15:0],16'b0} : {16'b0,RF_rdata2[15:0]}) |//sh
                    {32{op_sw}} & RF_rdata2;//sw

//运行周期
reg [31:0] Cycle_count;
always @ (posedge clk) begin
    if (rst)
        Cycle_count <= 32'b0;
    else
        Cycle_count <= Cycle_count + 32'b1;
end
assign cpu_perf_cnt_0 = Cycle_count;

//完成指令数
reg [31:0] Inst_count;
always @ (posedge clk) begin
    if (rst)
        Inst_count <= 32'b0;
    else if (curr_state === s_EX)
        Inst_count <= Inst_count + 32'b1;
    else
        Inst_count <= Inst_count;
end
assign cpu_perf_cnt_1 = Inst_count;

//访存指令数
reg [31:0] Mem_count;
always @ (posedge clk) begin
    if (rst)
        Mem_count <= 32'b0;
    else if ((curr_state === s_LD || curr_state === s_ST) && Mem_Req_Ready)
        Mem_count <= Mem_count + 32'b1;
    else
        Mem_count <= Mem_count;
end
assign cpu_perf_cnt_2 = Mem_count;

//跳转发生数
reg [31:0] B_count;
always @ (posedge clk) begin
    if (rst)
        B_count <= 32'b0;
    else if ((curr_state === s_EX) && (op_RE || op_I_branch))
        B_count <= B_count + 32'b1;
    else
        B_count <= B_count;
end
assign cpu_perf_cnt_3 = B_count;

//非跳转发生数
reg [31:0] NB_count;
always@(posedge clk) begin
    if (rst)
        NB_count <= 32'b0;
    else if ((curr_state === s_EX) && ~(op_RE || op_I_branch))
        NB_count <= NB_count + 32'b1;
    else
        NB_count <= NB_count;
end
assign cpu_perf_cnt_4 = NB_count;