module background (
	input clkPixel,
	input clk,
	output [3:0] red,
	output [3:0] green,
	output [3:0] blue,
	output [3:0] alpha,
	input hsyncStarting,
	input nextFrameActive,
	input lineStarting,
	input lineEnding,
	input [9:0] nextVPos,
	input [3:0] layersVisible,

	output reg [17:0] ram_addr,
	input [15:0] ram_din,
	output reg [15:0] ram_dout,
	output reg ram_ce,
	output reg ram_oe,
	output reg ram_we,
	output ram_lb,
	output ram_hb
);

	wire [3:0] charAddrOut;
	wire [3:0] charDataIn;
	wire [3:0] palAddrOut;
	wire [3:0] palDataIn;
	wire [3:0] tileLowAddrOut;
	wire [3:0] tileHighAddrOut;
	wire [3:0] tileLowDataIn;
	wire [3:0] tileHighDataIn;
	wire [3:0] pixelOut;

	backgroundControl bgControl (
		.clk(clk),
		.lineStarting(hsyncStarting & nextFrameActive),
		.layer0Pan(4'b0),
		.layer1Pan(4'b0),
		.layer2Pan(4'b0),
		.layer3Pan(4'b0),

		.charAddrOut(charAddrOut),
		.charDataIn(charDataIn),
		.palAddrOut(palAddrOut),
		.palDataIn(palDataIn),
		.tileLowAddrOut(tileLowAddrOut),
		.tileHighAddrOut(tileHighAddrOut),
		.tileLowDataIn(tileLowDataIn),
		.tileHighDataIn(tileHighDataIn),
		.pixelOut(pixelOut)
	);

	reg testAppend;
	reg lineActive;
	reg pixelsActive;
	wire [15:0] fifoOut[3:0];
	wire fifoEmpty, fifoFull;
	reg [15:0] toAppendToFIFO[3:0];

	// fifo has a latency of 2 write cycles + 2 read cycles
	dualFifo	dualFifo_layer0 (
		.wrclk(clk),
		.data(toAppendToFIFO[0]),
		.wrreq(testAppend),
		.wrfull(fifoFull),
		
		.rdclk(clkPixel),
		.q(fifoOut[0]),
		.rdreq(lineActive & ~fifoEmpty),
		.rdempty(fifoEmpty)
	);
	
	initial begin
		//testCounter = 0;
		testAppend = 0;
		//fifoState = 0;
		lineActive = 0;
		pixelsActive = 0;
		ram_ce = 1'b0;
		ram_oe = 1'b0;
		ram_we = 1'b0;
	end
	
	wire [17:0] nextAddrOffset;
	assign nextAddrOffset = {5'b00001, nextVPos[9:3], 6'b0};  // int(nextVPos / 8) * 64 + 0x2000
	
	assign ram_hb = 1'b1;
	assign ram_lb = 1'b1;
	
	
	reg [15:0] tileData;
	reg [17:0] charAddr;
	reg [31:0] pixelsToColor;

	always @(posedge clk) begin
		if(hsyncStarting & nextFrameActive) charAddr <= nextAddrOffset;
		else if(charDataIn[0]) charAddr <= charAddr + 1;  // TODO: not quite right, needs to wrap around when panning
		
		ram_ce <= |charAddrOut | |tileLowAddrOut | |tileHighAddrOut;
		ram_oe <= |charAddrOut | |tileLowAddrOut | |tileHighAddrOut;
		
		ram_addr <= charAddrOut[0] ? charAddr :
			tileLowAddrOut[0] ? {5'b0, tileData[8:0], nextVPos[2:0], 1'b0} :
			tileHighAddrOut[0] ? {5'b0, tileData[8:0], nextVPos[2:0], 1'b1} :
			18'b0;
			
		if(charDataIn[0]) tileData <= ram_din;
		
		if(tileLowDataIn[0]) pixelsToColor[31:16] <= ram_din;
		
		testAppend <= pixelOut[0];
		if(pixelOut[0]) begin
			toAppendToFIFO[0] <= {pixelsToColor[31:28], 12'hFFF};
			if(tileHighDataIn)
				pixelsToColor <= {pixelsToColor[27:16], ram_din, 4'b0000};
			else
				pixelsToColor <= {pixelsToColor[27:0], 4'b0000};
		end
	end

	
	reg [11:0] foo;
	reg delayPixels;
	always @(posedge clkPixel) begin
		delayPixels <= lineActive;
		pixelsActive <= delayPixels;  // lags two cycles behind read request (TODO: need a better way to have a configurable delay)
		
		if(lineStarting) begin
			lineActive <= 1;
			foo <= 0;
		end else if(pixelsActive)
			foo <= foo + 1;
		
		if(lineEnding) begin
			lineActive <= 0;
		end
	end
	
	wire [15:0] compPixelOut;
	alphaBlend blender (
		.clk(clkPixel),
		.composited({4'b1111, foo}),
		.toAdd(layersVisible[0] ? fifoOut[0] : 16'h0000),
		.out(compPixelOut)
	);
	
	assign red   = pixelsActive ? compPixelOut[3:0] : 4'h0;
	assign green = pixelsActive ? compPixelOut[7:4] : 4'h0;
	assign blue  = pixelsActive ? compPixelOut[11:8] : 4'h0;

endmodule
