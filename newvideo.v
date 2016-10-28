module newvideo (
	input clk50,
	output [3:0] red,
	output [3:0] green,
	output [3:0] blue,
	output hsync,
	output vsync,
	
	// SRAM interface
	output [17:0] sram_addr,
	inout [15:0] sram_data,
	output sram_ce_n,
	output sram_oe_n,
	output sram_we_n,
	output sram_lb_n,
	output sram_hb_n,
	
	input [3:0] layersVisible
);

	wire clkPixel, clk;
	wire locked;
	
	pll pll_inst (
		.areset(0),
		.inclk0(clk50),
		.c0(clkPixel),
		.c1(clk),
		.locked(locked)
	);
	
	wire sram_ce;
	wire sram_oe;
	wire sram_we;
	wire sram_lb;
	wire sram_hb;
	wire [15:0] sram_din;
	wire [15:0] sram_dout;
	
	assign sram_ce_n = ~sram_ce;
	assign sram_oe_n = ~sram_oe;
	assign sram_we_n = ~sram_we;
	assign sram_lb_n = ~sram_lb;
	assign sram_hb_n = ~sram_hb;
	
	assign sram_data = sram_we ? sram_dout : 16'bz;
	assign sram_din = sram_we ? 16'b0 : sram_data;

	gensquares gensquares_inst (
		.clkPixel(clkPixel),
		.clk(clk),
		.red(red),
		.green(green),
		.blue(blue),
		.hsync(hsync),
		.vsync(vsync),
		
		.ram_addr(sram_addr),
		.ram_din(sram_din),
		.ram_dout(sram_dout),
		.ram_ce(sram_ce),
		.ram_oe(sram_oe),
		.ram_we(sram_we),
		.ram_lb(sram_lb),
		.ram_hb(sram_hb),
		
		.layersVisible(layersVisible)
	);
	
endmodule
