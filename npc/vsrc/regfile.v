`timescale 1ns / 1ps

module regfile #(
    parameter REG_ADDR_WIDTH = 5,
    parameter DATA_WIDTH = 32,
    parameter REG_NUM =  32) (
  input clk,
  input rst,
  input wen, 
  input [REG_ADDR_WIDTH-1:0]  waddr,
  input [DATA_WIDTH-1:0]      wdata,
  input [REG_ADDR_WIDTH-1:0]  raddr1,
  output [DATA_WIDTH-1:0]     rdata1, 
  input [REG_ADDR_WIDTH-1:0]  raddr2,
  output [DATA_WIDTH-1:0]     rdata2
);
  reg [DATA_WIDTH-1:0] reg_file [0:REG_NUM-1];
  integer i;
  always @(posedge clk) begin
    if(rst)begin
      for (i = 0; i < REG_NUM; i = i + 1) begin
        reg_file[i] <= {DATA_WIDTH{1'b0}};
      end
    end
    else
      if (wen && waddr != {REG_ADDR_WIDTH{1'b0}}) 
        reg_file[waddr] <= wdata;
      else
        reg_file[waddr] <= reg_file[waddr]; 
  end
  assign rdata1 = (raddr1 == 0) ? {DATA_WIDTH{1'b0}} : reg_file[raddr1];
  assign rdata2 = (raddr2 == 0) ? {DATA_WIDTH{1'b0}} : reg_file[raddr2];
endmodule
