module gensquares (
	input clk40,
	input clk100,
	output [3:0] red,
	output [3:0] green,
	output [3:0] blue,
	output hsync,
	output vsync
);

	wire videoActive;
	wire [9:0] hPos;
	wire [9:0] vPos;
	wire nextFrameActive;
	wire [9:0] nextVPos;
	wire lineStarting, lineEnding;
	
	frameGenerator #(.PIPELINE_DELAY(1)) frameGenerator_inst(
		.clk40(clk40),
		.hsync(hsync),
		.vsync(vsync),
		.videoActive(videoActive),
		.lineStarting(lineStarting),
		.lineEnding(lineEnding),
		.hPos(hPos),
		.vPos(vPos),
		.nextFrameActive(nextFrameActive),
		.nextVPos(nextVPos)
	);

	reg [9:0] testCounter;
	reg testAppend;
	reg lineActive;
	wire [15:0] fifoOut;
	wire fifoEmpty, fifoFull;
	
	// fifo has a latency of 2 write cycles + 2 read cycles
	dualFifo	dualFifo_inst (
		.wrclk(clk100),
		.data(testCounter + nextVPos),
		.wrreq(testAppend),
		.wrfull(fifoFull),
		
		.rdclk(clk40),
		.q(fifoOut),
		.rdreq(lineActive & ~fifoEmpty),
		.rdempty(fifoEmpty)
	);

	reg fifoState;
	
	initial begin
		testCounter = 0;
		testAppend = 0;
		fifoState = 0;
		lineActive = 0;
	end
	
	always @(posedge clk100) begin
		case(fifoState)
			0: begin
				if(hsync & nextFrameActive) begin
					fifoState <= 1;
					testAppend <= 1;
				end
			end
			
			1: begin
				if(testCounter == 10'd799) begin
					fifoState <= 0;
					testAppend <= 0;
					testCounter <= 0;
				end else testCounter <= testCounter + 1;
			end
		endcase
	end
	
	reg [15:0] tileRGB;

	always @(posedge clk40) begin
		if(lineStarting)
			lineActive <= 1;
		if(lineEnding)
			lineActive <= 0;

		if(videoActive & ~fifoEmpty) begin
			tileRGB <= fifoOut;
			//tileRGB <= (vPos < 10'd8) ? hPos : fifoOut;
		end else begin
			tileRGB <= 0;
		end
	end
	
	assign red   = videoActive ? tileRGB[3:0] : 4'h0;
	assign green  = videoActive ? tileRGB[7:4] : 4'h0;
	assign blue = videoActive ? tileRGB[11:8] : 4'h0;
	//assign green = videoActive ? (vPos < 10'd8 && (hPos == 69 || hPos == 540) ? 4'b1111 : tileRGB[11:8]) : 4'h0;

endmodule
