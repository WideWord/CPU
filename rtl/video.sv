module VideoCtl(
	input clk,
	input reset,
	input sig_write,
	input[12:0] addr,
	input[31:0] value,

	input vga_clk,
	output[7:0] vga_r,
	output[7:0] vga_g,
	output[7:0] vga_b,
	output reg vga_hsync,
	output reg vga_vsync,
	output reg vga_blank_n,
	output vga_pixel_clk
);


parameter H_ACTIVE_VIDEO = 800;
parameter H_FRONT_PORCH = 40;
parameter H_SYNC_PULSE = 128;
parameter H_BACK_PORCH = 88;
parameter H_BLANK_PIX = H_FRONT_PORCH + H_SYNC_PULSE + H_BACK_PORCH;
parameter H_TOTAL_PIX = H_ACTIVE_VIDEO + H_BLANK_PIX;
 
parameter V_ACTIVE_VIDEO = 600;                            
parameter V_FRONT_PORCH = 1;
parameter V_SYNC_PULSE = 4;
parameter V_BACK_PORCH = 23;
parameter V_BLANK_PIX = V_FRONT_PORCH + V_SYNC_PULSE + V_BACK_PORCH;
parameter V_TOTAL_PIX = V_ACTIVE_VIDEO + V_BLANK_PIX;



reg[10:0] countV;
reg[10:0] countH;
reg[7:0] screenX;
reg[7:0] screenY;
reg[15:0] screenSym;
reg[15:0] screenSymRowStart;
reg[3:0] charX;
reg[3:0] charY;


reg[23:0] vga_color;

assign vga_r = vga_blank_n ? vga_color[7:0] : 8'd0;
assign vga_g = vga_blank_n ? vga_color[15:8] : 8'd0;
assign vga_b = vga_blank_n ? vga_color[23:16] : 8'd0;

assign vga_pixel_clk = ~vga_clk;

reg st_wren;
reg[31:0] st_data;
reg[9:0] st_wr_addr;

reg[31:0] st_q;
reg[9:0] st_rd_addr;

vram_st vram_st(
	.wrclock(clk),
	.wren(st_wren),
	.data(st_data),
	.wraddress(st_wr_addr),
	
	.rdclock(vga_clk),
	.q(st_q),
	.rdaddress(st_rd_addr)
);

reg s_wren;
reg[15:0] s_data;
reg[12:0] s_wr_addr;

reg[15:0] s_q;
reg[12:0] s_rd_addr;

vram_s vram_s(
	.wrclock(clk),
	.wren(s_wren),
	.data(s_data),
	.wraddress(s_wr_addr),
	
	.rdclock(vga_clk),
	.q(s_q),
	.rdaddress(s_rd_addr)
);

reg sig_write_buf;
reg[12:0] addr_buf;
reg[31:0] value_buf;

always @(posedge clk or posedge reset) begin
	if (reset) begin
		st_wren <= 0;
		s_wren <= 0;
		
		sig_write_buf <= 0;
		addr_buf <= 0;
		value_buf <= 0;
	end else begin
	
		sig_write_buf <= sig_write;
		addr_buf <= addr;
		value_buf <= value;
	
		st_wren <= 0;
		s_wren <= 0;
	
		if (sig_write_buf) begin
			if (addr_buf < 1024) begin
				st_wr_addr <= addr_buf;
				st_data <= value_buf;
				st_wren <= 1;
			end else begin
				s_wr_addr <= addr_buf - 1024;
				s_data <= value_buf;
				s_wren <= 1;
			end
		end
	end
end

reg blank_n_buf[2];
reg hsync_buf[2];
reg vsync_buf[2];
reg[3:0] charX_buf[2];
reg[3:0] charY_buf[2];

always @(posedge vga_clk or posedge reset) begin

	if (reset) begin
		countV <= 0;
		charX <= 0;
		charY <= 0;
		screenX <= 0;
		screenY <= 0;
		screenSymRowStart <= 0;
		screenSym <= 0;
	end else begin
	
		if (countH >= H_BLANK_PIX) begin
			if (charX < 7) begin
				charX <= charX + 1;
			end else begin
				charX <= 0;
				screenX <= screenX + 1;
				screenSym <= screenSym + 1;
			end
		end

		if (countH < H_TOTAL_PIX - 1)
			countH <= countH + 1;
		else begin
			countH <= 0;
			charX <= 0;
			screenX <= 0;

			if (countV >= V_BLANK_PIX) begin
				if (charY < 11) begin
					charY <= charY + 1;
					screenSym <= screenSymRowStart;
				end else begin
					screenSym <= screenSymRowStart + 100;
					screenSymRowStart <= screenSymRowStart + 100;
					charY <= 0;
					screenY <= screenY + 1;
				end
			end

			if (countV < V_TOTAL_PIX - 1)
				countV <= countV + 1;
			else begin
				countV <= 0;
				charX <= 0;
				charY <= 0;
				screenX <= 0;
				screenY <= 0;
				screenSymRowStart <= 0;
				screenSym <= 0;
			end
		end
		
		///////
		
		s_rd_addr <= screenSym;
		
		blank_n_buf[0] <= ~((countV < V_BLANK_PIX) || (countH < H_BLANK_PIX));
		vsync_buf[0] <= (countV >= V_FRONT_PORCH-1) && (countV <= V_FRONT_PORCH + V_SYNC_PULSE-1);
		hsync_buf[0] <= ~((countH >= H_FRONT_PORCH-1) && (countH <= H_FRONT_PORCH + H_SYNC_PULSE-1));
		
		charX_buf[0] <= charX;
		charY_buf[0] <= charY;
		
		////////
		
		st_rd_addr <= { s_q, charY_buf[0][3:2] };
		
		charX_buf[1] <= charX_buf[0];
		charY_buf[1] <= charY_buf[0];
		
		blank_n_buf[1] <= blank_n_buf[0];
		vsync_buf[1] <= vsync_buf[0];
		hsync_buf[1] <= hsync_buf[0];
		
		/////////
		
		vga_color <= st_q[{charY_buf[1][1:0], charX_buf[1][2:0]}] ? 24'hFFFFFF : 24'h0;
		
		vga_blank_n <= blank_n_buf[1];
		vga_vsync <= vsync_buf[1];
		vga_hsync <= hsync_buf[1];
		
		
	end
	
end



endmodule
