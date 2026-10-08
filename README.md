# Verilog-SPI #
## SPI Master and Slave Controller using Verilog HDL ##

1.CPOL & CPHA  
2.BITORDER  
3.DATAWIDTH  
Are configurable for both master and slave controller, while  
CLKDIV  
is configurable for master controller to decide the frequency of `O_sclk`, and  
1.ODRVMODE  
2.WDATADELAY  
is configurable for slave controller to  
1.fit different `I_clk` and `I_sclk` frequency rate  
2.delay `O_wready` to wait `I_wdata` that can return data according to the last byte.  
  
