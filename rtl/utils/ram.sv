interface RAMReadChannel(input clk);

	logic [31:0] address;
	logic [1:0] sig_read;
	logic [31:0] data;
	logic is_ready;
	
	modport Client(output address, output sig_read, output data, input is_ready);
	modport RAM(input address, input sig_read, input data, output is_ready);
	
endinterface

interface RAMWriteChannel(input clk);

	logic [31:0] address;
	logic [1:0] sig_write;
	logic [31:0] data;
	logic is_ready;
	
	modport Client(output address, output sig_write, input data, input is_ready);
	modport RAM(input address, input sig_write, output data, output is_ready);
	
endinterface

interface SRAMInterface(
	output sig_write_n,
	output sig_read_n,
	inout[15:0] data,
	output[19:0] address,
	output high_byte_n,
	output low_byte_n
);

endinterface


module RAM(
	input clk,
	input reset,
	
	SRAMInterface sram,
	
	RAMReadChannel read_channels[READ_CHANNELS_COUNT],
	RAMWriteChannel write_channels[WRITE_CHANNELS_COUNT]
);

	parameter READ_CHANNELS_COUNT = 1;
	parameter WRITE_CHANNELS_COUNT = 1;

	reg[1:0] sch_sig_read[READ_CHANNELS_COUNT];
	reg[31:0] sch_read_addr[READ_CHANNELS_COUNT];
	reg[31:0] read_data[READ_CHANNELS_COUNT];

	reg[1:0] sch_sig_write[WRITE_CHANNELS_COUNT];
	reg[31:0] sch_write_addr[WRITE_CHANNELS_COUNT];
	reg[31:0] sch_write_data[WRITE_CHANNELS_COUNT];
	
	wire[31:0] read_address[READ_CHANNELS_COUNT];
	wire[1:0] sig_read[READ_CHANNELS_COUNT];
	
	wire[31:0] write_address[WRITE_CHANNELS_COUNT];
	wire[1:0] sig_write[WRITE_CHANNELS_COUNT];
	wire[31:0] write_data[WRITE_CHANNELS_COUNT];

	
	generate
		genvar i;
		
		for (i = 0; i < READ_CHANNELS_COUNT; i = i + 1) begin : read_scheduling
			assign read_channels[i].data = read_data[i];
			assign read_channels[i].is_ready = sch_sig_read[i] == 0;
			assign read_address[i] = read_channels[i].address;
			assign sig_read[i] = read_channels[i].sig_read;
		end
		
		for (i = 0; i < WRITE_CHANNELS_COUNT; i = i + 1) begin : write_scheduling
			assign write_channels[i].is_ready = sch_sig_write[i] == 0;
			assign write_address[i] = write_channels[i].sig_write;
			assign sig_write[i] = write_channels[i].sig_write;
			assign write_data[i] = write_channels[i].data;
		end
				
	endgenerate
	
	reg[3:0] current_channel;
	
	enum reg[3:0] {
		ST_INITIAL,
		ST_READ_START,
		ST_WRITE_START,
		ST_READ_1,
		ST_READ_2,
		ST_READ_3,
		ST_WRITE_1,
		ST_WRITE_2,
		ST_WRITE_END
	} state;

	always @(posedge clk or posedge reset) begin
		if (reset) begin
			state <= ST_INITIAL;
			sram.sig_read_n <= 1;
			sram.sig_write_n <= 1;
			sram.low_byte_n <= 1;
			sram.high_byte_n <= 1;
			sram.address <= 0;
			sram.data <= 16'hZZZZ;
			
			for (int i = 0; i < READ_CHANNELS_COUNT; i = i + 1) begin
				sch_sig_read[i] <= 0;
			end
			
			for (int i = 0; i < WRITE_CHANNELS_COUNT; i = i + 1) begin	
				sch_sig_write[i] <= 0;
			end
			
		end else begin
		
			for (int i = 0; i < READ_CHANNELS_COUNT; i = i + 1) begin				
				if (sig_read[i] != 0 && sch_sig_read[i] == 0) begin
					sch_sig_read[i] <= sig_read[i];
					sch_read_addr[i] <= read_address[i];
				end
			end
			
			for (int i = 0; i < WRITE_CHANNELS_COUNT; i = i + 1) begin	
				if (sig_write[i] != 0 && sch_sig_write[i] == 0) begin
					sch_sig_write[i] <= sig_write[i];
					sch_write_addr[i] <= write_address[i];
					sch_write_data[i] <= write_data[i];
				end
			end
		
			case (state)
				ST_INITIAL: begin
						for (int i = 0; i < READ_CHANNELS_COUNT; i = i + 1) begin : read_start
							if (sch_sig_read[i] != 0) begin
								state <= ST_READ_START;
								current_channel <= i;
							end
						end
						for (int i = 0; i < WRITE_CHANNELS_COUNT; i = i + 1) begin : write_start
							if (sch_sig_write[i] != 0) begin
								state <= ST_WRITE_START;
								current_channel <= i;
							end
						end
				end
				ST_READ_START: begin
					if (sch_read_addr[current_channel][0] == 0) begin
						sram.sig_write_n <= 1;
						sram.sig_read_n <= 0;
						sram.data <= 16'hZZZZ;
						sram.address <= sch_read_addr[current_channel][20:1];
						sram.high_byte_n <= 0;
						sram.low_byte_n <= 0; 
					end else begin
						sram.sig_write_n <= 1;
						sram.sig_read_n <= 0;
						sram.data <= 16'hZZZZ;
						sram.address <= sch_read_addr[current_channel][20:1];
						sram.high_byte_n <= 0;
						sram.low_byte_n <= 0; 
					end
					state <= ST_READ_1;
				end
				ST_WRITE_START: begin
					if (sch_write_addr[current_channel][0] == 0) begin
						sram.sig_write_n <= 0;
						sram.sig_read_n <= 1;
						sram.data <= sch_write_data[current_channel][15:0];
						sram.address <= sch_read_addr[current_channel][20:1];
						sram.high_byte_n <= !(sch_sig_write[current_channel] > 1);
						sram.low_byte_n <= 0;
						if (sch_sig_write[current_channel] == 3) begin
							state <= ST_WRITE_1;
						end else begin
							sch_sig_write[current_channel] <= 0;
							state <= ST_WRITE_END;
						end
					end else begin
						sram.sig_write_n <= 0;
						sram.sig_read_n <= 1;
						sram.data <= { sch_write_data[current_channel][7:0], 8'h0 };
						sram.address <= sch_read_addr[current_channel][20:1];
						sram.high_byte_n <= 0;
						sram.low_byte_n <= 1;
						if (sch_sig_write[current_channel] > 13) begin
							state <= ST_WRITE_1;
						end else begin
							sch_sig_write[current_channel] <= 0;
							state <= ST_WRITE_END;
						end	
					end
				end
				ST_READ_1: begin
					if (sch_read_addr[current_channel][0] == 0) begin
						read_data[current_channel][15:0] <= sram.data;
						if (sch_sig_read[current_channel] < 3) begin
							sram.sig_write_n <= 1;
							sram.sig_read_n <= 1;
							sram.high_byte_n <= 1;
							sram.low_byte_n <= 1;
							sch_sig_read[current_channel] <= 0;
							state <= ST_INITIAL;
						end else begin
							sram.sig_write_n <= 1;
							sram.sig_read_n <= 0;
							sram.data <= 16'hZZZZ;
							sram.address <= sch_read_addr[current_channel][20:1] + 1;
							sram.high_byte_n <= 0;
							sram.low_byte_n <= 0; 
							state <= ST_READ_2;
						end
					end else begin
						read_data[current_channel][7:0] <= sram.data[15:8];
						if (sch_sig_read[current_channel] == 1) begin
							sram.sig_write_n <= 1;
							sram.sig_read_n <= 1;
							sram.high_byte_n <= 1;
							sram.low_byte_n <= 1;
							sch_sig_read[current_channel] <= 0;
							state <= ST_INITIAL;
						end else begin
							sram.sig_write_n <= 1;
							sram.sig_read_n <= 0;
							sram.data <= 16'hZZZZ;
							sram.address <= sch_read_addr[current_channel][20:1] + 1;
							sram.high_byte_n <= 0;
							sram.low_byte_n <= 0;
							state <= ST_READ_2;
						end
					end
				end
				ST_READ_2: begin
					if (sch_read_addr[current_channel][0] == 0) begin
						read_data[current_channel][31:16] <= sram.data;
						sram.sig_write_n <= 1;
						sram.sig_read_n <= 1;
						sram.high_byte_n <= 1;
						sram.low_byte_n <= 1;
						sch_sig_read[current_channel] <= 0;
						state <= ST_INITIAL;
					end else begin
						read_data[current_channel][23:8] <= sram.data;
						if (sch_sig_read[current_channel] < 3) begin
							sram.sig_write_n <= 1;
							sram.sig_read_n <= 1;
							sram.high_byte_n <= 1;
							sram.low_byte_n <= 1;
							sch_sig_read[current_channel] <= 0;
							state <= ST_INITIAL;
						end else begin
							sram.sig_write_n <= 1;
							sram.sig_read_n <= 0;
							sram.address <= sch_read_addr[current_channel][20:1] + 2;
							sram.high_byte_n <= 0;
							sram.low_byte_n <= 0;
							state <= ST_READ_3;
						end
					end
				end
				ST_READ_3: begin
					read_data[current_channel][31:24] <= sram.data[7:0];
					sram.sig_write_n <= 1;
					sram.sig_read_n <= 1;
					sram.high_byte_n <= 1;
					sram.low_byte_n <= 1;
					sch_sig_read[current_channel] <= 0;
					state <= ST_INITIAL;
				end
				ST_WRITE_1: begin
					if (sch_write_addr[current_channel][0] == 0) begin
						sram.data <= sch_write_data[current_channel][31:16];
						sram.address <= sch_write_addr[current_channel][20:1] + 1;
						sram.high_byte_n <= 0;
						sram.low_byte_n <= 0;
						sch_sig_write[current_channel] <= 0;
						state <= ST_WRITE_END;
					end else begin
						sram.data <= sch_write_data[current_channel][23:8];
						sram.address <= sch_write_addr[current_channel][20:1] + 1;
						if (sch_sig_write[current_channel] == 2) begin
							sram.high_byte_n <= 1;
							sram.low_byte_n <= 0;
							sch_sig_write[current_channel] <= 0;
							state <= ST_WRITE_END;
						end else begin
							sram.high_byte_n <= 0;
							sram.low_byte_n <= 0;
							state <= ST_WRITE_2;
						end
					end
				end
				ST_WRITE_2: begin
					sram.data <= { 8'h0, sch_write_data[current_channel][31:24] };
					sram.address <= sch_write_addr[current_channel][20:1] + 2;
					sram.high_byte_n <= 1;
					sram.low_byte_n <= 0;
					sch_sig_write[current_channel] <= 0;
					state <= ST_WRITE_END;
				end
				ST_WRITE_END: begin
					sram.sig_write_n <= 1;
					sram.sig_read_n <= 1;
					sram.high_byte_n <= 1;
					sram.low_byte_n <= 1;
					state <= ST_INITIAL;
				end
			endcase
		end
	end

endmodule
