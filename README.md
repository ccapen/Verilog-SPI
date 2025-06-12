# Verilog-SPI#
##SPI Master and Slave Controller using Verilog HDL##

1.CPOL & CPHA  
2.BITORDER  
3.DATAWIDTH  
Are configurable for both master and slave controller, while  
CLKDIV  
is configurable for master controller to decide the frequency of `sclk`, and  
DRVMODE  
is configurable for slave controller to fit different `sysclk` and `sclk` combination;  
