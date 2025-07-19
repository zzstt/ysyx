`timescale 10 ns / 1 ns
`define DATA_WIDTH 32
`define ADDR_WIDTH 5

module reg_file(
    input                    clk,
    input  [`ADDR_WIDTH - 1:0] waddr,
    input  [`ADDR_WIDTH - 1:0] raddr1,
    input  [`ADDR_WIDTH - 1:0] raddr2,
    input                    wen,
    input  [`DATA_WIDTH - 1:0] wdata,
    output [`DATA_WIDTH - 1:0] rdata1,
    output [`DATA_WIDTH - 1:0] rdata2
);

    reg [`DATA_WIDTH -1:0] r[`DATA_WIDTH-1:0];
    always @(posedge clk) begin
        if(((waddr != 5'd0) && wen))
            r[waddr] <= wdata;
    end
    assign rdata1 = (raddr1 != 5'd0) ? r[raddr1] : 32'd0;
    assign rdata2 = (raddr2 != 5'd0) ? r[raddr2] : 32'd0;
endmodule