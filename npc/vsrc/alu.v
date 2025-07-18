`include "param.vh"
parameter OP_ADD = 3'b000,
    OP_SUB = 3'b101,
    OP_SLT = 3'b010,
    OP_SLTU= 3'b011,
    OP_XOR = 3'b100,
    OP_OR  = 3'b110,
    OP_AND = 3'b111;
module alu (
    input [`w(`DATA_WIDTH)]  src1,
    input [`w(`DATA_WIDTH)]  src2,
    input [`w(`ALU_OP_WIDTH)]alu_op,
    output[`w(`DATA_WIDTH)]  result
);
    wire [`w(`DATA_WIDTH)] re_add,re_and,re_or,re_xor;
    assign re_add = src1 + src2;
    assign re_and = src1 & src2;
    assign re_or  = src1 | src2;
    assign re_xor = src1 ^ src2;
    assign result = (alu_op == OP_ADD) ? re_add :
             (alu_op == OP_AND) ? re_and :
             (alu_op == OP_OR) ? re_or :
             (alu_op == OP_XOR) ? re_xor : 
             {(`DATA_WIDTH){1'b0}}; // Default case
endmodule
