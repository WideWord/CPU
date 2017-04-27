`include "rtl/cpu.sv"

module CPUTest();

reg[7:0] memory[255];

reg clk;
reg reset;

CPU cpu(
	.clk(clk),
	.reset(reset)
);

assign cpu.m_in_ready = 1;
assign cpu.m_in_data = { 
	memory[cpu.m_in_addr + 3],
	memory[cpu.m_in_addr + 2], 
	memory[cpu.m_in_addr + 1], 
	memory[cpu.m_in_addr] 
};

assign cpu.m_out_ready = 1;


always @(posedge clk) if (!reset) begin
	case (cpu.m_out_sig_write)
	1: memory[cpu.m_out_addr] <= cpu.m_out_data[7:0];
	2: begin
		memory[cpu.m_out_addr] <= cpu.m_out_data[7:0];
		memory[cpu.m_out_addr + 1] <= cpu.m_out_data[15:8];
	end
	3: begin
		memory[cpu.m_out_addr] <= cpu.m_out_data[7:0];
		memory[cpu.m_out_addr + 1] <= cpu.m_out_data[15:8];
		memory[cpu.m_out_addr + 2] <= cpu.m_out_data[23:16];
		memory[cpu.m_out_addr + 3] <= cpu.m_out_data[31:24];
	end
	endcase
end

initial begin
	for (int i = 0; i < 255; i = i + 1) memory[i] = 0;
	$readmemh("prog/multiply.bin", memory);
	$monitor($time,, cpu.regs[0],, cpu.regs[31][4:0] ,, cpu.b_op[4:0],, cpu.condition);
	reset = 1;
	clk = 0;
	#1
	reset = 0;
	#5000 $finish;
end

always #5 clk = ~clk;

endmodule