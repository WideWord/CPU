
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
	output [19:0] SRAM_ADDR
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
wire clk = clk_ctr < 2000;
reg[31:0] clk_ctr;
wire reset = SW[0];

SRAMController sram_controller(
	.clk(clk),
	.reset(reset),
	.writeEnabledN(SRAM_WE_N),
	.outputEnabledN(SRAM_OE_N),
	.lowByteN(SRAM_LB_N),
	.highByteN(SRAM_UB_N),
	.data(SRAM_DQ),
	.addr(SRAM_ADDR),
	
	.m_in_ready(m_in_ready),
	.m_in_data(m_in_data),
	.m_in_addr(m_in_addr),
	.m_in_sig_read(m_in_sig_read),
	
	.m_out_addr(m_out_addr),
	.m_out_sig_write(m_out_sig_write),
	.m_out_data(m_out_data),
	.m_out_ready(m_out_ready)

);

wire[31:0] m_in_addr;
wire[1:0] m_in_sig_read;
wire[31:0] m_in_data;
wire m_in_ready;

wire[31:0] m_out_addr;
wire[1:0] m_out_sig_write;
wire[31:0] m_out_data;
wire m_out_ready;

CPU cpu(
	.clk(clk),
	.reset(reset),
	
	.m_in_ready(m_in_ready),
	.m_in_data(m_in_data),
	.m_in_addr(m_in_addr),
	.m_in_sig_read(m_in_sig_read),
	
	.m_out_addr(m_out_addr),
	.m_out_sig_write(m_out_sig_write),
	.m_out_data(m_out_data),
	.m_out_ready(m_out_ready),
	
	.debugOutput(debugOutput)
);



always @(posedge CLOCK_50 or posedge reset) if (reset) begin
	clk_ctr <= 0;
end else begin
	clk_ctr <= clk_ctr + 1;
	if (clk_ctr > 10000) clk_ctr <= 0;
end


endmodule
