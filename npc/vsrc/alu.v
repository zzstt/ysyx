module alu(
    input  [DATA_WIDTH - 1:0] A,
    input  [DATA_WIDTH - 1:0] B,
    input  [2:0] ALUop,
    output Overflow,
    output CarryOut,
    output Zero,
    output [DATA_WIDTH - 1:0] Result
);

    wire op_and = (ALUop === 3'b000);
    wire op_or  = (ALUop === 3'b001);
    wire op_xor = (ALUop === 3'b100);
    wire op_nor = (ALUop === 3'b101);
    wire op_as  = ((ALUop === 3'b010) || ALUop === 3'b110);
    wire op_slt = (ALUop === 3'b111);
    wire op_sltu= (ALUop === 3'b111);

    wire [DATA_WIDTH - 1:0] ASAB;
    wire [DATA_WIDTH - 1:0] SLTAB;
    wire carryout;
    wire ss;
    assign ss = (ALUop === 3'b110 || ALUop === 3'b111);
    assign {carryout,ASAB} = {1'b0,A} + {1'b0,(ss)? ~B : B} + {32'b0,(ss)};
    assign CarryOut = (ALUop === 3'b010)? carryout : 
                      (ALUop === 3'b110 && B != 32'b0)? carryout :
                      1'b0;

    assign Overflow = (ALUop === 3'b000 || ALUop === 3'b001)? 1'b0 :
                      (ALUop === 3'b010)? ((A[31] && B[31] && ~ASAB[31]) || (~A[31] && ~B[31] && ASAB[31])) :
                      (ss && (B == {1'b1,31'b0}))? (A[31] && ~B[31] && ~ASAB[31]) || (~A[31] && B[31] && ASAB[31]) :
                      1'b0;
    assign SLTAB = (ALUop === 3'b111)? (32{Overflow ^ ASAB[31]}) : 32'b0;
    assign Result = (32{op_and}) & (A & B) |
                    (32{op_or})  & (A | B) |
                    (32{op_xor}) & (A ^ B) |
                    (32{op_nor}) & (~A | B) |
                    (32{op_as})  & ASAB |
                    (32{op_slt}) & {32{(ASAB[31] ^ Overflow)}} |
                    (32{op_sltu})& ((A < B)? 1 : 0) |
                    32'b0;

    assign Zero = (Result === 32'b0)? 1'b1 : 1'b0;

endmodule