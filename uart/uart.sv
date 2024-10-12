// Code your design here
module uart_t#(parameter clk_freq=100000,baud_rate=9600) (input clk,rst,newd,input [7:0]tx_data,output reg tx,donetx);
typedef  enum bit [1:0]{idle =2'b00,start=2'b01,send=2'b10,comp=2'b11}state_type;
state_type state=idle;
bit uclk=0;
int countc=0;
int count=0;
localparam clk_count=(clk_freq/baud_rate);
always @(posedge clk)
begin
//if(rst==1'b1)
//uclk<=1'b0;
//else
//begin
if(countc<clk_count)
countc<=countc+1;
else
begin
uclk<=~uclk;
countc<=0;
//uclk<=~uclk;
//end
end
end
reg [7:0]temp;
always @(posedge uclk)
begin
if(rst==1'b1)
begin
state<=idle;
end
else
begin
case(state)
idle :
begin
count<=0;
if(newd==1'b1)
begin
tx<=1'b0;
donetx<=1'b0;
state<=send;
temp<=tx_data;

end
else
begin
state<=idle;
temp<=8'b0;
end
end
send :
begin
if(count<=7)
begin
tx<=temp[count];
count<=count+1;
state<=send;
end
else
begin
count<=0;
tx<=1'b1;
state<=idle;
donetx<=1'b1;

end
end
default: state<=idle;
endcase
end
end
endmodule


module uart_r #(parameter clk_freq=100000,parameter baud_rate=9600)(input clk,rst,rx,output reg donerx,output reg [7:0]rxdata);

typedef enum bit[1:0] {idle=2'b00,send=2'b01}state_type;
state_type state=idle;
bit uclk=0;
int count=0;
int countc=0;
localparam clk_count=(clk_freq/baud_rate);
always @(posedge clk)
begin
if(countc<clk_count/2)
countc<=countc+1;
else
begin
uclk<=~uclk;
countc<=0;
end
end

always @(posedge uclk)
begin
if(rst==1'b1)
begin
 rxdata<=8'h00;	
count<=0;
donerx<=1'b0;

end
else
begin
case(state)
idle : 
begin
rxdata<=8'h0;
donerx<=1'b0;
count<=0;
if(rx==1'b0)
state<=send;
else
state<=idle;
end

send :
begin
  if(count<=7)
begin
count<=count+1;
rxdata <= {rx, rxdata[7:1]};
end
else
begin

donerx<=1'b1;
count<=0;
  state<=idle;
end
end
default :
state<=idle;
endcase
 
end
end
endmodule

module uart_top#(parameter clk_freq=100000,baud_rate=9600)(input clk,rst,newd,rx,input [7:0]tx_data,output donetx,donerx,tx,output [7:0]rxdata);
  
uart_t #(clk_freq,baud_rate)utx(clk,rst,newd,tx_data,tx,donetx);
uart_r #(clk_freq,baud_rate)urx(clk,rst,rx,donerx,rxdata);

endmodule


interface uart_if;
logic clk,rst,newd,tx;
  logic [7:0]tx_data;
  logic donetx;
  logic rx,donerx;
  logic [7:0]rxdata;
  logic uclk;
  logic uclkrx;
endinterface
