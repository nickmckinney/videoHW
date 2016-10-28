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

	output reg [17:0] ram_addr,
	input [15:0] ram_din,
	output reg [15:0] ram_dout,
	output reg ram_ce,
	output reg ram_oe,
	output reg ram_we,
	output ram_lb,
	output ram_hb
);

	reg [9:0] testCounter;
	reg testAppend;
	reg lineActive;
	reg pixelsActive;
	wire [15:0] fifoOut;
	wire fifoEmpty, fifoFull;
	
	// fifo has a latency of 2 write cycles + 2 read cycles
	dualFifo	dualFifo_inst (
		.wrclk(clk),
		.data(toAppendToFIFO),
		.wrreq(testAppend),
		.wrfull(fifoFull),
		
		.rdclk(clkPixel),
		.q(fifoOut),
		.rdreq(lineActive & ~fifoEmpty),
		.rdempty(fifoEmpty)
	);
	
	initial begin
		testCounter = 0;
		testAppend = 0;
		fifoState = 0;
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
	
	// 0 - idle
	// 1 - read character
	// 2 - read tile word 0
	// 3 - read tile word 1
	// 4 - load pixels into FIFO (x8)
	// 5 - wait state (temporary until I put together a more sophisticated state machine)
	reg [2:0] fifoState;

	reg [2:0] loadPxCount;
	reg [15:0] tileData;
	reg [15:0] toAppendToFIFO;
	reg [17:0] charAddr;
	
	reg [31:0] pixelsToColor;
	
	always @(posedge clk) begin
		case(fifoState)
			0: begin
				testAppend <= 0; // to save a cycle when exiting state 4, we'll do this here instead of having a state 5
				charAddr <= nextAddrOffset;
				ram_addr <= nextAddrOffset;
				if(hsyncStarting & nextFrameActive) begin
					fifoState <= 1;
					//charAddr <= nextAddrOffset;
					//ram_addr <= nextAddrOffset;
					ram_ce <= 1;
					ram_oe <= 1;
					// testCounter is already reset to 0
				end
			end
			
			// character format:
			//  xxxxxxxT TTTTTTTT
			// T: tile number
			1: begin
				testAppend <= 0; // to save a cycle when exiting state 4, we'll do this here instead of having a state 5
				
				// calculate and set ram_addr
				tileData <= ram_din;
				fifoState <= 2;
				ram_addr <= {5'b0, ram_din[8:0], nextVPos[2:0], 1'b0};
			end
			
			2: begin
				// capture tile word 0
				pixelsToColor[31:16] <= ram_din;
				
				// increment ram_addr
				ram_addr <= {5'b0, tileData[8:0], nextVPos[2:0], 1'b1};
				
				fifoState <= 3;
			end
			
			3: begin
				// capture tile word 1
				pixelsToColor[15:0] <= ram_din;
				
				fifoState <= 4;
				loadPxCount <= 0;
			end
			
			4: begin
				if(loadPxCount == 7) begin
					if(testCounter == 10'd39) begin
						fifoState <= 0;
						testCounter <= 0;
						ram_ce <= 0;
						ram_oe <= 0;
					end else begin
						fifoState <= 1;
						testCounter <= testCounter + 1;
						charAddr <= charAddr + 1;
						ram_addr <= charAddr + 1;
					end
				end
				
				loadPxCount <= loadPxCount + 1;
				testAppend <= 1;
				toAppendToFIFO <= {pixelsToColor[31:28], 12'hFFF};
				pixelsToColor <= {pixelsToColor[27:0], 4'b0000};
			end
		endcase
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
	
	wire [15:0] pixelOut;
	alphaBlend blender (
		.clk(clkPixel),
		.composited({4'b1111, foo}),
		.toAdd(fifoOut),
		.out(pixelOut)
	);
	
	assign red   = pixelsActive ? pixelOut[3:0] : 4'h0;
	assign green = pixelsActive ? pixelOut[7:4] : 4'h0;
	assign blue  = pixelsActive ? pixelOut[11:8] : 4'h0;

endmodule
