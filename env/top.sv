
module top(
	input CLOCK_50,
	input[18:0] SW,
	output[6:0] HEX0,
	output[6:0] HEX1,
	output[6:0] HEX2,
	output[6:0] HEX3,
	output[6:0] HEX4,
	output[6:0] HEX5,
	output[6:0] HEX6,
	output[6:0] HEX7,

	output SRAM_WE_N,
	output SRAM_OE_N,
	output SRAM_LB_N,
	output SRAM_UB_N,
	output SRAM_CE_N,
	inout[15:0] SRAM_DQ,
	output [19:0] SRAM_ADDR,
	
	output SD_CLK,
	output SD_CMD,
	inout[3:0] SD_DAT
);


wire[6:0] hexDisplay[8];

assign HEX0 = hexDisplay[0];
assign HEX1 = hexDisplay[1];
assign HEX2 = hexDisplay[2];
assign HEX3 = hexDisplay[3];
assign HEX4 = hexDisplay[4];
assign HEX5 = hexDisplay[5];
assign HEX6 = hexDisplay[6];
assign HEX7 = hexDisplay[7];

HEXDisplay32(debugOutput, hexDisplay);

wire[31:0] debugOutput;

reg clk;
reg clk_250kHz;
reg clk_250kHz_180;
reg[31:0] clk_ctr;
reg[31:0] clk_250kHz_ctr;
wire reset = SW[0];
wire cpu_run_stop = SW[1];

RAM ram(
	.clk(clk),
	.reset(reset),

	.read_channels(read_channels),
	.write_channels(write_channels),
	.sram(sram_i)
);

RAMReadChannel read_channels[2](.clk(clk));
RAMWriteChannel write_channels[2](.clk(clk));

SRAMInterface sram_i(
	.sig_read_n(SRAM_OE_N),
	.sig_write_n(SRAM_WE_N),
	.data(SRAM_DQ),
	.address(SRAM_ADDR),
	.high_byte_n(SRAM_UB_N),
	.low_byte_n(SRAM_LB_N)
);

assign SRAM_CE_N = 0;

CPU cpu(
	.clk(clk),
	.reset(cpu_run_stop),
	
	.m_in_ready(read_channels[0].Client.is_ready),
	.m_in_data(read_channels[0].Client.data),
	.m_in_addr(read_channels[0].Client.address),
	.m_in_sig_read(read_channels[0].Client.sig_read),
	
	.m_out_addr(write_channels[0].Client.address),
	.m_out_sig_write(write_channels[0].Client.sig_write),
	.m_out_data(write_channels[0].Client.data),
	.m_out_ready(write_channels[0].Client.is_ready),
	
);

SDInterface sd_interface(
	.clk(SD_CLK),
	.cmd(SD_CMD),
	.cs(SD_DAT[3]),
	.data(SD_DAT[0])
	
);

SDController sd_ctl(
	.clk(clk),
	.reset(reset),
	
	.ram_read(read_channels[1].Client),
	.ram_write(write_channels[1].Client),
	
	.sd(sd_interface.Controller),
	
	.sig_250kHz(clk_250kHz),
	.sig_250kHz_180(clk_250kHz_180),
	.debugOutput(debugOutput)

);

always @(posedge CLOCK_50 or posedge reset) if (reset) begin
	clk_ctr <= 0;
	clk_250kHz_ctr <= 0;
end else begin
	clk_ctr <= clk_ctr + 1;
	if (clk_ctr > 25) begin
		clk <= 1;
	end else begin
		clk <= 0;
		clk_250kHz <= 0;
		clk_250kHz_180 <= 0;
	end
	if (clk_ctr > 50) begin 
		clk_ctr <= 0;
		clk_250kHz_ctr <= clk_250kHz_ctr + 1;
		if (clk_250kHz_ctr == 1) begin
			clk_250kHz <= 1;
		end
		if (clk_250kHz_ctr == 3) begin
			clk_250kHz_ctr <= 0;
			clk_250kHz_180 <= 1;
		end
	end
	
	
	
end


endmodule
