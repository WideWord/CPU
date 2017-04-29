module SDBoot(
	input clk,
	input reset,
	
	SRAMInterface sram, 
	
	SDInterface sd,
	
	output logic ready,
	output logic[31:0] debugOutput
);

	typedef enum logic[15:0]  {
		WAIT_80_CLKS,
		INIT_0,
		INIT_1,
		INIT_2,
		INIT_3,
		INIT_4,
		INIT_5,
		INIT_6,
		INIT_7,
		INIT_8,
		INIT_9_0,
		INIT_9_1,
		INIT_9,
		INIT_10,
		INIT_11,
		INIT_12,
		INIT_13,
		INIT_14,
		BOOT,
		BOOT_1,
		BOOT_2,
		BOOT_3,
		BOOT_4,
		TRANSFER,
		TRANSFER_0,
		TRANSFER_CMD,
		TRANSFER_CMD_0,
		NOTHING
	} State;
	
	State state;
	State transfer_cmd_next_state;
	State transfer_next_state;
	
	reg[7:0] wait_ctr;
	
	reg[7:0] spi_data;
	reg[3:0] spi_ctr;
	
	reg[47:0] spi_cmd_data;
	reg[3:0] spi_cmd_ctr;
	
	wire sd_clk_allow = (state == TRANSFER || (state == TRANSFER_0 && spi_ctr != 7) || sd.cs);
	
	reg sd_cs_buf;
	
	reg[8:0] boot_ctr;
	reg[7:0] boot_buf;
	
	reg[7:0] init_9_0;
	
		
	assign sd.clk = clk | (~sd_clk_allow);
	
	always @(negedge clk or posedge reset) begin
		if (reset) begin
			sd.cmd <= 'd1;
			sd.cs <= 'd1;
		end else begin
			sd.cmd <= spi_data[7];
			sd.cs <= sd_cs_buf;
		end
	end

	always @(posedge clk or posedge reset) begin
		if (reset) begin
			sram.sig_write_n <= 1;
			sram.sig_read_n <= 1;
			sram.data <= 'bz;
			sram.address <= 'd0;
			sram.high_byte_n <= 'b0;
			sram.low_byte_n <= 'b0;
			state <= WAIT_80_CLKS;
			transfer_next_state <= NOTHING;
			transfer_cmd_next_state <= NOTHING;
			wait_ctr <= 'd0;
			sd_cs_buf <= 'b1;
			spi_data <= 'hFF;
			spi_ctr <= 'd0;
			ready <= 0;
			debugOutput <= 0;
			boot_ctr <= 0;
			spi_cmd_data <= 'd0;
			
		end else begin 
			case (state)
				WAIT_80_CLKS: begin
					wait_ctr <= wait_ctr + 'd1;
					if (wait_ctr == 'd80) begin
						sd_cs_buf <= 'd0;
						spi_cmd_data <= 48'h400000000095;
						state <= TRANSFER_CMD;
						transfer_cmd_next_state <= INIT_0;
					end
				end
				INIT_0: begin
					if (spi_data == 'hFF) begin
						spi_data <= 'hFF;
						state <= TRANSFER;
						transfer_next_state <= INIT_0;
					end else begin
						state <= INIT_1;
					end
				end
				INIT_1: begin
					spi_cmd_data <= 48'h48000001AA87;
					state <= TRANSFER_CMD;
					transfer_cmd_next_state <= INIT_2;
				end
				INIT_2: begin
					if (spi_data == 'hFF) begin
						spi_data <= 'hFF;
						state <= TRANSFER;
						transfer_next_state <= INIT_2;
					end else if (spi_data == 'h04) begin
						state <= INIT_3;
					end else if (spi_data == 'h01) begin
						state <= INIT_9_0;
					end
				end
				INIT_3: begin //v1
					if (spi_data == 'h00) begin
						state <= BOOT;
					end else begin
						spi_data <= 'h41;
						state <= TRANSFER;
						transfer_next_state <= INIT_4;
					end
				end
				INIT_4: begin
					if (spi_data == 'h00) begin
						state <= BOOT;
					end else begin
						spi_data <= 'h00;
						state <= TRANSFER;
						transfer_next_state <= INIT_5;
					end
				end
				INIT_5: begin
					if (spi_data == 'h00) begin
						state <= BOOT;
					end else begin
						spi_data <= 'h00;
						state <= TRANSFER;
						transfer_next_state <= INIT_6;
					end
				end
				INIT_6: begin
					if (spi_data == 'h00) begin
						state <= BOOT;
					end else begin
						spi_data <= 'h00;
						state <= TRANSFER;
						transfer_next_state <= INIT_7;
					end
				end
				INIT_7: begin
					if (spi_data == 'h00) begin
						state <= BOOT;
					end else begin
						spi_data <= 'h00;
						state <= TRANSFER;
						transfer_next_state <= INIT_8;
					end
				end
				INIT_8: begin
					if (spi_data == 'h00) begin
						state <= BOOT;
					end else begin
						spi_data <= 'h00;
						state <= TRANSFER;
						transfer_next_state <= INIT_3;
					end
				end
				INIT_9_0: begin
					init_9_0 <= 0;
					sd_cs_buf <= 1;
					state <= INIT_9_1;
				end
				INIT_9_1: begin
					if (init_9_0 == 255) begin
						sd_cs_buf <= 0;
						state <= INIT_9;
					end else begin
						init_9_0 <= init_9_0 + 1;
					end
				end
				INIT_9: begin //v2
					spi_cmd_data <= 48'h770000000000;
					state <= TRANSFER_CMD;
					transfer_cmd_next_state <= INIT_10;
				end
				INIT_10: begin
					if (spi_data == 'h1) begin
						state <= INIT_11;
					end else begin
						spi_data <= 'hFF;
						state <= TRANSFER;
						transfer_next_state <= INIT_10;
					end
				end
				INIT_11: begin
					spi_cmd_data <= 48'h6940000000FF;
					state <= TRANSFER_CMD;
					transfer_cmd_next_state <= INIT_12;
				end
				INIT_12: begin
					spi_data <= 'hFF;
					state <= TRANSFER;
					transfer_next_state <= INIT_13;
				end
				INIT_13: begin
					spi_data <= 'hFF;
					state <= TRANSFER;
					transfer_next_state <= INIT_14;
				end
				INIT_14: begin
					if (spi_data == 'h00) begin
						state <= BOOT;
					end else begin
						state <= INIT_9_0;
					end
				end
				
				BOOT: begin
					spi_cmd_data <= 48'h510000000000;
					transfer_cmd_next_state <= BOOT_1;
					state <= TRANSFER_CMD;
				end
				
				BOOT_1: begin
					if (spi_data == 'hFE) begin
						spi_data <= 'hFF;
						transfer_next_state <= BOOT_2;
						state <= TRANSFER;
					end else begin
						spi_data <= 'hFF;
						transfer_next_state <= BOOT_1;
						state <= TRANSFER;
						boot_ctr <= 0;
					end
				end
				
				BOOT_2: begin
					sram.sig_write_n <= 1;
					boot_buf <= spi_data;
					spi_data <= 'hFF;
					transfer_next_state <= BOOT_3;
					state <= TRANSFER;
				end
				
				BOOT_3: begin
					sram.data <= { spi_data, boot_buf };
					sram.sig_write_n <= 0;
					sram.address <= boot_ctr;
					boot_ctr <= boot_ctr + 1;
					
					if (boot_ctr == 255) begin
						spi_data <= 'hFF;
						transfer_next_state <= BOOT_4;
						state <= TRANSFER;
					end else begin
						spi_data <= 'hFF;
						transfer_next_state <= BOOT_2;
						state <= TRANSFER;
					end
				end
				
				BOOT_4: begin
					sram.sig_write_n <= 1;
					spi_data <= 'hFF;
					transfer_next_state <= NOTHING;
					state <= TRANSFER;
					ready <= 1;
				end
				
				TRANSFER: begin
					spi_data[7:1] <= spi_data[6:0];
					spi_data[0] <= sd.data;
					state <= TRANSFER_0;
					spi_ctr <= 0;
				end
				TRANSFER_0: begin
					if (spi_ctr == 7) begin
						state <= transfer_next_state;
					end else begin
						spi_ctr <= spi_ctr + 'd1;
						spi_data[7:1] <= spi_data[6:0];
						spi_data[0] <= sd.data;
					end
				end
				TRANSFER_CMD: begin
					spi_cmd_ctr <= 0;
					spi_data <= spi_cmd_data[47:40];
					spi_cmd_data <= { spi_cmd_data[39:0], 8'd0 };
					transfer_next_state <= TRANSFER_CMD_0;
					state <= TRANSFER;
				end
				TRANSFER_CMD_0: begin
					if (spi_cmd_ctr == 5) begin
						state <= transfer_cmd_next_state;
					end else begin
						spi_cmd_ctr <= spi_cmd_ctr + 'd1;
						spi_data <= spi_cmd_data[47:40];
						spi_cmd_data <= { spi_cmd_data[39:0], 8'd0 };
						state <= TRANSFER;
						transfer_next_state <= TRANSFER_CMD_0;
					end
				end
			endcase
		end
	end

endmodule
