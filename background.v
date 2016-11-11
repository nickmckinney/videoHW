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
	output ram_hb,
	
	output reg [2:0] palAddr,
	input [255:0] palData
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
	wire [3:0] pixelMask;

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
		.pixelOut(pixelOut),
		.pixelMask(pixelMask)
	);

	reg [3:0] fifoAppend;
	reg [3:0] layerActive;
	reg pixelsActive;
	wire [15:0] fifoOut[3:0];
	wire [3:0] fifoEmpty;
	wire [3:0] fifoFull;
	reg [15:0] toAppendToFIFO[3:0];

	// fifo has a latency of 2 write cycles + 2 read cycles
	dualFifo	dualFifo_layer0 (
		.wrclk(clk),
		.data(toAppendToFIFO[0]),
		.wrreq(fifoAppend[0]),
		.wrfull(fifoFull[0]),
		
		.rdclk(clkPixel),
		.q(fifoOut[0]),
		.rdreq(layerActive[0] & ~fifoEmpty[0]),
		.rdempty(fifoEmpty[0])
	);

	dualFifo	dualFifo_layer1 (
		.wrclk(clk),
		.data(toAppendToFIFO[1]),
		.wrreq(fifoAppend[1]),
		.wrfull(fifoFull[1]),
		
		.rdclk(clkPixel),
		.q(fifoOut[1]),
		.rdreq(layerActive[1] & ~fifoEmpty[1]),
		.rdempty(fifoEmpty[1])
	);

	dualFifo	dualFifo_layer2 (
		.wrclk(clk),
		.data(toAppendToFIFO[2]),
		.wrreq(fifoAppend[2]),
		.wrfull(fifoFull[2]),
		
		.rdclk(clkPixel),
		.q(fifoOut[2]),
		.rdreq(layerActive[2] & ~fifoEmpty[2]),
		.rdempty(fifoEmpty[2])
	);

	dualFifo	dualFifo_layer3 (
		.wrclk(clk),
		.data(toAppendToFIFO[3]),
		.wrreq(fifoAppend[3]),
		.wrfull(fifoFull[3]),
		
		.rdclk(clkPixel),
		.q(fifoOut[3]),
		.rdreq(layerActive[3] & ~fifoEmpty[3]),
		.rdempty(fifoEmpty[3])
	);

	initial begin
		fifoAppend = 4'b0;
		layerActive = 4'b0;
		pixelsActive = 0;
		ram_ce = 1'b0;
		ram_oe = 1'b0;
		ram_we = 1'b0;
	end
	
	wire [17:0] nextAddrOffset [3:0];
	assign nextAddrOffset[0] = {6'b000010, nextVPos[8:3], 6'b0};  // int(nextVPos / 8) * 64 + 0x2000
	assign nextAddrOffset[1] = {6'b000011, nextVPos[8:3], 6'b0};  // int(nextVPos / 8) * 64 + 0x3000
	assign nextAddrOffset[2] = {6'b000100, nextVPos[8:3], 6'b0};  // int(nextVPos / 8) * 64 + 0x4000
	assign nextAddrOffset[3] = {6'b000101, nextVPos[8:3], 6'b0};  // int(nextVPos / 8) * 64 + 0x5000

	assign ram_hb = 1'b1;
	assign ram_lb = 1'b1;
	
	
	reg [15:0] tileData [3:0];
	reg [17:0] charAddr [3:0];
	reg [31:0] pixelsToColor [3:0];
	reg [255:0] curPalette [3:0];
	
	integer layer;

	/*
	
	character data:
	
	      V  H
	      F  F [pal num][   which tile to draw   ]

	F  E  D  C  B  A  9  8  7  6  5  4  3  2  1  0
	
	*/
	
	function [15:0] getColorFromPalette;
		input [255:0] palette;
		input [3:0] whichOne;
		
		begin
			case(whichOne)
				4'h0: getColorFromPalette = palette[15:0];
				4'h1: getColorFromPalette = palette[31:16];
				4'h2: getColorFromPalette = palette[47:32];
				4'h3: getColorFromPalette = palette[63:48];
				4'h4: getColorFromPalette = palette[79:64];
				4'h5: getColorFromPalette = palette[95:80];
				4'h6: getColorFromPalette = palette[111:96];
				4'h7: getColorFromPalette = palette[127:112];
				4'h8: getColorFromPalette = palette[143:128];
				4'h9: getColorFromPalette = palette[159:144];
				4'hA: getColorFromPalette = palette[175:160];
				4'hB: getColorFromPalette = palette[191:176];
				4'hC: getColorFromPalette = palette[207:192];
				4'hD: getColorFromPalette = palette[223:208];
				4'hE: getColorFromPalette = palette[239:224];
				4'hF: getColorFromPalette = palette[255:240];
			endcase
		end
	endfunction
	
	always @(posedge clk) begin
		ram_ce <= |charAddrOut | |tileLowAddrOut | |tileHighAddrOut;
		ram_oe <= |charAddrOut | |tileLowAddrOut | |tileHighAddrOut;
		
		ram_addr <= charAddrOut[0] ? charAddr[0] :
						charAddrOut[1] ? charAddr[1] :
						charAddrOut[2] ? charAddr[2] :
						charAddrOut[3] ? charAddr[3] :
						tileLowAddrOut[0] ? {5'b0, tileData[0][8:0], nextVPos[2:0], 1'b0} :
						tileLowAddrOut[1] ? {5'b0, tileData[1][8:0], nextVPos[2:0], 1'b0} :
						tileLowAddrOut[2] ? {5'b0, tileData[2][8:0], nextVPos[2:0], 1'b0} :
						tileLowAddrOut[3] ? {5'b0, tileData[3][8:0], nextVPos[2:0], 1'b0} :
						tileHighAddrOut[0] ? {5'b0, tileData[0][8:0], nextVPos[2:0], 1'b1} :
						tileHighAddrOut[1] ? {5'b0, tileData[1][8:0], nextVPos[2:0], 1'b1} :
						tileHighAddrOut[2] ? {5'b0, tileData[2][8:0], nextVPos[2:0], 1'b1} :
						tileHighAddrOut[3] ? {5'b0, tileData[3][8:0], nextVPos[2:0], 1'b1} :
						18'b0;

		palAddr <= ram_din[11:9];

		for(layer = 0; layer < 4; layer = layer + 1) begin
			charAddr[layer] <= (hsyncStarting & nextFrameActive) ? nextAddrOffset[layer] :
								charDataIn[layer] ? (charAddr[layer] + 1) : charAddr[layer];  // TODO: not quite right, needs to wrap around when panning

			if(charDataIn[layer]) tileData[layer] <= ram_din;
			if(palDataIn[layer]) curPalette[layer] <= palData;

			if(tileLowDataIn[layer]) pixelsToColor[layer][31:16] <= ram_din;

			fifoAppend[layer] <= pixelOut[layer] & pixelMask[layer];
			if(pixelOut[layer]) begin
				toAppendToFIFO[layer] <= getColorFromPalette(curPalette[layer], pixelsToColor[layer][31:28]);
				if(tileHighDataIn[layer])
					pixelsToColor[layer] <= {pixelsToColor[layer][27:20], ram_din, 8'h0};
				else
					pixelsToColor[layer] <= {pixelsToColor[layer][27:0], 4'b0000};
			end
		end
	end

	
	reg [11:0] foo;
	reg delayPixels;
	always @(posedge clkPixel) begin
		layerActive[3:1] <= layerActive[2:0];
		delayPixels <= layerActive[3];
		pixelsActive <= delayPixels;

		if(lineStarting) begin
			layerActive[0] <= 1;
			foo <= 0;
		end else if(pixelsActive)
			foo <= foo + 1;
		
		if(lineEnding) begin
			layerActive[0] <= 0;
		end
	end
	
	wire [15:0] compPixelOut [3:0];
	alphaBlend blender0 (
		.clk(clkPixel),
		.composited({4'b1111, foo[11:4], ~foo[3:0]}),
		//.composited(16'hF000),
		.toAdd(layersVisible[0] ? fifoOut[0] : 16'h0000),
		.out(compPixelOut[0])
	);
	alphaBlend blender1 (
		.clk(clkPixel),
		.composited(compPixelOut[0]),
		.toAdd(layersVisible[1] ? fifoOut[1] : 16'h0000),
		.out(compPixelOut[1])
	);
	alphaBlend blender2 (
		.clk(clkPixel),
		.composited(compPixelOut[1]),
		.toAdd(layersVisible[2] ? fifoOut[2] : 16'h0000),
		.out(compPixelOut[2])
	);
	alphaBlend blender3 (
		.clk(clkPixel),
		.composited(compPixelOut[2]),
		.toAdd(layersVisible[3] ? fifoOut[3] : 16'h0000),
		.out(compPixelOut[3])
	);

	assign red   = pixelsActive ? compPixelOut[3][3:0] : 4'h0;
	assign green = pixelsActive ? compPixelOut[3][7:4] : 4'h0;
	assign blue  = pixelsActive ? compPixelOut[3][11:8] : 4'h0;

endmodule
