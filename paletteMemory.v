module paletteMemory (
	input clk,
	input [2:0] addr,
	input we,
	output [255:0] out
);

	/*reg [2:0] foo;
	
	always @(posedge clk) begin
		foo <= addr;
	end
	
	assign out = {foo, foo[0], 12'hFFF};*/
	
palRam	palRam_inst (
	.address_a ( addr ),
	.address_b ( 0 ),
	.clock_a ( clk ),
	.clock_b ( clk ),
	.data_a ( data_a_sig ),
	//.data_b ( data_b_sig ),
	.wren_a ( we ),
	.wren_b ( 1'b0 ),
	.q_a ( out )
	//.q_b ( q_b_sig )
	);

endmodule
