module fifo_tb;
    reg clk, rst, rd, wr;
    reg [7:0] din;
    wire [7:0] dout;
    wire empty, full;

    fifo uut (clk, rst, wr, rd, din, dout, empty, full);

    // Clock generation
    initial begin
        clk = 1'b0;
    end
    always #10 clk = ~clk;  // Clock toggle every 10 time units

    // Reset sequence
    initial begin
        rst = 1'b1;  // Apply reset
       #10
        rst = 1'b0;  // Release reset after 20 time units
    end

    // Write and read sequence
    initial begin
//    #5
        wr = 1'b1; rd = 1'b0;  // Initially only write enabled
        din = 8'b00000001;  // First data write
        #20;
        din = 8'b00000010;  // Second data write
        #20;
        din = 8'b00000011;  // Third data write
        #20;
        din = 8'b00000100;  // Fourth data write
        #20;
        din = 8'b00000101;  // Fifth data write
        #20;

        wr = 1'b0;
        #20  // Stop writing
        rd = 1'b1;  // Start reading

        #20;  // Read first data (expecting 00000001)
        #20;  // Read second data (expecting 00000010)
        #20;  // Read third data (expecting 00000011)
        #20;  // Read fourth data (expecting 00000100)
        #20;  // Read fifth data (expecting 00000101)

        $finish;
    end
endmodule
