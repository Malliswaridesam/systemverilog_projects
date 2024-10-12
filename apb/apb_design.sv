// Code your design here
module apb(
input pclk,prset,psel,penable,pwrite,
input [7:0]pwdata,
input [31:0]paddr,
output reg pready,
output reg [7:0]pread,
output perr);

reg [7:0]mem[16];
localparam [1:0]idle=0,write=1,read=2;
reg [1:0]state,nstate;

bit addr_err,addv_err,data_err;

always @(posedge pclk , negedge prset)
begin
if(prset==1'b0)
state<=idle;
else
state<=nstate;
end

always @(*)
begin
case (state)

idle : 
begin 
pread=8'b0;
pready=1'b0;

if(psel==1'b1 && pwrite==1'b1)
nstate =write;

else if(psel==1'b1 && pwrite ==1'b0)
nstate =read;

else
nstate =idle;
end

write : begin 
if(psel==1'b1 && penable ==1'b1)
begin
if(!addr_err && !addv_err && !data_err)
begin
pready =1'b1;
  mem[paddr] =pwdata;
nstate =idle;
end
else
begin
pready =1'b1;
nstate =idle;
end
end
end

read : begin
if(psel==1'b1 && penable ==1'b1 )
begin 
if(!addr_err && !addv_err && !data_err)
begin
pready =1'b1;
pread =mem[paddr];
nstate =idle;
end
else
begin
pready =1'b1;
pread =8'b0;
nstate =idle;
end
end
end

default : 
begin
  nstate =idle;
pready =1'b0;
pread =8'b0;

end
endcase
end

reg av_t;
always @(*)
begin
if(paddr>=1'b0)
av_t =1'b0;
else
av_t =1'b1;
end

reg dv_t;
always @(*)
begin
if(pwdata>=1'b0)
dv_t =1'b0;
else
dv_t =1'b1;
end

assign addr_err=((nstate==write||read) && (paddr>15))?1'b1:1'b0;
assign addv_err=(nstate==write||read)?av_t:1'b0;
assign data_err=(nstate==write||read)?dv_t:1'b0;
assign perr  = (psel == 1'b1 && penable == 1'b1) ? ( addv_err || addr_err || data_err) : 1'b0;
endmodule

interface apb_if;
logic pclk,prset,psel,penable,pwrite;
logic [31:0]paddr;
logic [7:0]pwdata;
logic [7:0]pread;
logic pready;
logic perr;
endinterface
