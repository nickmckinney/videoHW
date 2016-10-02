module gensquares (
	input clk40,
	output [3:0] red,
	output [3:0] green,
	output [3:0] blue,
	output hsync,
	output vsync
);

	wire videoActive;
	wire [9:0] hPos;
	wire [9:0] vPos;
	
	frameGenerator frameGenerator_inst (
		.clk40(clk40),
		.hsync(hsync),
		.vsync(vsync),
		.videoActive(videoActive),
		.hPos(hPos),
		.vPos(vPos)
	);
	
	assign red   = (videoActive && hPos[4]) ? 4'hF : 4'h0;
	assign blue  = (videoActive && ~hPos[4]) ? 4'hF : 4'h0;
	assign green = (videoActive && vPos[4]) ? 4'hF : 4'h0;

endmodule
