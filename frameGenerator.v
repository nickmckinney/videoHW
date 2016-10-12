module frameGenerator #(
	// can specify the video pipeline length to get enough advance notice via lineStarting and
	// lineEnding so that the data is ready at the end of the pipe by the time it's needed
	parameter PIPELINE_DELAY = 0
)
(
	input clk40,
	output reg hsync,
	output reg vsync,
	output videoActive,
	output lineStarting,  // active for the one pixel just before the line starts
	output lineEnding,    // active for the one pixel just before the line ends
	output hsyncStarting,
	output [9:0] hPos,
	output [9:0] vPos,
	output nextFrameActive,
	output [9:0] nextVPos
);

	localparam HSYNC_POLARITY_IS_POSITIVE = 0;
	localparam HORIZ_VISIBLE = 11'd640;
	localparam HORIZ_FRONT_PORCH = 11'd16;
	localparam HORIZ_SYNC = 11'd96;
	localparam HORIZ_BACK_PORCH = 11'd48;
	localparam HORIZ_TOTAL = (HORIZ_VISIBLE + HORIZ_FRONT_PORCH + HORIZ_SYNC + HORIZ_BACK_PORCH);
	localparam HORIZ_START_FRONT_PORCH = HORIZ_VISIBLE - 1;
	localparam HORIZ_START_SYNC = HORIZ_START_FRONT_PORCH + HORIZ_FRONT_PORCH;
	localparam HORIZ_START_BACK_PORCH = HORIZ_START_SYNC + HORIZ_SYNC;
	localparam HORIZ_END_LINE = HORIZ_TOTAL - 1;
	
	localparam VSYNC_POLARITY_IS_POSITIVE = 0;
	localparam VERT_VISIBLE = 10'd480;
	localparam VERT_FRONT_PORCH = 10'd10;
	localparam VERT_SYNC = 10'd2;
	localparam VERT_BACK_PORCH = 10'd33;
	localparam VERT_TOTAL = (VERT_VISIBLE + VERT_FRONT_PORCH + VERT_SYNC + VERT_BACK_PORCH);
	localparam VERT_START_FRONT_PORCH = VERT_VISIBLE - 1;
	localparam VERT_START_SYNC = VERT_START_FRONT_PORCH + VERT_FRONT_PORCH;
	localparam VERT_START_BACK_PORCH = VERT_START_SYNC + VERT_SYNC;
	localparam VERT_END_LINE = VERT_TOTAL - 1;
	
	reg [10:0] hposCount;
	reg [9:0] vposCount;
	reg [9:0] nextVposCount;
	wire frameActive;
	wire lineActive;
	
	initial begin
		hposCount <= 0;
		vposCount <= 0;
		nextVposCount <= 0;
		hsync <= ~HSYNC_POLARITY_IS_POSITIVE;
		vsync <= ~VSYNC_POLARITY_IS_POSITIVE;
	end
	
	assign lineActive = (hposCount < HORIZ_VISIBLE);
	assign frameActive = (vposCount < VERT_VISIBLE);
	assign videoActive = lineActive & frameActive;
	
	assign lineStarting = (hposCount == HORIZ_END_LINE - PIPELINE_DELAY);
	assign lineEnding = (hposCount == HORIZ_START_FRONT_PORCH - PIPELINE_DELAY);
	assign hsyncStarting = (hposCount == HORIZ_START_SYNC - PIPELINE_DELAY);
	
	assign hPos = lineActive ? hposCount[9:0] : 10'h0;
	assign vPos = frameActive ? vposCount : 9'h0;
	
	assign nextFrameActive = (nextVposCount < VERT_VISIBLE);
	
	assign nextVPos = nextFrameActive ? nextVposCount : 9'h0;
	
	always @(posedge clk40) begin
		if(hposCount == (HORIZ_TOTAL - 1)) begin
			hposCount <= 0;
			vposCount <= nextVposCount;
			
			if(vposCount == VERT_START_SYNC) begin
				vsync <= VSYNC_POLARITY_IS_POSITIVE;
			end
			
			if(vposCount == VERT_START_BACK_PORCH) begin
				vsync <= ~VSYNC_POLARITY_IS_POSITIVE;
			end
		end else begin
			hposCount <= hposCount + 1;
		end

		if(hposCount == HORIZ_START_FRONT_PORCH) begin
			nextVposCount <= vposCount == VERT_END_LINE ? 0 : vposCount + 1;
		end

		if(hposCount == HORIZ_START_SYNC) begin
			hsync <= HSYNC_POLARITY_IS_POSITIVE;
		end
		
		if(hposCount == HORIZ_START_BACK_PORCH) begin
			hsync <= ~HSYNC_POLARITY_IS_POSITIVE;
		end
	end
endmodule
