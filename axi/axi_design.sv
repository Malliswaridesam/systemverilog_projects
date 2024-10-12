// Code your design here
module axi(
input  aclk,arst,awvalid,
input  [31:0]awaddr,
output reg awready,

input  wvalid,
input  [31:0]wdata,
output reg wready,

input  bready,
output reg bvalid,
output reg [1:0]bresp,

input  arvalid,
input   [31:0]araddr,
output reg arready,

input  rready,
output reg [31:0]rdata,
output reg rvalid,
output reg [1:0]rresp
);

localparam idle =0,send_waddr_aclk=1,send_raddr_aclk=2,send_wdata_aclk=3,update_mem=4,send_wr_err=5,
send_wr_resp=6,gen_data=7,send_rd_err=8,send_rdata=9;

reg [3:0]state=idle;
reg [3:0]next_state=idle;
reg [1:0]count=0;
reg [31:0]waddr,write_data,raddr,read_data;


reg [31:0]mem[128];

always @(posedge aclk)
begin

  if(arst==1'b0)
begin

state<=idle;
for(int i=0;i<128;i++)
begin
mem[i]=0;
end
awready<=1'b0;
wready<=1'b0;
bvalid<=1'b0;
bresp<=1'b0;
arready<=1'b0;
rdata<=1'b0;
rvalid<=1'b0;
rresp<=1'b0;
waddr<=0;
write_data<=0;
raddr<=0;
read_data<=0;
end
else 
begin
case(state)
idle:
begin
awready<=1'b0;
wready<=1'b0;
bvalid<=1'b0;
bresp<=1'b0;
arready<=1'b0;
rdata<=1'b0;
rresp<=1'b0;
waddr<=0;
write_data<=0;
raddr<=0;
read_data<=0;
  count<=0;
rvalid<=1'b0;
  
if(awvalid==1'b1)
begin
state<=send_waddr_aclk;
waddr<=awaddr;
awready<=1'b1;
end
else if(arvalid ==1'b1)
begin
state<=send_raddr_aclk;
raddr<=araddr;
arready<=1'b1;
end
else
state<=idle;
end

send_waddr_aclk:
begin
awready<=1'b0;
if(wvalid)
begin
write_data<=wdata;
wready<=1'b1;
state<=send_wdata_aclk;
end
else
state<=send_waddr_aclk;
end

send_wdata_aclk:
begin
wready<=1'b0;
if(waddr<128)
begin
state<=update_mem;
  mem[waddr]<=write_data;
end
else
begin
state<=send_wr_err;
bresp<=2'b11;
bvalid<=1'b1;
end
end

update_mem: begin
  mem[waddr]<=write_data;
state<=send_wr_resp;
end

send_wr_resp:
begin
bresp<=2'b00;
bvalid<=1'b1;
if(bready)
state<=idle;
else
state<=send_wr_resp;
end

send_wr_err:
begin
if(bready)
state<=idle;
else
state<=send_wr_err;
end


send_raddr_aclk:
begin
arready<=1'b0;
if(raddr<128)
state<=gen_data;
else
begin
rvalid<=1'b1;
state<=send_rd_err;
  rdata<=0;
rresp<=2'b11;

end
end

gen_data:
begin
if(count<2)
begin
  
read_data<=mem[raddr];
state<=gen_data;
count<=count+1;
end
else
begin
rvalid<=1'b1;
rdata<=read_data;
rresp<=2'b00;
if(rready)
state<=idle;
else
state<=gen_data;
end
end


send_rd_err:
begin
if(rready)
state<=idle;

else
state<=send_rd_err; 
end

default : state<=idle;
endcase
end
end
endmodule

interface axi_if;
logic [31:0]awaddr;
logic [31:0]araddr;
logic [31:0]wdata;
logic [31:0]rdata;
logic aclk, arst, awready, awvalid, wvalid, wready, bready,bvalid;
logic [1:0]bresp,rresp;
logic arready, arvalid, rready, rvalid;

endinterface
