// Code your testbench here
// or browse Examples
class transaction;
rand bit [31:0]paddr;
rand bit [7:0]pwdata;
rand bit pwrite;
 bit psel;
 bit penable;
bit pready;
  bit [7:0]pread;
bit perr;
  
function void display(input string tag);
    $display("[%0s] :  paddr:%0d  pwdata:%0d pwrite:%0b  prdata:%0d pslverr:%0b",tag,paddr,pwdata, pwrite, pread, perr);
endfunction

constraint paddr_range{
paddr>=0; paddr<=15;
};
constraint pwdata_range{
pwdata>=10; pwdata<=100;
};

//   constraint pwrite_range {
//     pwrite dist {0:/50 ,1:/50};
//   }
endclass

class generator;
mailbox #(transaction)mbx;
transaction tr;
event done;
event drvnext;
event scrnext;
int count=0;

function new(mailbox #(transaction)mbx);
this.mbx=mbx;
tr=new();
endfunction

task run();
repeat(count)
begin
assert(tr.randomize)
else $error("Randomization failed");
  tr.display("Gen");
mbx.put(tr);
@(drvnext);
@(scrnext);
end
->done;
endtask
endclass

class driver;
transaction data;
virtual apb_if vif;
mailbox #(transaction)mbx;
event drvnext;

function new(mailbox #(transaction)mbx);
this.mbx=mbx;
endfunction

task reset();
vif.prset<=1'b0;
vif.psel<=1'b0;
vif.paddr<=1'b0;
vif.pwrite<=1'b0;
vif.pwdata<=1'b0;
vif.penable<=1'b0;
@(posedge vif.pclk)
vif.prset<=1'b1;
$display("Reset done");
$display("---------------------------");
endtask

task run();
forever begin
mbx.get(data);
@(posedge vif.pclk)
  
if(data.pwrite==1'b1)
begin
//vif.prset<=1'b1;
vif.psel<=1'b1;
vif.penable<=1'b0;
vif.pwrite<=1'b1;
vif.paddr<=data.paddr;
vif.pwdata<=data.pwdata;
@(posedge vif.pclk)
vif.penable<=1'b1;
@(posedge vif.pclk)
vif.psel<=1'b0;
vif.penable<=1'b0;
vif.pwrite<=1'b0;
  data.display("Drv");
->drvnext;
end

else if(data.pwrite==1'b0)
begin
//vif.prset<=1'b1;
vif.psel<=1'b1;
vif.penable<=1'b0;
vif.pwdata<=0;
vif.paddr<=data.paddr;
vif.pwrite<=1'b0;
@(posedge vif.pclk)
vif.penable<=1'b1;
@(posedge vif.pclk)
vif.psel<=1'b0;
vif.penable<=1'b0;
vif.pwrite<=1'b0;
data.display("DRV");
->drvnext;
end

end
endtask
endclass

class monitor;
transaction tr;
mailbox #(transaction )mbxms;
virtual apb_if vif;

function new(mailbox #(transaction)mbxms);
this.mbxms=mbxms;
endfunction

task run();
  tr=new();
forever begin
@(posedge vif.pclk)
if(vif.pready==1'b1)
begin
tr.paddr =vif.paddr;
tr.pwdata =vif.pwdata;
tr.pwrite =vif.pwrite;
tr.pread =vif.pread;
tr.perr =vif.perr;
@(posedge vif.pclk);
  tr.display("MON");
mbxms.put(tr);
end
end
endtask
endclass

class scoreboard;
transaction tr;
mailbox #(transaction)mbxms;
event scrnext;
  bit [7:0]mem_pwdata[16]= '{default:0};
bit [7:0]rdata;
int err=0;

function new(mailbox #(transaction)mbxms);
this.mbxms=mbxms;
endfunction

task run();
forever begin
mbxms.get(tr);
tr.display("Scr");

if(tr.pwrite==1'b1 && tr.perr==1'b0)
begin
mem_pwdata[tr.paddr]=tr.pwdata;
  $display("[SCR]: Data stored :%0d,ADDR:%0d",tr.pwdata,tr.paddr);
end

else if(tr.pwrite==1'b0 && tr.perr==1'b0)
begin
 rdata=mem_pwdata[tr.paddr];
  if(tr.pread==rdata)
  $display("[SCR]: Data Match");
  else
  begin
  err++;
  $display("[SCR]:Data Mismatch");
  end
  end
  
else if(tr.perr==1'b1)
begin
  $display("[SCO] : SLV ERROR DETECTED");
end
 $display("---------------------------------------------------------------------------------------------------");
     ->scrnext;
end
endtask
endclass


class environment;
generator gen;
driver drv;
monitor mon;
scoreboard scr;

mailbox #(transaction)mbx,mbxms;
event drvnext,scrnext,done;

virtual apb_if vif;
function new(virtual apb_if vif);
mbx=new();
mbxms=new();

gen=new(mbx);
drv=new(mbx);
mon=new(mbxms);
scr=new(mbxms);

this.vif=vif;
drv.vif=this.vif;
mon.vif=this.vif;
gen.drvnext=drvnext;
drv.drvnext=drvnext;
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


module tb;
    
   apb_if vif();
   apb dut (
   vif.pclk,
   vif.prset,
   vif.psel,
   vif.penable,
    vif.pwrite,
   vif.pwdata,
  
  
    vif.paddr,
   vif.pready,
    vif.pread,
   vif.perr
   );
   
    initial begin
      vif.pclk <= 0;
    end
    
    always #10 vif.pclk <= ~vif.pclk;
    environment env;
    initial begin
      env = new(vif);
      env.gen.count = 30;
      env.run();
    end
  endmodule
