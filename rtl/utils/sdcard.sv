interface SDInterface(output clk, output cmd, input data, output cs);

	modport Controller(
		output clk,
		output cmd,
		input data,
		output cs
	);

endinterface

module SDController(
	input reset,
	input clk,
	input sig_250kHz,
	input sig_250kHz_180,
	
	output logic boot_ready,
	output logic[31:0] debugOutput,
	
	RAMReadChannel.Client ram_read,
	RAMWriteChannel.Client ram_write,
	SDInterface.Controller sd
);

	typedef enum logic[3:0] {
		ST_INITIALIZE_0,
		ST_INITIALIZE_1,
		ST_INITIALIZE_2,
		ST_INITIALIZE_3,
		ST_INITIALIZE_V1,
		ST_INITIALIZE_V2,
		ST_INITIALIZE_V2_1,
		ST_INITIALIZE_V2_2,
		ST_SEND_COMMAND,
		ST_BOOT,
		ST_BOOT_1,
		ST_BOOT_2,
		ST_BOOT_3,
		ST_BOOT_4,
		ST_BOOT_5,
		ST_WAITING
	} State;
	
	assign debugOutput[3:0] = state;
	assign debugOutput[31:24] = command[7:0];
	assign debugOutput[23:4] = 16'hFEED;
	
	State state;
	State next_state;
	
	reg[7:0] initializing_ctr;
	
	reg[47:0] command;
	reg[7:0] command_length;
	
	reg[8:0] boot_ctr;
	
	assign ram_read.sig_read = 0;
	assign ram_read.address = 0;
	
	always @(posedge clk or posedge reset) begin
		if (reset) begin
			state <= ST_INITIALIZE_0;
			next_state <= ST_WAITING;
			command <= 0;
			command_length <= 0;
			sd.cs <= 1;
			sd.cmd <= 1;
			initializing_ctr <= 0;
			boot_ctr <= 0;
			boot_ready <= 0;
		end else begin
			if (sig_250kHz && (state == ST_SEND_COMMAND || state == ST_INITIALIZE_0 )) 
				sd.clk <= 1;
			if (sig_250kHz_180) 
				sd.clk <= 0;
				
			case (state)
				ST_INITIALIZE_0: begin
					if (sig_250kHz) initializing_ctr <= initializing_ctr + 8'd1;
					if (initializing_ctr > 80) begin
						sd.cs <= 0;
						command <= 48'h400000000095;
						command_length <= 8'd48;
						state <= ST_SEND_COMMAND;
						next_state <= ST_INITIALIZE_1;
					end
				end
				ST_INITIALIZE_1: begin
					if (command[7:0] == 8'h1) begin
						state <= ST_INITIALIZE_2;
					end else begin 
						command_length <= 8'd8;
						command <= 48'hFFFFFFFFFFFF;
						state <= ST_SEND_COMMAND;
						next_state <= ST_INITIALIZE_1;
					end
				end
				ST_INITIALIZE_2: begin
					command <= 48'h48000001AA87;
					command_length <= 8'd48;
					state <= ST_SEND_COMMAND;
					next_state <= ST_INITIALIZE_3;
				end
				ST_INITIALIZE_3: begin
					if (command[7:0] == 8'hFF) begin
						command_length <= 8'd8;
						command <= 48'hFFFFFFFFFFFF;
						state <= ST_SEND_COMMAND;
						next_state <= ST_INITIALIZE_3;
					end else if (command[7:0] == 8'h4) begin // v1
						state <= ST_INITIALIZE_V1;
						command <= 48'hFFFFFFFFFFFF;
					end else begin // v2
						command <= 48'h770000000000;
						command_length <= 8'd48;
						state <= ST_SEND_COMMAND;
						next_state <= ST_INITIALIZE_V2;
					end
				end
				ST_INITIALIZE_V1: begin
					if (command != 48'hFFFFFFFFFFFF) begin
						state <= ST_BOOT;
					end else begin 
						command <= 48'h410000000000;
						command_length <= 8'd48;
						state <= ST_SEND_COMMAND;
						next_state <= ST_INITIALIZE_V1;
					end
				end
				ST_INITIALIZE_V2: begin
					if (command[7:0] == 8'h1) begin
						command <= 48'h6940000000FF;
						command_length <= 8'd48;
						state <= ST_SEND_COMMAND;
						next_state <= ST_INITIALIZE_V2_1;
					end else begin
						command <= 48'hFFFFFFFFFFFF;
						command_length <= 8'd8;
						state <= ST_SEND_COMMAND;
						next_state <= ST_INITIALIZE_V2;
					end
				end
				ST_INITIALIZE_V2_1: begin
					command <= 48'hFFFFFFFFFFFF;
					command_length <= 8'd16;
					state <= ST_SEND_COMMAND;
					next_state <= ST_INITIALIZE_V2_2;
				end
				ST_INITIALIZE_V2_2: begin
					if (command[7:0] == 8'h0) begin
						state <= ST_BOOT;
					end else begin
						command[7:0] <= 8'h1;
						state <= ST_INITIALIZE_V2;
					end
				end
				ST_SEND_COMMAND: begin
					if (sig_250kHz) begin
						command_length <= command_length - 8'd1;
						sd.cmd <= command[47];
						command[47:1] <= command[46:0];
						command[0] <= sd.data;
						if (command_length == 1) begin
							state <= next_state;
						end
					end
				end
				ST_BOOT: begin
					command <= 48'h510000000000;
					command_length <= 8'd48;
					state <= ST_SEND_COMMAND;
					next_state <= ST_BOOT_1;
				end
				ST_BOOT_1: begin
					if (command[7:0] == 8'h0) begin
						command <= 48'hFFFFFFFFFFFF;
						command_length <= 8'd8;
						state <= ST_SEND_COMMAND;
						next_state <= ST_BOOT_2;
					end else begin
						command <= 48'hFFFFFFFFFFFF;
						command_length <= 8'd8;
						state <= ST_SEND_COMMAND;
						next_state <= ST_BOOT_1;
					end
				end
				ST_BOOT_2: begin
					if (command[7:0] == 8'hFE) begin
						command <= 48'hFFFFFFFFFFFF;
						command_length <= 8'd8;
						state <= ST_SEND_COMMAND;
						next_state <= ST_BOOT_3;
					end else begin
						command <= 48'hFFFFFFFFFFFF;
						command_length <= 8'd8;
						state <= ST_SEND_COMMAND;
						next_state <= ST_BOOT_2;
					end
				end
				ST_BOOT_3: begin
					ram_write.address <= boot_ctr;
					ram_write.data <= { 24'd0, command[7:0] };
					ram_write.sig_write <= 1;
					boot_ctr <= boot_ctr + 9'd1;
					if (boot_ctr == 9'd511) begin
						state <= ST_BOOT_5;
					end else begin
						state <= ST_BOOT_4;
					end
				end
				ST_BOOT_4: begin
					ram_write.sig_write <= 0;
					if (ram_write.is_ready) begin
						command <= 48'hFFFFFFFFFFFF;
						command_length <= 8'd8;
						state <= ST_SEND_COMMAND;
						next_state <= ST_BOOT_3;
					end
				end
				ST_BOOT_5: begin
					ram_write.sig_write <= 0;
					if (ram_write.is_ready) begin
						boot_ready <= 1;
						state <= ST_WAITING;
					end
				end
				ST_WAITING: begin
				end
			endcase
		end
	end


endmodule
