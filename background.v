module background (
	input clk40,
	input clk100,
	output [3:0] red,
	output [3:0] green,
	output [3:0] blue,
	output [3:0] alpha,
	input hsync,
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
		.wrclk(clk100),
		.data(toAppendToFIFO),
		.wrreq(testAppend),
		.wrfull(fifoFull),
		
		.rdclk(clk40),
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
	assign nextAddrOffset = {4'b0, nextVPos[9:3], 7'b0};  // int(nextVPos / 8) * 128
	
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
	reg [8:0] tileId;
	reg [15:0] toAppendToFIFO;
	reg [17:0] charAddr;
	
	always @(posedge clk100) begin
		case(fifoState)
			0: begin
				testAppend <= 0; // to save a cycle when exiting state 4, we'll do this here instead of having a state 5
				charAddr <= nextAddrOffset;
				ram_addr <= nextAddrOffset;
				if(hsync & nextFrameActive) begin
					fifoState <= 5;
					//charAddr <= nextAddrOffset;
					//ram_addr <= nextAddrOffset;
					ram_ce <= 1;
					ram_oe <= 1;
					// testCounter is already reset to 0
				end
			end
			
			5: begin
				testAppend <= 0; // to save a cycle when exiting state 4, we'll do this here instead of having a state 5
				fifoState <= 1;
			end
			
			// character format:
			//  xxxxxxxT TTTTTTTT
			// T: tile number
			1: begin
				testAppend <= 0; // to save a cycle when exiting state 4, we'll do this here instead of having a state 5
				
				// calculate and set ram_addr
				tileId <= ram_din[8:0];
				fifoState <= 2;
				//ram_addr <= 17'h0FFFF;
			end
			
			2: begin
				// capture tile word 0
				// increment ram_addr
				fifoState <= 3;
			end
			
			3: begin
				// capture tile word 1
				fifoState <= 4;
				loadPxCount <= 0;
			end
			
			4: begin
				if(loadPxCount == 7) begin
					if(testCounter == 10'd99) begin
						fifoState <= 0;
						testCounter <= 0;
						ram_ce <= 0;
						ram_oe <= 0;
					end else begin
						fifoState <= 5;
						testCounter <= testCounter + 1;
						charAddr <= charAddr + 1;
						ram_addr <= charAddr + 1;
					end
				end
				
				loadPxCount <= loadPxCount + 1;
				testAppend <= 1;
				toAppendToFIFO <= tileId;
			end
		endcase
	end
	
	always @(posedge clk40) begin
		pixelsActive <= lineActive;  // lags one cycle behind read request
		
		if(lineStarting)
			lineActive <= 1;
		if(lineEnding)
			lineActive <= 0;
	end
	
	assign red   = pixelsActive ? fifoOut[3:0] : 4'h0;
	assign green = pixelsActive ? fifoOut[7:4] : 4'h0;
	assign blue  = pixelsActive ? fifoOut[11:8] : 4'h0;

endmodule
