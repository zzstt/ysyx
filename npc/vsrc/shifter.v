`timescale 10 ns / 1 ns
`define DATA_WIDTH 32

module shifter (
    input  [`DATA_WIDTH - 1:0] A,
    input  [4:0] B,
    input  [1:0] Shifttop,
    output [`DATA_WIDTH - 1:0] Result
);

    wire ll = (Shifttop === 2'b00);
    wire rl = (Shifttop === 2'b10);
    wire ra = (Shifttop === 2'b11);
    wire [`DATA_WIDTH - 1:0] All = (A << B);
    wire [`DATA_WIDTH - 1:0] Arl = (A >> B);
    wire [`DATA_WIDTH - 1:0] Ara = ((A >> B) | ({32{A[31]}} << (6'b0 + {1'b0, ~B} + 1)));
    assign Result = {32{ll}} & All |
                    {32{rl}} & Arl |
                    {32{ra}} & Ara;
endmodule