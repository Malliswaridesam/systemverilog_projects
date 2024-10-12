// Code your testbench here
// or browse Examples
class transaction;
randc bit op;
rand bit [31:0]awaddr;
rand bit [31:0]araddr;
rand bit [31:0]wdata;
bit [31:0]rdata;
bit [1:0]bresp;
bit [1:0]rresp;
constraint addr_range{
awaddr >0 ; awaddr<15; araddr>0 ;araddr<15;
};
constraint wdata_range{
wdata>10 ; wdata<100;
};
//   constraint valid_addr_range {awaddr == 1; araddr == 1;}
//   constraint valid_data_range {wdata < 12; rdata < 12;}

function void display(input string tag);
$display("[%0s]: waddr:%0d ,wdata:%0d, raddr:%0d, rdata:%0d, op:%0d",tag,awaddr,wdata,araddr,rdata,op);
endfunction
  
endclass


class generator;
transaction tr;
mailbox #(transaction)mbx;
event scrnext;
event done;
int count=0;

function new(mailbox #(transaction)mbx);
this.mbx=mbx;
tr=new();
endfunction

task run();
for(int i=0;i<=count;i++)
begin
assert(tr.randomize)else
$display("Randomization failed");
mbx.put(tr);
tr.display("Gen");
@(scrnext);
end
->done;
endtask
endclass

class driver;
transaction tr;
mailbox #(transaction)mbx,mbxdm;
// event drvnext;
virtual axi_if vif;

function new(mailbox #(transaction)mbx,mbxdm);
this.mbx=mbx;
this.mbxdm=mbxdm;
endfunction

task reset();
vif.arst<=1'b0;
vif.awvalid<=1'b0;
vif.awaddr<=0;
vif.wvalid<=1'b0;
vif.wdata<=0;
vif.bready<=0;
vif.araddr<=0;
vif.arvalid<=1'b0;
@(posedge vif.aclk)
vif.arst<=1'b1;
$display("Reset Done");
$display("---------------");
endtask

task write( input transaction tr);
$display("Drv : op:%0d ,waddr:%0d ,wdata:%0d",tr.op,tr.awaddr,tr.wdata);
mbxdm.put(tr);
vif.arst<=1'b1;
vif.awvalid<=1'b1;
vif.arvalid<=1'b0;
vif.araddr<=0;
vif.awaddr<=tr.awaddr;
@(negedge vif.awready)
vif.awvalid<=1'b0;
vif.awaddr<=0;
vif.wvalid<=1'b1;
vif.wdata<=tr.wdata;
@(negedge vif.wready)
vif.wvalid<=1'b0;
vif.wdata<=0;
vif.bready<=1'b1;
vif.rready<=1'b0;
@(negedge vif.bvalid)
vif.bready<=1'b0;                                        
  
endtask

task read(input transaction tr);
$display("[DRV] : OP : %0b ,araddr : %0d ",tr.op, tr.araddr);
  mbxdm.put(tr);
vif.arst<=1'b1;
vif.awvalid<=1'b0;
vif.awaddr<=0;
vif.wvalid  <= 1'b0;
vif.wdata   <= 0;
vif.bready<=1'b0;
vif.arvalid<=1'b1;
vif.araddr<=tr.araddr;
@(negedge vif.arready)
vif.arvalid<=1'b0;
vif.araddr<=0;
vif.rready<=1'b1;
@(negedge vif.rvalid)
 vif.rready<=1'b0;
endtask

task run();
forever begin
mbx.get(tr);
@(posedge vif.aclk)
if(tr.op==1'b1)
write(tr);
else
read(tr);
end
endtask
endclass


class monitor;
transaction tr,trd;
virtual axi_if vif;
  mailbox #(transaction)mbxdm;
  mailbox #(transaction)mbxms;

function new(mailbox #(transaction)mbxdm,mailbox #(transaction)mbxms);
this.mbxdm=mbxdm;
this.mbxms=mbxms;
endfunction

task run();
tr=new();
forever begin
@(posedge vif.aclk)
mbxdm.get(trd);
  if(trd.op== 1)
begin
tr.op =trd.op;
tr.awaddr = trd.awaddr;
  tr.wdata =trd.wdata;
@(posedge vif.bvalid)
tr.bresp =vif.bresp;
@(negedge vif.bvalid)
$display("[MON] : OP : %0b awaddr : %0d wdata : %0d bresp:%0d",tr.op, tr.awaddr, tr.wdata,tr.bresp);
 mbxms.put(tr);
end

  else
begin
tr.op =trd.op;
tr.araddr =trd.araddr;
@(posedge vif.rvalid)
tr.rdata =vif.rdata;
tr.rresp =vif.rresp;
@(negedge vif.rvalid)
$display("[MON] : OP : %0b araddr : %0d rdata : %0d rresp:%0d",tr.op, tr.araddr, tr.rdata,tr.rresp);
 mbxms.put(tr);
end
end
endtask
endclass

class scoreboard;
transaction tr,trd;
event scrnext;
mailbox #(transaction)mbxms;
bit [31:0]temp;
bit [31:0]mem[128]='{default: 0};

function new(mailbox #(transaction)mbxms);
this.mbxms=mbxms;
endfunction

task run();
forever begin
mbxms.get(tr);
//tr.display("scr";)
  if(tr.op ==1)
begin
  $display("[SCO] : OP : %0b awaddr : %0d wdata : %0d bresp : %0d",tr.op, tr.awaddr, tr.wdata, tr.bresp);
    if(tr.bresp==3)
    $display("SCR: DECODE ERROR");
    else begin
    mem[tr.awaddr]=tr.wdata;
      $display("[SCO] : DATA STORED ADDR :%0d and DATA :%0d", tr.awaddr,tr.wdata);
    end
end
else
begin
$display("[SCO] : OP : %0b araddr : %0d rdata : %0d rresp : %0d",tr.op, tr.araddr,
 tr.rdata, tr.rresp);
 temp=mem[tr.araddr];

 if(tr.rresp==3)
 $display("SCR: DECODE ERROR");
  else if( tr.rresp==1'b0 && temp==tr.rdata)
 $display("Data Match");
 else
 $display("Data Mismatch");
end
 $display("----------------------------------------------------");
 ->scrnext;
end

endtask

endclass


class environment;
  
generator gen;
driver drv;
monitor mon;
scoreboard scr;

mailbox #(transaction)mbx,mbxms,mbxdm;
event scrnext,done;

virtual axi_if vif;
function new(virtual axi_if vif);
mbx=new();
mbxms=new();
mbxdm=new();

gen=new(mbx);
drv=new(mbx,mbxdm);
mon=new(mbxdm,mbxms);
scr=new(mbxms);

this.vif=vif;
drv.vif=this.vif;
mon.vif=this.vif;
 
gen.scrnext=scrnext;
scr.scrnext=scrnext;

endfunction

 task pre_test();
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


module axi_tb;
axi_if vif();
axi uut(vif.aclk,vif.arst,vif.awvalid,vif.awaddr,vif.awready,vif.wvalid
        ,vif.wdata,vif.wready, vif.bready, vif.bvalid,vif.bresp, vif.arvalid,
vif.araddr,vif.arready,vif.rready,vif.rdata,vif.rvalid,vif.rresp);

initial begin
vif.aclk<=1'b0;
end
  
always #10 vif.aclk=~vif.aclk;
environment env;
initial begin
env=new(vif);
env.gen.count=30;
env.run();
end
   initial begin
    $dumpfile("dump.vcd");
    $dumpvars;   
  end

endmodule
