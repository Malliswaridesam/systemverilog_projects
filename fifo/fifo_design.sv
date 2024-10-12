module fifo(
    input clk, rst, wr, rd, 
    input [7:0] din, 
    output reg [7:0] dout, 
    output empty, full
);
    reg [3:0] wptr = 0;
    reg [3:0] rptr = 0;
    reg [4:0] ctrl = 0;
    reg [7:0] mem[15:0];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wptr <= 4'b0;
            rptr <= 4'b0;
            ctrl <= 5'b0;
            dout <= 8'b0;  // Initialize dout to avoid undefined values
        end
        else if (wr && !full) begin
            mem[wptr] <= din;
            wptr <= wptr + 1;
            ctrl <= ctrl + 1;
        end
        else if (rd && !empty) begin
            dout <= mem[rptr];
            rptr <= rptr + 1;
            ctrl <= ctrl - 1;
        end
    end

    assign empty = (ctrl == 0) ? 1'b1 : 1'b0;
    assign full = (ctrl == 16) ? 1'b1 : 1'b0;

endmodule

interface fifo_if;
logic clk,rst,rd,wr;
logic [7:0]din;
logic [7:0]dout;
logic empty,full;
endinterface
