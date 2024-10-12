// Code your testbench here
// or browse Examples
class transaction;
typedef enum bit {write =1'b0,read=1'b1}oper_type;
randc oper_type oper;
rand bit [7:0]tx_data;
bit newd;
bit tx;
bit rx;
bit donetx;
bit donerx;
bit [7:0]rxdata;
 
 function transaction copy();
 copy=new();
 copy.oper=this.oper;
 copy.tx_data=this.tx_data;
 copy.newd=this.newd;
 copy.tx=this.tx;
 copy.rx=this.rx;
 copy.donetx=this.donetx;
 copy.donerx=this.donerx;
 copy.rxdata=this.rxdata;
 endfunction
endclass

class generator;
transaction tr;
mailbox #(transaction)mbx;
event drvnext,scrnext;
event done;
int count=0;

function new(mailbox #(transaction)mbx);
this.mbx=mbx;
tr=new();
endfunction

task run();
repeat(count)
begin
assert(tr.randomize)
else $display("Randomization failed");
mbx.put(tr.copy);
$display("[Gen] : oper :%0s Din:%0d",tr.oper.name(),tr.tx_data);

@(drvnext);
@(scrnext);
end
->done;
endtask
endclass

class driver;

transaction tr;
virtual uart_if uif;
event drvnext;
mailbox #(transaction)mbx;
mailbox #(bit [7:0])mbxds;
bit [7:0]din;
bit [7:0]data_rx;

function new(mailbox #(transaction)mbx,mailbox #(bit [7:0])mbxds);
this.mbx=mbx;
this.mbxds=mbxds;
endfunction

task reset();
uif.rst<=1'b1;
uif.newd<=1'b0;
uif.tx_data<=1'b0;
@(posedge uif.clk)
uif.rst<=1'b0;
$display("Reset Done");
endtask

task run();
forever begin
mbx.get(tr);
if(tr.oper==1'b0)
begin
@(posedge uif.uclk)
uif.rst<=1'b0;
uif.newd<=1'b1;
uif.rx=1'b1;
uif.tx_data=tr.tx_data;
@(posedge uif.uclk)
uif.newd<=1'b0;
mbxds.put(tr.tx_data);

  wait(uif.donetx==1'b1);
$display("[Drv]: Data sent to scoreboard:%0d",tr.tx_data);
->drvnext;
end

  
else if(tr.oper ==1'b1)
begin
  @(posedge uif.uclkrx)
uif.rst<=1'b0;
uif.rx<=1'b0;
uif.newd<=1'b0;
  @(posedge uif.uclkrx)
for(int i=0;i<=7;i++)
begin
  @(posedge uif.uclkrx)
uif.rx<=$urandom_range(1,40);
data_rx[i]=uif.rx;
end
mbxds.put(data_rx);
$display("[DRV]: Data RCVD : %0d", data_rx);
wait(uif.donerx==1'b1);
uif.rx<=1'b1;
->drvnext;
end
end
endtask
endclass


class monitor;
  
virtual uart_if uif;
transaction tr;
mailbox #(bit [7:0])mbxms;
  bit [7:0]srx=8'b0;
  bit [7:0]rrx=8'b0;

function new(mailbox #(bit [7:0])mbxms);
this.mbxms=mbxms;
endfunction

task run();
 
forever begin
@(posedge uif.uclk)
// 
  
if((uif.newd==1'b1) && (uif.rx==1'b1))
begin
 
@(posedge uif.uclk)

for(int i=0;i<=7;i++)
begin
@(posedge uif.uclk)
srx[i]=uif.tx;
end

wait(uif.donetx==1'b1);
$display("[MON] : DATA SEND on UART TX %0d", srx);
  @(posedge uif.uclk)
mbxms.put(srx);
end

else if((uif.newd==1'b0) && (uif.rx==1'b0))
begin
wait(uif.donerx==1'b1);
rrx=uif.rxdata;
$display("[MON] : DATA RCVD RX %0d", rrx);
@(posedge uif.uclk); 
mbxms.put(rrx);
end

end
endtask
endclass



class scoreboard;

transaction tr;
mailbox #(bit [7:0])mbxds,mbxms;
bit [7:0]ds;
bit [7:0]ms;
event scrnext;
function new(mailbox #(bit [7:0])mbxds,mbxms);
this.mbxds=mbxds;
this.mbxms=mbxms;
endfunction

task run();
forever begin
mbxds.get(ds);
mbxms.get(ms);
$display("[Scr]: Ds:%0d,Ms:%0d",ds,ms);
if(ds==ms)
$display("Data Match");
else
$display("Data Mismatch");
->scrnext;
end
endtask
endclass

class environment;

generator gen;
driver drv;
monitor mon;
scoreboard scr;
mailbox #(transaction)mbx;
mailbox #(bit [7:0])mbxms,mbxds;
virtual uart_if uif;
event done;
event scorenext,drivernext;
function new(virtual uart_if uif);
mbx=new();
mbxms=new();
mbxds=new();

gen=new(mbx);
drv=new(mbx,mbxds);
mon=new(mbxms);
scr=new(mbxds,mbxms);

this.uif=uif;
drv.uif=this.uif;
mon.uif=this.uif;

gen.scrnext=scorenext;
scr.scrnext=scorenext;
drv.drvnext=drivernext;
gen.drvnext=drivernext;

endfunction

task pre_test;
drv.reset();
endtask

task test();
fork
gen.run();
drv.run();
mon.run();
scr.run();
join_any
endtask

task post_test();
wait(gen.done.triggered);
$finish();
endtask

  task run();
    pre_test();
    test();
    post_test();
  endtask
endclass


module tb;
    
  uart_if uif();
  uart_top #(100000, 9600) dut (uif.clk,uif.rst,uif.newd,uif.rx,uif.tx_data,uif.donetx,uif.donerx,uif.tx,uif.rxdata);
    initial begin
      uif.clk <= 0;
    end
    
    always #10 uif.clk <= ~uif.clk;
    
    environment env;
    initial begin
      env = new(uif);
      env.gen.count = 10;
      env.run();
    end 
  assign uif.uclk = dut.utx.uclk; 
  assign uif.uclkrx=dut.urx.uclk;
  endmodule
