`include "param.vh"
module top(
    input         clk,
    input         rst,
    output[`w(`ADDR_WIDTH)]     pc,
    input[`w(`DATA_WIDTH)]      inst
);
    
    wire [3:0] wmask;

    cpu u_cpu(
        .clk     	(clk      ),
        .rst     	(rst      ),
        .pc      	(pc       ),
        .inst    	(inst     ),
        .rdata   	(rdata    ),
        .wdata   	(wdata    ),
        .wmask      (wmask    ),
        .addr    	(addr     ),
        .mem_wen 	(mem_wen  ),
        .mem_valid (valid)
    );
    import "DPI-C" function int paddr_read(input int raddr);
    import "DPI-C" function void paddr_write(
    input int waddr, input int wdata, input byte wmask);
    reg [31:0] rdata;
    wire[31:0] wdata,addr;
    wire mem_wen;

    wire valid;
    always @(*) begin
        if (valid) begin
            rdata = paddr_read(addr);
            if (mem_wen) begin
                paddr_write(addr, wdata, {4'b0,wmask});
            end
        end
        else begin
            rdata = 0;
        end
    end

endmodule
