module VideoCtl(
	input clk,
	input reset,
	input sig_write,
	input[19:0] pixel,
	input[23:0] color,

	input vga_clk,
	output[23:0] vga_color,
	output vga_hsync,
	output vga_vsync,
	output vga_blank_n,
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


reg[23:0] video_buffer[480000];

always @(posedge clk or posedge reset) begin
	if (reset) begin
		for (int i = 0; i < 480000; ++i)
			video_buffer[i] <= 0;
	end else begin
		if (sig_write) begin
			video_buffer[pixel] <= color[23:0];
		end
	end
end

reg[10:0] countV;
reg[10:0] countH;
reg[19:0] screenCtr; 

assign vga_pixel_clk = ~vga_clk;
assign vga_blank_n = ~((countV < V_BLANK_PIX) || (countH < H_BLANK_PIX));
assign vga_vsync = (countV >= V_FRONT_PORCH-1) && (countV <= V_FRONT_PORCH + V_SYNC_PULSE-1);
assign vga_vsync = ~((countH >= H_FRONT_PORCH-1) && (countH <= H_FRONT_PORCH + H_SYNC_PULSE-1));


always @(posedge vga_clk)
begin
    if (countH < H_TOTAL_PIX)
        countH <= countH + 1'b1;
    else
        countH <= 0;

    if ((countV >= V_BLANK_PIX - 1) && (countH >= H_BLANK_PIX - 1)) begin
    	vga_color <= video_buffer[screenCtr];
    	screenCtr <= screenCtr + 20'd1;
	end
end
 
always @(posedge hsync)
begin
    if (countV < V_TOTAL_PIX)
        countV <= countV + 1'b1;
    else begin
    	screenCtr <= 0;
        countV <= 0;
    end
end


endmodule
