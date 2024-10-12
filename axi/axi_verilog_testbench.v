module axi_tb;
reg aclk=0,arst=0,awvalid=0;
reg [31:0]awaddr=0;
wire awready;

reg wvalid=0;
reg [31:0]wdata=0;
wire wready;

reg bready=0;
wire bvalid;
wire [1:0]bresp;

reg arvalid=0;
reg [31:0]araddr=0;
wire arready;

reg rready=0;
wire [31:0]rdata;
wire rvalid;
wire [1:0]rresp;

axi uut(aclk,arset,awvalid,awaddr,awready,wvalid,wdata,wready,bready,bvalid,bresp,arvalid,araddr,arready,
rready,rdata,rvalid,rresp);

initial begin
aclk<=1'b0;
end
always #10 aclk=~aclk;

initial begin
arst=1'b0;
repeat(5)@(posedge aclk)
arst=1'b1;

repeat(2)@(posedge aclk)
awvalid=1'b1;
awaddr=32'h87;
@(negedge awready)
awvalid=1'b0;

repeat(2)@(posedge aclk)
wvalid=1'b1;
wdata=32'h1;
@(negedge wready)
wvalid=1'b0;

repeat(2)@(posedge aclk)
bready=1'b1;
@(negedge bvalid)
bready=1'b0;

repeat(2)@(posedge aclk)
arvalid=1'b1;
araddr=32'h87;
@(negedge arready)
arvalid=1'b0;

repeat(2)@(posedge aclk)
rready=1'b1;
@(negedge rvalid)
rready=1'b0;
#100
$stop;
end

endmodule
 
 
