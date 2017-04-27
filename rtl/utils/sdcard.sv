interface SDInterface();

logic clk;
logic cmd;
logic data;

endinterface

module SDController(
	input reset,
	input clk,
	
	RAMReadChannel.Client ram_read,
	RAMWriteChannel.Client ram_write
);

	enum reg[3:0] {
		ST_BOOT,
		ST_WAITING
	} state;
	
	always @(posedge clk or posedge reset) begin
		if (reset) begin
			state <= ST_BOOT;	
		end else begin
			state <= ST_WAITING;
		end
	end


endmodule
