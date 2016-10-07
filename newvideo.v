module newvideo (
	input clk50,
	output [3:0] red,
	output [3:0] green,
	output [3:0] blue,
	output hsync,
	output vsync
);

	wire clk40, clk100;
	wire locked;
	
	pll pll_inst (
		.areset(0),
		.inclk0(clk50),
		.c0(clk40),
		.c1(clk100),
		.locked(locked)
	);
	
	gensquares gensquares_inst (
		.clk40(clk40),
		.clk100(clk100),
		.red(red),
		.green(green),
		.blue(blue),
		.hsync(hsync),
		.vsync(vsync)
	);
	
endmodule
