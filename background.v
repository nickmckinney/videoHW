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
		.data(ram_din),
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
		pixelsActive = 0;
		ram_ce = 1'b0;
		ram_oe = 1'b0;
		ram_we = 1'b0;
	end
	
	wire [19:0] nextAddrOffset;
	
	multBy800 mult_inst (
		.inNum(nextVPos),
		.outNum(nextAddrOffset)
	);
	
	assign ram_hb = 1'b1;
	assign ram_lb = 1'b1;
	
	always @(posedge clk100) begin
		case(fifoState)
			0: begin
				if(hsync & nextFrameActive) begin
					fifoState <= 1;
					testAppend <= 1;
					ram_addr <= nextAddrOffset[17:0];
					ram_ce <= 1;
					ram_oe <= 1;
				end
			end
			
			1: begin
				if(testCounter == 10'd799) begin
					fifoState <= 0;
					testAppend <= 0;
					testCounter <= 0;
					ram_ce <= 0;
					ram_oe <= 0;
				end else begin
					testCounter <= testCounter + 1;
					ram_addr <= ram_addr + 1;
				end
			end
		endcase
	end
	
	reg [15:0] tileRGB;

	always @(posedge clk40) begin
		pixelsActive <= lineActive;  // lags one cycle behind read request
		
		if(lineStarting)
			lineActive <= 1;
		if(lineEnding)
			lineActive <= 0;

		if(lineActive & ~fifoEmpty) begin
			tileRGB <= fifoOut;
			//tileRGB <= (vPos < 10'd8) ? hPos : fifoOut;
		end else begin
			tileRGB <= 0;
		end
	end
	
	assign red   = pixelsActive ? tileRGB[3:0] : 4'h0;
	assign green = pixelsActive ? tileRGB[7:4] : 4'h0;
	assign blue  = pixelsActive ? tileRGB[11:8] : 4'h0;

endmodule
