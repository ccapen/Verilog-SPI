module top_tb();

	reg R_clk;
	reg R_rstn;
	reg R_valid;
	
	always #10 R_clk = !R_clk;
	
	initial
	begin
		R_clk = 1'b0;
		R_rstn = 1'b0;
		R_valid = 1'b0;
		#55 R_rstn = 1'b1;
		#20 R_valid = 1'b1;
		#20 R_valid = 1'b0;
	end
	

	spi_master #(
		.CPOL		(0),
		.CPHA		(0),
		.DATAWIDTH	(16),
		.CLKDIV		(8)
	) spi_master_u(
		.I_clk		(R_clk),
		.I_rstn		(R_rstn),
		
		.I_send_data	(16'haa55),
		.I_valid			(R_valid),
		.O_busy			(),
		.O_recv_data	(),
		
		.O_cs				(),
		.O_sclk			(),
		.O_mosi			(),
		.I_miso			(1'b0)
	);

	
endmodule
