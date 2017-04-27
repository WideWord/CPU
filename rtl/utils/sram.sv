module SRAMController(
	input clk,
	input reset,

	output reg writeEnabledN,
	output reg outputEnabledN,
	output reg lowByteN,
	output reg highByteN,
	inout reg[15:0] data,
	output reg[19:0] addr,
	
	input[31:0] m_in_addr,
	input[1:0] m_in_sig_read,
	output reg[31:0] m_in_data,
	output m_in_ready,
	
	input[31:0] m_out_addr,
	input[1:0] m_out_sig_write,
	input[31:0] m_out_data,
	output m_out_ready
);  

typedef enum reg[2:0] {
	ST_INITIAL,
	ST_WAITING,
	ST_UNALIGNED_0,
	ST_UNALIGNED_1,
	ST_UNALIGNED_2,
	ST_ALIGNED_0,
	ST_ALIGNED_1
} State;

State read_state;
State write_state;

assign m_in_ready = read_state == ST_INITIAL;
assign m_out_ready = write_state == ST_INITIAL;

reg[31:0] m_in_addr_c;
reg[1:0] m_in_sig_read_c;

reg[31:0] m_out_addr_c;
reg[1:0] m_out_sig_write_c;
reg[31:0] m_out_data_c;

always @(posedge clk or posedge reset) if (reset) begin
	writeEnabledN <= 1;
	outputEnabledN <= 1;
	lowByteN <= 1;
	highByteN <= 1;
	data <= 16'hZZZZ;
	addr <= 0;
	read_state <= ST_INITIAL;
	write_state <= ST_INITIAL;
	m_in_data <= 0;
end else begin
	case(read_state)
		ST_INITIAL: begin
			if (m_in_sig_read != 0) begin
				m_in_sig_read_c <= m_in_sig_read;
				m_in_addr_c <= m_in_addr;
				if (write_state == ST_INITIAL && m_out_sig_write == 0) begin
					outputEnabledN <= 0;
					lowByteN <= 0;
					highByteN <= 0;
					addr <= m_in_addr[20:1];
					read_state <= m_in_addr[0] ? ST_UNALIGNED_0 : ST_ALIGNED_0;
				end else begin
					read_state <= ST_WAITING;
				end
			end
		end
		ST_WAITING: begin
			if (write_state == ST_INITIAL) begin
				outputEnabledN <= 0;
				lowByteN <= 0;
				highByteN <= 0;
				addr <= m_in_addr_c[20:1];
				read_state <= m_in_addr_c[0] ? ST_UNALIGNED_0 : ST_ALIGNED_0;
			end
		end
		ST_ALIGNED_0: begin
			m_in_data[15:0] <= data;
			if (m_in_sig_read_c == 3) begin
				addr <= m_in_addr_c[20:1] + 1;
				read_state <= ST_ALIGNED_1;
			end else begin
				outputEnabledN <= 1;
				lowByteN <= 1;
				highByteN <= 1;
				read_state <= ST_INITIAL;
			end
		end
		ST_ALIGNED_1: begin
			m_in_data[31:16] <= data;
			outputEnabledN <= 1;
			lowByteN <= 1;
			highByteN <= 1;
			read_state <= ST_INITIAL;
		end
		ST_UNALIGNED_0: begin
			m_in_data[7:0] <= data[15:8];
			if (m_in_sig_read_c >= 2) begin
				addr <= m_in_addr_c[20:1] + 1;
				read_state <= ST_UNALIGNED_1;
			end else begin
				outputEnabledN <= 1;
				lowByteN <= 1;
				highByteN <= 1;
				read_state <= ST_INITIAL;
			end
		end
		ST_UNALIGNED_1: begin
			m_in_data[23:8] <= data;
			if (m_in_sig_read_c == 3) begin
				addr <= m_in_addr_c[20:1] + 1;
				read_state <= ST_UNALIGNED_2;
			end else begin
				outputEnabledN <= 1;
				lowByteN <= 1;
				highByteN <= 1;
				read_state <= ST_INITIAL;
			end
		end
		ST_UNALIGNED_2: begin
			m_in_data[31:24] <= data[7:0];
			outputEnabledN <= 1;
			lowByteN <= 1;
			highByteN <= 1;
			read_state <= ST_INITIAL;
		end
	endcase
	case (write_state)
		ST_INITIAL: begin
			if (m_out_sig_write != 0) begin
				m_out_addr_c <= m_out_addr;
				m_out_sig_write_c <= m_out_sig_write;
				m_out_data_c <= m_out_data;
				if (read_state == ST_INITIAL && m_in_sig_read == 0) begin
					writeEnabledN <= 0;
					addr <= m_out_addr[20:1];
					if (m_out_addr[0]) begin
						lowByteN <= 1;
						highByteN <= 0;
						data <= { m_out_data[7:0], 8'h0 };
						write_state <= ST_UNALIGNED_0;
					end else begin
						lowByteN <= 0;
						highByteN <= m_out_sig_write == 1;
						data <= m_out_data[15:0];
						write_state <= ST_ALIGNED_0;
					end
				end else begin
					write_state <= ST_WAITING;
				end
			end
		end
		ST_WAITING: begin
			if (read_state == ST_INITIAL) begin
				writeEnabledN <= 0;
				addr <= m_out_addr[20:1];
				if (m_out_addr_c[0]) begin
					lowByteN <= 1;
					highByteN <= 0;
					data <= { m_out_data_c[7:0], 8'h0 };
					write_state <= ST_UNALIGNED_0;
				end else begin
					lowByteN <= 0;
					highByteN <= m_out_sig_write_c == 1;
					data <= m_out_data_c[15:0];
					write_state <= ST_ALIGNED_0;
				end
			end
		end
		ST_ALIGNED_0: begin
			if (m_out_sig_write_c == 3) begin
				data <= m_out_data_c[31:16];
				write_state <= ST_ALIGNED_1;
			end else begin
				writeEnabledN <= 1;
				lowByteN <= 1;
				highByteN <= 1;
				data <= 16'hZZZZ;
				write_state <= ST_INITIAL;
			end
		end
		ST_ALIGNED_1: begin
			writeEnabledN <= 1;
			lowByteN <= 1;
			highByteN <= 1;
			data <= 16'hZZZZ;
			write_state <= ST_INITIAL;
		end
		ST_UNALIGNED_0: begin
			if (m_out_sig_write_c > 1) begin
				data <= m_out_data_c[23:8];
				highByteN <= m_out_sig_write_c == 2;
				write_state <= ST_UNALIGNED_1;
			end else begin
				writeEnabledN <= 1;
				lowByteN <= 1;
				highByteN <= 1;
				data <= 16'hZZZZ;
				write_state <= ST_INITIAL;
			end
		end
		ST_UNALIGNED_1: begin
			if (m_out_sig_write_c == 3) begin
				data <= {8'h0, m_out_data_c[31:24] };
				highByteN <= 1;
				write_state <= ST_UNALIGNED_2;
			end else begin
				writeEnabledN <= 1;
				lowByteN <= 1;
				highByteN <= 1;
				data <= 16'hZZZZ;
				write_state <= ST_INITIAL;
			end 
		end
		ST_UNALIGNED_2: begin
			writeEnabledN <= 1;
			lowByteN <= 1;
			highByteN <= 1;
			data <= 16'hZZZZ;
			write_state <= ST_INITIAL;
		end
	endcase
end



endmodule
