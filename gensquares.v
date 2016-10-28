module gensquares (
	input clkPixel,
	input clk,
	output [3:0] red,
	output [3:0] green,
	output [3:0] blue,
	output hsync,
	output vsync,
	
	output [17:0] ram_addr,
	input [15:0] ram_din,
	output [15:0] ram_dout,
	output ram_ce,
	output ram_oe,
	output ram_we,
	output ram_lb,
	output ram_hb,
	
	input [3:0] layersVisible
);

	wire videoActive;
	wire [9:0] hPos;
	wire [9:0] vPos;
	wire nextFrameActive;
	wire [9:0] nextVPos;
	wire lineStarting, lineEnding, hsyncStarting;
	
	frameGenerator #(.PIPELINE_DELAY(2)) frameGenerator_inst(
		.clkPixel(clkPixel),
		.hsync(hsync),
		.vsync(vsync),
		.videoActive(videoActive),
		.lineStarting(lineStarting),
		.lineEnding(lineEnding),
		.hsyncStarting(hsyncStarting),
		.hPos(hPos),
		.vPos(vPos),
		.nextFrameActive(nextFrameActive),
		.nextVPos(nextVPos)
	);

	background background_inst (
		.clkPixel(clkPixel),
		.clk(clk),
		.red(red),
		.green(green),
		.blue(blue),
		//.alpha,
		.hsyncStarting(hsyncStarting),
		.nextFrameActive(nextFrameActive),
		.lineStarting(lineStarting),
		.lineEnding(lineEnding),
		.nextVPos(nextVPos),
		.layersVisible(layersVisible),

		.ram_addr(ram_addr),
		.ram_din(ram_din),
		.ram_dout(ram_dout),
		.ram_ce(ram_ce),
		.ram_oe(ram_oe),
		.ram_we(ram_we),
		.ram_lb(ram_lb),
		.ram_hb(ram_hb)
	);

endmodule
