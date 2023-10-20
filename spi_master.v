/*
	spi接口主机模块
	完成传输后未做O_cs延时，O_cs拉高结束传输时O_busy立即拉低，
	若外部芯片对两次传输间隔的O_cs高电平时间有要求，需等待足够的时间再进行下一次传输
*/

module spi_master #(
	parameter	CPOL			= 0,	//SCLK = CPOL when spi is standby
	parameter	CPHA			= 1,	//when CPHA == 0, sample will occur in the first edge, 
							//when CPHA == 1, sample will occur in the second edge
	parameter	DATAWIDTH	= 8,	//一次传输的数据位宽
	parameter	CLKDIV		= 8	//SCLK相对主时钟的分频系数，必须为偶数
) (
	input					I_clk,
	input					I_rstn,
	
	input	[DATAWIDTH-1:0]	I_send_data,
	input					I_valid,
	output	[DATAWIDTH-1:0]	O_recv_data,
	output					O_busy,
	
	output			O_cs,
	output			O_sclk,
	output			O_mosi,
	input			I_miso
);

	localparam CNTWIDTH = $clog2(DATAWIDTH);
	
	reg [DATAWIDTH:0] R_send_data;
	reg [DATAWIDTH-1:0] R_recv_data;
	
	reg [CNTWIDTH+1:0] R_cnt;
	
	wire W_clk_en;
	
	reg R_shifter_en;
	wire W_shifter_end;
	
	reg R_transfer_en;
	wire W_transfer_end;
	
	
	clk_valid #(
		.CLKDIVIDE		(CLKDIV/2),
		.REGMODE		("NOREG")
	) clk_valid_u(
		.I_clk		(I_clk),
		.I_rstn		(R_transfer_en),
		
		.O_valid		(W_clk_en)
	);
	
	
	always@(posedge I_clk or negedge I_rstn)
	if(!I_rstn) R_cnt<={(CNTWIDTH+2){1'b0}};
	else if(W_transfer_end) R_cnt<={(CNTWIDTH+2){1'b0}};
	else if(W_clk_en) R_cnt<=R_cnt+1'b1;
	else R_cnt<=R_cnt;
	
	assign W_transfer_end = (R_cnt == (DATAWIDTH*2)) && W_clk_en;
	
	always@(posedge I_clk or negedge I_rstn)
	if(!I_rstn) R_transfer_en<=1'b0;
	else if(I_valid) R_transfer_en<=1'b1;
	else if(W_transfer_end) R_transfer_en<=1'b0;
	else R_transfer_en<=R_transfer_en;
	
	
	always@(posedge I_clk or negedge I_rstn)
	if(!I_rstn) R_send_data<={(DATAWIDTH+1){1'b0}};
	else if(I_valid) R_send_data<= ( CPHA ? {1'b0,I_send_data} : {I_send_data,1'b0});
	else if(W_clk_en && (R_cnt[0] ^ CPHA)) R_send_data<={R_send_data[DATAWIDTH-1:0],1'b0};
	else R_send_data<=R_send_data;
	
	always@(posedge I_clk or negedge I_rstn)
	if(!I_rstn) R_recv_data<={DATAWIDTH{1'b0}};
	else if(W_clk_en && (R_cnt[0] ^ (!CPHA))) R_recv_data<={I_miso,R_recv_data[DATAWIDTH-1:1]};
	else R_recv_data<=R_recv_data;
	
	
	assign O_busy = R_transfer_en;
	assign O_recv_data = R_recv_data;
	
	
	assign O_sclk = R_cnt[0] ^ CPOL;
	
	assign O_cs = !R_transfer_en;//(R_cnt == {(CNTWIDTH+2){1'b0}});
	assign O_mosi = R_send_data[DATAWIDTH];
	
	
endmodule
