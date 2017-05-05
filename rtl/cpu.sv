module CPU(
	input clk,
	input reset,

	input m_in_ready,
	input[31:0] m_in_data,
	output reg[31:0] m_in_addr,
	output reg[1:0] m_in_sig_read,

	input m_out_ready,
	output reg[31:0] m_out_data,
	output reg[31:0] m_out_addr,
	output reg[1:0] m_out_sig_write,
	
	output[31:0] debugOutput
);

parameter REG_COUNT = 32;
parameter REG_FLAGS = 31;
parameter REG_SP = 30;

reg[31:0] regs[32];
reg[31:0] pc;
reg[31:0] interrupt_handler;
reg interrupt_enabled;

assign debugOutput = regs[0];

enum reg[2:0] {
	ST_FETCH_COMMAND,
	ST_WAIT_FETCH_COMMAND,
	ST_EXECUTE,
	ST_EXECUTE_1
} state;

reg[31:0] command;

wire[7:0] opcode = command[7:0];
wire[7:0] result_op = command[15:8];
wire[7:0] a_op = command[23:16];
wire[7:0] b_op = command[31:24];
wire[31:0] s_ba_op = { b_op[7] ? 16'hFFFF : 16'h0, b_op, a_op };
wire[31:0] s_b_op = { b_op[7] ? 24'hFFFFFF : 24'h0, b_op };
wire[31:0] s_ar_op = { a_op[7] ? 16'hFFFF : 16'h0, a_op, result_op };

wire condition = 	b_op == 0 ? 1 :
					(b_op[4:0] & regs[REG_FLAGS][4:0]) == 0 ? 0 : 1;

always @(posedge clk or posedge reset) if (reset) begin
	for (int i = 0; i < REG_COUNT; i = i + 1) regs[i] = 0;
	pc <= 0;
	state <= ST_FETCH_COMMAND;
	command <= 0;
	m_in_sig_read <= 0;
	m_out_sig_write <= 0;
	m_in_addr <= 0;
	m_out_addr <= 0;
	m_out_data <= 0;
	interrupt_handler <= 0;
	interrupt_enabled <= 0;
end else begin
	case (state)
	ST_FETCH_COMMAND: begin
		m_in_addr <= pc;
		m_in_sig_read <= 2'd3;
		state <= ST_WAIT_FETCH_COMMAND;
	end
	ST_WAIT_FETCH_COMMAND: begin
		m_in_sig_read <= 0;
		if (m_in_ready) begin
			command <= m_in_data;
			pc <= pc + 4;
			state <= ST_EXECUTE;
		end
 	end
 	ST_EXECUTE, ST_EXECUTE_1: begin
 		state <= ST_FETCH_COMMAND;
 		case (opcode)
 		8'h00: regs[result_op] <= regs[a_op];
 		8'h01: regs[result_op] <= regs[a_op] + regs[b_op];
 		8'h02: regs[result_op] <= regs[a_op] - regs[b_op];
 		8'h03: regs[result_op] <= regs[a_op] & regs[b_op];
 		8'h04: regs[result_op] <= regs[a_op] | regs[b_op];
 		8'h05: regs[result_op] <= regs[a_op] ^ regs[b_op];
 		8'h06: regs[result_op] <= ~regs[a_op];

 		8'h10: regs[result_op] <= { 16'h0, b_op, a_op };
 		8'h11: regs[result_op] <= s_ba_op;
 		8'h12: regs[result_op] <= { b_op, a_op, regs[result_op][15:0] };
 		8'h13: regs[result_op] <= regs[result_op] + s_ba_op;

 		8'h14: begin
 			regs[REG_FLAGS][0] <= regs[result_op] == regs[a_op];
 			regs[REG_FLAGS][1] <= regs[result_op] > regs[a_op];
 			regs[REG_FLAGS][2] <= regs[result_op] < regs[a_op];
 			regs[REG_FLAGS][3] <= $signed(regs[result_op]) > $signed(regs[a_op]);
 			regs[REG_FLAGS][4] <= $signed(regs[result_op]) < $signed(regs[a_op]);
 		end

 		8'h15: begin
 			regs[REG_FLAGS][0] <= regs[result_op] == { b_op, a_op };
 			regs[REG_FLAGS][1] <= regs[result_op] > { b_op, a_op };
 			regs[REG_FLAGS][2] <= regs[result_op] < { b_op, a_op };
 			regs[REG_FLAGS][3] <= $signed(regs[result_op]) > $signed({ b_op, a_op });
 			regs[REG_FLAGS][4] <= $signed(regs[result_op]) < $signed({ b_op, a_op });
 		end

 		8'h16: begin
 			regs[REG_FLAGS][0] <= regs[result_op] == s_ba_op;
 			regs[REG_FLAGS][1] <= regs[result_op] > s_ba_op;
 			regs[REG_FLAGS][2] <= regs[result_op] < s_ba_op;
 			regs[REG_FLAGS][3] <= $signed(regs[result_op]) > $signed(s_ba_op);
 			regs[REG_FLAGS][4] <= $signed(regs[result_op]) < $signed(s_ba_op);
 		end

 		8'h20: case (state)
 			ST_EXECUTE: begin
 				m_in_addr <= regs[a_op] + s_b_op;
 				m_in_sig_read <= 1;
 				state <= ST_EXECUTE_1;
 			end
 			ST_EXECUTE_1: begin
 				m_in_sig_read <= 0;
 				if (m_in_ready) begin
 					regs[result_op] <= { 24'd0, m_in_data[7:0] };
 					state <= ST_FETCH_COMMAND;
 				end else state <= ST_EXECUTE_1;
 			end
 		endcase

 		8'h21: case (state)
 			ST_EXECUTE: begin
 				m_in_addr <= regs[a_op] + s_b_op;
 				m_in_sig_read <= 1;
 				state <= ST_EXECUTE_1;
 			end
 			ST_EXECUTE_1: begin
 				m_in_sig_read <= 0;
 				if (m_in_ready) begin
 					regs[result_op] <= { m_in_data[7] ? 24'hFFFFFF : 24'h0, m_in_data[7:0] };
 					state <= ST_FETCH_COMMAND;
 				end else state <= ST_EXECUTE_1;
 			end
 		endcase

 		8'h22: case (state)
 			ST_EXECUTE: begin
 				m_in_addr <= regs[a_op] + s_b_op;
 				m_in_sig_read <= 2;
 				state <= ST_EXECUTE_1;
 			end
 			ST_EXECUTE_1: begin
 				m_in_sig_read <= 0;
 				if (m_in_ready) begin
 					regs[result_op] <= { 16'd0, m_in_data[15:0] };
 					state <= ST_FETCH_COMMAND;
 				end else state <= ST_EXECUTE_1;
 			end
 		endcase

 		8'h23: case (state)
 			ST_EXECUTE: begin
 				m_in_addr <= regs[a_op] + s_b_op;
 				m_in_sig_read <= 2;
 				state <= ST_EXECUTE_1;
 			end
 			ST_EXECUTE_1: begin
 				m_in_sig_read <= 0;
 				if (m_in_ready) begin
 					regs[result_op] <= { m_in_data[15] ? 16'hFFFF : 16'h0, m_in_data[15:0] };
 					state <= ST_FETCH_COMMAND;
 				end else state <= ST_EXECUTE_1;
 			end
 		endcase
 		
		8'h24: case (state)
 			ST_EXECUTE: begin
 				m_in_addr <= regs[a_op] + s_b_op;
 				m_in_sig_read <= 3;
 				state <= ST_EXECUTE_1;
 			end
 			ST_EXECUTE_1: begin
 				m_in_sig_read <= 0;
 				if (m_in_ready) begin
 					regs[result_op] <= m_in_data;
 					state <= ST_FETCH_COMMAND;
 				end else state <= ST_EXECUTE_1;
 			end
 		endcase

 		8'h25: case (state)
 			ST_EXECUTE: begin
 				m_out_addr <= regs[a_op] + s_b_op;
 				m_out_sig_write <= 1;
 				m_out_data <= regs[result_op];
 				state <= ST_EXECUTE_1;
 			end
 			ST_EXECUTE_1: begin
 				m_out_sig_write <= 0;
 				if (m_out_ready) begin
 					state <= ST_FETCH_COMMAND;
 				end else state <= ST_EXECUTE_1;
 			end
 		endcase

 		8'h26: case (state)
 			ST_EXECUTE: begin
 				m_out_addr <= regs[a_op] + s_b_op;
 				m_out_sig_write <= 2;
 				m_out_data <= regs[result_op];
 				state <= ST_EXECUTE_1;
 			end
 			ST_EXECUTE_1: begin
 				m_out_sig_write <= 0;
 				if (m_out_ready) begin
 					state <= ST_FETCH_COMMAND;
 				end else state <= ST_EXECUTE_1;
 			end
 		endcase

 		8'h27: case (state)
 			ST_EXECUTE: begin
 				m_out_addr <= regs[a_op] + s_b_op;
 				m_out_sig_write <= 3;
 				m_out_data <= regs[result_op];
 				state <= ST_EXECUTE_1;
 			end
 			ST_EXECUTE_1: begin
 				m_out_sig_write <= 0;
 				if (m_out_ready) begin
 					state <= ST_FETCH_COMMAND;
 				end else state <= ST_EXECUTE_1;
 			end
 		endcase

 		8'h30: if (condition) pc <= regs[result_op];
 		8'h31: if (condition) pc <= pc + s_ar_op;
 		8'h32: if (condition) pc <= { pc[31:24], a_op, result_op };

 		8'h33: case (state)
 			ST_EXECUTE: begin
 				if (condition) begin
 					regs[REG_SP] <= regs[REG_SP] - 32'd4;
 					m_out_addr <= regs[REG_SP] - 32'd4;
 					m_out_sig_write <= 3;
 					m_out_data <= pc;
 					state <= ST_EXECUTE_1;
 					pc <= regs[result_op];
 				end
 			end
 			ST_EXECUTE_1: begin
 				m_out_sig_write <= 0;
 				if (m_out_ready) begin
 					state <= ST_FETCH_COMMAND;
 				end else state <= ST_EXECUTE_1;
 			end
 		endcase

 		8'h34: case (state)
 			ST_EXECUTE: begin
 				if (condition) begin
 					regs[REG_SP] <= regs[REG_SP] - 32'd4;
 					m_out_addr <= regs[REG_SP] - 32'd4;
 					m_out_sig_write <= 3;
 					m_out_data <= pc;
 					state <= ST_EXECUTE_1;
 					pc <= pc + s_ar_op;
 				end
 			end
 			ST_EXECUTE_1: begin
 				m_out_sig_write <= 0;
 				if (m_out_ready) begin
 					state <= ST_FETCH_COMMAND;
 				end else state <= ST_EXECUTE_1;
 			end
 		endcase

 		8'h35: case (state)
			ST_EXECUTE: begin
				if (condition) begin
					regs[REG_SP] <= regs[REG_SP] - 32'd4;
					m_out_addr <= regs[REG_SP] - 32'd4;
					m_out_sig_write <= 3;
					m_out_data <= pc;
					state <= ST_EXECUTE_1;
					pc <= { pc[31:24], a_op, result_op };
				end
			end
			ST_EXECUTE_1: begin
				m_out_sig_write <= 0;
				if (m_out_ready) begin
					state <= ST_FETCH_COMMAND;
				end else state <= ST_EXECUTE_1;
			end
 		endcase

 		8'h36: case (state)
 			ST_EXECUTE: begin
				if (condition) begin
					regs[REG_SP] <= regs[REG_SP] + 32'd4;
					m_in_addr <= regs[REG_SP];
					m_in_sig_read <= 3;
					state <= ST_EXECUTE_1;
				end
			end
			ST_EXECUTE_1: begin
				m_in_sig_read <= 0;
				if (m_in_ready) begin
					pc <= m_in_data;
					state <= ST_FETCH_COMMAND;
				end else state <= ST_EXECUTE_1;
			end
 		endcase

 		8'h37: case (state)
 			ST_EXECUTE: begin
 				if (condition && interrupt_enabled) begin
 					regs[REG_SP] <= regs[REG_SP] - 32'd4;
 					m_out_addr <= regs[REG_SP] - 32'd4;
 					m_out_sig_write <= 3;
 					m_out_data <= pc;
 					state <= ST_EXECUTE_1;
 					pc <= interrupt_handler;
 				end
 			end
 			ST_EXECUTE_1: begin
 				m_out_sig_write <= 0;
 				if (m_out_ready) begin
 					state <= ST_FETCH_COMMAND;
 				end else state <= ST_EXECUTE_1;
 			end
 		endcase
 		
 		8'h38: interrupt_handler <= regs[result_op];
 		8'h39: interrupt_enabled <= result_op[0];
 		endcase
 	end
	endcase
end


endmodule
