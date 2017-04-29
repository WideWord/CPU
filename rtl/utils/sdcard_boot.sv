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
		INIT_9,
		INIT_10,
		INIT_11,
		INIT_12,
		INIT_13,
		INIT_14,
		INIT_15,
		INIT_16,
		INIT_17,
		INIT_18,
		INIT_19,
		INIT_20,
		INIT_21,
		INIT_22,
		INIT_23,
		INIT_24,
		INIT_25,
		INIT_26,
		INIT_27,
		INIT_28,
		INIT_29,
		INIT_30,
		INIT_31,
		INIT_32,
		INIT_33,
		INIT_34,
		INIT_35,
		INIT_36,
		BOOT,
		BOOT_1,
		BOOT_2,
		BOOT_3,
		BOOT_4,
		BOOT_5,
		BOOT_6,
		BOOT_7,
		BOOT_8,
		BOOT_9,
		BOOT_10,
		TRANSFER,
		TRANSFER_0,
		NOTHING
	} State;
	
	State state;
	State next_state;
	
	reg[7:0] wait_ctr;
	
	reg[7:0] spi_data;
	reg[3:0] spi_ctr;
	
	wire sd_clk_allow = (state == TRANSFER || (state == TRANSFER_0 && spi_ctr != 7) || state == WAIT_80_CLKS);
	
	reg sd_cs_buf;
	
	reg[8:0] boot_ctr;
	reg[7:0] boot_buf;
		
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
			next_state <= NOTHING;
			wait_ctr <= 'd0;
			sd_cs_buf <= 'b1;
			spi_data <= 'hFF;
			spi_ctr <= 'd0;
			ready <= 0;
			debugOutput <= 0;
			boot_ctr <= 0;
		end else begin 
			case (state)
				WAIT_80_CLKS: begin
					wait_ctr <= wait_ctr + 'd1;
					if (wait_ctr == 'd80) begin
						sd_cs_buf <= 'd0;
						spi_data <= 'h40;
						state <= TRANSFER;
						next_state <= INIT_0;
					end
				end
				INIT_0: begin
					spi_data <= 'h00;
					state <= TRANSFER;
					next_state <= INIT_1;
				end
				INIT_1: begin
					spi_data <= 'h00;
					state <= TRANSFER;
					next_state <= INIT_2;
				end
				INIT_2: begin
					spi_data <= 'h00;
					state <= TRANSFER;
					next_state <= INIT_3;
				end
				INIT_3: begin
					spi_data <= 'h00;
					state <= TRANSFER;
					next_state <= INIT_4;
				end
				INIT_4: begin
					spi_data <= 'h95;
					state <= TRANSFER;
					next_state <= INIT_5;
				end
				INIT_5: begin
					spi_data <= 'hFF;
					state <= TRANSFER;
					next_state <= INIT_6;
				end
				INIT_6: begin
					if (spi_data != 'h01) begin
						spi_data <= 'hFF;
						state <= TRANSFER;
						next_state <= INIT_6;
					end else begin
						state <= INIT_7;
					end
				end
				INIT_7: begin
					spi_data <= 'h48;
					state <= TRANSFER;
					next_state <= INIT_8;
				end
				INIT_8: begin
					spi_data <= 'h00;
					state <= TRANSFER;
					next_state <= INIT_9;
				end
				INIT_9: begin
					spi_data <= 'h00;
					state <= TRANSFER;
					next_state <= INIT_10;
				end
				INIT_10: begin
					spi_data <= 'h01;
					state <= TRANSFER;
					next_state <= INIT_11;
				end
				INIT_11: begin
					spi_data <= 'hAA;
					state <= TRANSFER;
					next_state <= INIT_12;
				end
				INIT_12: begin
					spi_data <= 'h87;
					state <= TRANSFER;
					next_state <= INIT_13;
				end
				INIT_13: begin
					spi_data <= 'hFF;
					state <= TRANSFER;
					next_state <= INIT_14;
				end
				INIT_14: begin
					if (spi_data == 'h01) begin
						state <= INIT_21;
					end else if (spi_data == 'h04) begin
						spi_data <= 'h41;
						state <= TRANSFER;
						next_state <= INIT_16;
					end else begin
						spi_data <= 'hFF;
						state <= TRANSFER;
						next_state <= INIT_14;
					end
				end
				INIT_15: begin // v1 init
					if (spi_data == 'h00) begin
						state <= BOOT;
					end else begin
						spi_data <= 'h41;
						state <= TRANSFER;
						next_state <= INIT_16;
					end
				end
				INIT_16: begin
					if (spi_data == 'h00) begin
						state <= BOOT;
					end else begin
						spi_data <= 'h00;
						state <= TRANSFER;
						next_state <= INIT_17;
					end
				end
				INIT_17: begin
					if (spi_data == 'h00) begin
						state <= BOOT;
					end else begin
						spi_data <= 'h00;
						state <= TRANSFER;
						next_state <= INIT_18;
					end
				end
				INIT_18: begin
					if (spi_data == 'h00) begin
						state <= BOOT;
					end else begin
						spi_data <= 'h00;
						state <= TRANSFER;
						next_state <= INIT_19;
					end
				end
				INIT_19: begin
					if (spi_data == 'h00) begin
						state <= BOOT;
					end else begin
						spi_data <= 'h00;
						state <= TRANSFER;
						next_state <= INIT_20;
					end
				end
				INIT_20: begin
					if (spi_data == 'h00) begin
						state <= BOOT;
					end else begin
						spi_data <= 'h00;
						state <= TRANSFER;
						next_state <= INIT_15;
					end
				end
				INIT_21: begin //v2
					spi_data <= 'h77;
					state <= TRANSFER;
					next_state <= INIT_22;
				end
				INIT_22: begin
					spi_data <= 'h00;
					state <= TRANSFER;
					next_state <= INIT_23;
				end
				INIT_23: begin
					spi_data <= 'h00;
					state <= TRANSFER;
					next_state <= INIT_24;
				end
				INIT_24: begin
					spi_data <= 'h00;
					state <= TRANSFER;
					next_state <= INIT_25;
				end
				INIT_25: begin
					spi_data <= 'h00;
					state <= TRANSFER;
					next_state <= INIT_26;
				end
				INIT_26: begin
					spi_data <= 'h00;
					state <= TRANSFER;
					next_state <= INIT_27;
				end
				INIT_27: begin
					if (spi_data == 'h01) begin
						state <= INIT_28;
					end else begin
						spi_data <= 'hFF;
						state <= TRANSFER;
						next_state <= INIT_27;
					end
				end
				INIT_28: begin
					spi_data <= 'h69;
					state <= TRANSFER;
					next_state <= INIT_29;
				end
				INIT_29: begin
					spi_data <= 'h00;
					state <= TRANSFER;
					next_state <= INIT_30;
				end
				INIT_30: begin
					spi_data <= 'h00;
					state <= TRANSFER;
					next_state <= INIT_31;
				end
				INIT_31: begin
					spi_data <= 'h00;
					state <= TRANSFER;
					next_state <= INIT_32;
				end
				INIT_32: begin
					spi_data <= 'h00;
					state <= TRANSFER;
					next_state <= INIT_33;
				end
				INIT_33: begin
					spi_data <= 'hFF;
					state <= TRANSFER;
					next_state <= INIT_34;
				end
				INIT_34: begin
					spi_data <= 'hFF;
					state <= TRANSFER;
					next_state <= INIT_35;
				end
				INIT_35: begin
					spi_data <= 'hFF;
					state <= TRANSFER;
					next_state <= INIT_36;
				end
				INIT_36: begin
					if (spi_data == 'h00) begin
						state <= BOOT;
					end else begin
						state <= INIT_21;
					end
				end
				BOOT: begin
					spi_data <= 'h51;
					state <= TRANSFER;
					next_state <= BOOT_1;
				end
				BOOT_1: begin
					spi_data <= 'h00;
					state <= TRANSFER;
					next_state <= BOOT_2;
				end
				BOOT_2: begin
					spi_data <= 'h00;
					state <= TRANSFER;
					next_state <= BOOT_3;
				end
				BOOT_3: begin
					spi_data <= 'h00;
					state <= TRANSFER;
					next_state <= BOOT_4;
				end
				BOOT_4: begin
					spi_data <= 'h00;
					state <= TRANSFER;
					next_state <= BOOT_5;
				end
				BOOT_5: begin
					spi_data <= 'h00;
					state <= TRANSFER;
					next_state <= BOOT_6;
				end
				BOOT_6: begin
					if (spi_data == 'h00) begin
						state <= BOOT_7;
					end else begin
						spi_data <= 'hFF;
						state <= TRANSFER;
						next_state <= BOOT_6;
					end
				end
				BOOT_7: begin
					if (spi_data == 'hFE) begin
						spi_data <= 'hFF;
						state <= TRANSFER;
						next_state <= BOOT_8;
					end else begin
						spi_data <= 'hFF;
						state <= TRANSFER;
						next_state <= BOOT_7;
					end
				end
				BOOT_8: begin
					sram.sig_write_n <= 1;
					sram.sig_read_n <= 1;
					boot_buf <= spi_data;
					spi_data <= 'hFF;
					state <= TRANSFER;
					next_state <= BOOT_9;
				end
				BOOT_9: begin
					sram.sig_write_n <= 0;
					sram.sig_read_n <= 1;
					sram.data <= { spi_data, boot_buf };
					sram.address <= boot_ctr;
					boot_ctr <= boot_ctr + 'd1;
					if (boot_ctr == 'd255) begin
						state <= BOOT_10;
					end else begin
						spi_data <= 'hFF;
						state <= TRANSFER;
						next_state <= BOOT_8;
					end
				end
				BOOT_10: begin
					sram.sig_write_n <= 1;
					sram.sig_read_n <= 1;
					ready <= 1;
					state <= NOTHING;
				end
				TRANSFER: begin
					spi_data[7:1] <= spi_data[6:0];
					spi_data[0] <= sd.data;
					state <= TRANSFER_0;
					spi_ctr <= 0;
				end
				TRANSFER_0: begin
					if (spi_ctr == 7) begin
						state <= next_state;
					end else begin
						spi_ctr <= spi_ctr + 'd1;
						spi_data[7:1] <= spi_data[6:0];
						spi_data[0] <= sd.data;
					end
				end
			endcase
		end
	end

endmodule
