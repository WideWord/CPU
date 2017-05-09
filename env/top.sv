
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
	inout[3:0] SD_DAT,
	
	output[8:0] LEDG,
	
	output VGA_CLK,
	output VGA_BLANK_N,
	output[7:0] VGA_R,
	output[7:0] VGA_G,
	output[7:0] VGA_B,
	output VGA_SYNC_N,
	output VGA_HS,
	output VGA_VS
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

pll pll(
	.areset(reset),
	.inclk0(CLOCK_50),
	.c0(clk_250kHz),
	.c1(clk_40MHz),
	.c2(clk_50MHz)
);


wire clk_250kHz;
wire clk_50MHz;
wire clk_40MHz;
wire reset = SW[0];

RAM ram(
	.clk(clk_50MHz),
	.reset(reset),

	.read_channels(read_channels),
	.write_channels(write_channels),
	.sram(sram),
	
	.video_color(video_color),
	.video_addr(video_addr),
	.video_sig_write(video_sig_write)
);

RAMReadChannel read_channels[1]();
RAMWriteChannel write_channels[2]();

SRAMInterface sram(
	.sig_read_n(SRAM_OE_N),
	.sig_write_n(SRAM_WE_N),
	.data(SRAM_DQ),
	.address(SRAM_ADDR),
	.high_byte_n(SRAM_UB_N),
	.low_byte_n(SRAM_LB_N)
);

assign SRAM_CE_N = 0;

CPU cpu(
	.clk(clk_50MHz),
	.reset(~boot_ready),
	
	.m_in_ready(read_channels[0].Client.is_ready),
	.m_in_data(read_channels[0].Client.data),
	.m_in_addr(read_channels[0].Client.address),
	.m_in_sig_read(read_channels[0].Client.sig_read),
	
	.m_out_addr(write_channels[0].Client.address),
	.m_out_sig_write(write_channels[0].Client.sig_write),
	.m_out_data(write_channels[0].Client.data),
	.m_out_ready(write_channels[0].Client.is_ready),
	
	.debugOutput(debugOutput)
);

SDInterface sd(
	.clk(SD_CLK),
	.cmd(SD_CMD),
	.cs(SD_DAT[3]),
	.data(SD_DAT[0])
);

wire boot_ready;


SDBoot sd_boot(
	.clk(clk_250kHz),
	.reset(reset),
	
	.sd(sd),
	.ram_write(write_channels[1].Client),
	
	.ready(boot_ready)
);

assign LEDG[8:1] = 0;
assign LEDG[0] = boot_ready;


wire[12:0] video_addr;
wire[31:0] video_color;
wire video_sig_write;

assign VGA_SYNC_N = 0;

VideoCtl video_ctl(
	.clk(clk_50MHz), 
	.reset(reset),
	.sig_write(video_sig_write),
	.addr(video_addr),
	.value(video_color),
	.vga_clk(clk_40MHz),
	.vga_pixel_clk(VGA_CLK),
	.vga_r(VGA_R),
	.vga_g(VGA_G),
	.vga_b(VGA_B),
	.vga_blank_n(VGA_BLANK_N),
	.vga_hsync(VGA_HS),
	.vga_vsync(VGA_VS)
);

endmodule
