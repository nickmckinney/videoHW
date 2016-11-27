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
	
	output [2:0] palAddr,
	input [255:0] palData,
	
	input [3:0] layersVisible
);

	wire videoActive;
	wire [9:0] hPos;
	wire [9:0] vPos;
	wire nextFrameActive;
	wire [9:0] nextVPos;
	wire lineStarting, lineEnding, hsyncStarting, vsyncStarting;
	
	reg [8:0] pan0;
	reg [8:0] pan1;

	frameGenerator #(.PIPELINE_DELAY(5)) frameGenerator_inst(
		.clkPixel(clkPixel),
		.hsync(hsync),
		.vsync(vsync),
		.videoActive(videoActive),
		.lineStarting(lineStarting),
		.lineEnding(lineEnding),
		.hsyncStarting(hsyncStarting),
		.vsyncStarting(vsyncStarting),
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
		.ram_hb(ram_hb),
		
		.palAddr(palAddr),
		.palData(palData),
		
		.pan0(pan0),
		.pan1(pan1)
	);
	
	initial begin
		pan0 = 9'h0;
		pan1 = 9'h0;
	end
	
	reg foo;
	always @(posedge clkPixel) begin
		if(vsyncStarting) begin 
			pan0 <= pan0 + 1;
			foo <= ~foo;
			if(foo) pan1 <= pan1 + 1;
		end
	end

endmodule
