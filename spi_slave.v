/*
	Copyright (C), 2025, LGPL
	Author: ccapen@github.com
*/
module spi_slave #(
	parameter	CPOL			= 0,	//SCLK = CPOL when spi is standby
	parameter	CPHA			= 1,	//when CPHA == 0, sample will occur in the first edge, 
										//when CPHA == 1, sample will occur in the second edge
	parameter	BITORDER		= "MSB_FIRST",	//"MSB_FIRST" "LSB_FIRST"
	parameter	DATAWIDTH		= 8,	//一次传输的数据位宽
	parameter	ODRVMODE		= "NORMAL",	//"NORMAL" "ADVANCE"
											//O_miso driver mode of timing
											//O_miso always later than I_sclk edge constant 3 I_clk cycles
											//when in "ADVANCE" mode, O_miso will be drivered at sample edge
											//when I_clk frequency lower than (12 * I_sclk frequency), use "ADVANCE"; else use "NORMAL"
	parameter	WDATADELAY		= 4		//delay O_wready to wait I_wdata, must >= 1
										//O_wready will be high when transfer start and WDATADELAY I_clk cycles later than O_rvalid
										//it should less than cycles of I_clk of minimum interval between two contiguous transfer
										//additionally, if ODRVMODE is "NORMAL" and (CPHA == 0), it must less than ((frequency of I_clk)/2)/(frequency of I_sclk)
) (
	input					I_clk,
	input					I_rstn,

	input	[DATAWIDTH-1:0]	I_wdata,
	output					O_wready,
	output					O_rvalid,
	output	[DATAWIDTH-1:0]	O_rdata,
	output					O_transfer_end,	//will be high for 1 I_clk cycle when I_csn postive edge

	input					I_csn,
	input					I_sclk,
	input					I_mosi,
	output					O_miso
);

localparam CNTWIDTH = $clog2(DATAWIDTH);
localparam CNTWDELAYVWIDTH	= $clog2(WDATADELAY+1);


reg [2:0] R_csn_d;
reg [2:0] R_sclk_d;
reg [2:0] R_mosi_d;

always @(posedge I_clk or negedge I_rstn) begin
	if(!I_rstn)begin
		R_csn_d  <= 3'b111;
		R_sclk_d <= 3'b0;
		R_mosi_d <= 3'b0;
	end
	else begin
		R_csn_d  <= {R_csn_d[1:0], I_csn};
		R_sclk_d <= {R_sclk_d[1:0], I_sclk};
		R_mosi_d <= {R_mosi_d[1:0], I_mosi};
	end
end

wire W_sclk_pos = (!R_sclk_d[2]) & R_sclk_d[1];
wire W_sclk_neg = R_sclk_d[2] & (!R_sclk_d[1]);
wire W_sample_edge = (CPOL ^ CPHA) ? W_sclk_neg : W_sclk_pos;
wire W_driver_edge = (CPOL ^ (!CPHA) ^ (ODRVMODE != "NORMAL")) ? W_sclk_neg : W_sclk_pos;
wire W_transfer_start = R_csn_d[2] & (!R_csn_d[1]);

assign O_transfer_end = (!R_csn_d[2]) & R_csn_d[1];


reg [CNTWIDTH-1:0] R_cnt;
reg [DATAWIDTH-1:0] R_rdata;
reg [DATAWIDTH:0] R_wdata;
reg R_rvalid;
reg [CNTWDELAYVWIDTH-1:0] R_cnt_wdata_delay;

always @(posedge I_clk or negedge I_rstn) begin
	if(!I_rstn)
		R_cnt <= {CNTWIDTH{1'b0}};
	else if(R_csn_d[2] || ((R_cnt == (DATAWIDTH-1)) && W_sample_edge))
		R_cnt <= {CNTWIDTH{1'b0}};
	else if(W_sample_edge)
		R_cnt <= R_cnt + 1'b1;
	else 
		R_cnt <= R_cnt;
	
	if(!I_rstn)
		R_rdata <= {DATAWIDTH{1'b0}};
	else if(W_sample_edge)
		R_rdata <= (BITORDER == "MSB_FIRST") ? {R_rdata[DATAWIDTH-2:0], R_mosi_d[2]} : {R_mosi_d[2], R_rdata[DATAWIDTH-1:1]};
	else 
		R_rdata <= R_rdata;
	
	if(!I_rstn)
		R_rvalid <= 1'b0;
	else 
		R_rvalid <= (R_cnt == (DATAWIDTH-1)) && W_sample_edge;
	
	if(!I_rstn)
		R_wdata <= {(DATAWIDTH+1){1'b0}};
	else if(O_wready)
		R_wdata <= ((BITORDER == "MSB_FIRST") ^ (((!CPHA)) || (ODRVMODE != "NORMAL"))) ? {R_wdata[DATAWIDTH], I_wdata} : {I_wdata, R_wdata[0]};
	else if(W_driver_edge)
		R_wdata <= (BITORDER == "MSB_FIRST") ? {R_wdata[DATAWIDTH-1:0], 1'b0} : {1'b0, R_wdata[DATAWIDTH:1]};
	else 
		R_wdata <= R_wdata;
	
	if(!I_rstn)
		R_cnt_wdata_delay <= {CNTWDELAYVWIDTH{1'b0}};
	else if((R_cnt == (DATAWIDTH-1)) && W_sample_edge)
		R_cnt_wdata_delay <= WDATADELAY;
	else if(R_cnt_wdata_delay == {CNTWDELAYVWIDTH{1'b0}})
		R_cnt_wdata_delay <= {CNTWDELAYVWIDTH{1'b0}};
	else 
		R_cnt_wdata_delay <= R_cnt_wdata_delay - 1'b1;
end

assign O_wready = (W_transfer_start || (R_cnt_wdata_delay == {{(CNTWDELAYVWIDTH-1){1'b0}}, 1'b1}));
assign O_rvalid = R_rvalid;
assign O_rdata = R_rdata;

assign O_miso = (BITORDER == "MSB_FIRST") ? R_wdata[DATAWIDTH] : R_wdata[0];


endmodule
