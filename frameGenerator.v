module frameGenerator (
	input clk40,
	output reg hsync,
	output reg vsync,
	output videoActive,
	output [9:0] hPos,
	output [9:0] vPos,
	output nextFrameActive,
	output [9:0] nextVPos
);

	localparam HORIZ_VISIBLE = 11'd800;
	localparam HORIZ_FRONT_PORCH = 11'd40;
	localparam HORIZ_SYNC = 11'd128;
	localparam HORIZ_BACK_PORCH = 11'd88;
	localparam HORIZ_TOTAL = (HORIZ_VISIBLE + HORIZ_FRONT_PORCH + HORIZ_SYNC + HORIZ_BACK_PORCH);
	localparam HORIZ_START_FRONT_PORCH = HORIZ_VISIBLE - 1;
	localparam HORIZ_START_SYNC = HORIZ_START_FRONT_PORCH + HORIZ_FRONT_PORCH;
	localparam HORIZ_START_BACK_PORCH = HORIZ_START_SYNC + HORIZ_SYNC;
	localparam HORIZ_END_LINE = HORIZ_TOTAL - 1;
	
	localparam VERT_VISIBLE = 10'd600;
	localparam VERT_FRONT_PORCH = 10'd1;
	localparam VERT_SYNC = 10'd4;
	localparam VERT_BACK_PORCH = 10'd23;
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
		hsync <= 0;
		vsync <= 0;
	end
	
	assign lineActive = (hposCount < HORIZ_VISIBLE);
	assign frameActive = (vposCount < VERT_VISIBLE);
	assign videoActive = lineActive & frameActive;
	
	assign hPos = lineActive ? hposCount[9:0] : 10'h0;
	assign vPos = frameActive ? vposCount : 9'h0;
	
	assign nextFrameActive = (nextVposCount < VERT_VISIBLE);
	
	assign nextVPos = nextFrameActive ? nextVposCount : 9'h0;
	
	always @(posedge clk40) begin
		if(hposCount == (HORIZ_TOTAL - 1)) begin
			hposCount <= 0;
			vposCount <= nextVposCount;
			
			if(vposCount == VERT_START_SYNC) begin
				vsync <= 1;
			end
			
			if(vposCount == VERT_START_BACK_PORCH) begin
				vsync <= 0;
			end
		end else begin
			hposCount <= hposCount + 1;
		end

		if(hposCount == HORIZ_START_SYNC) begin
			hsync <= 1;
			nextVposCount <= vposCount == VERT_END_LINE ? 0 : vposCount + 1;
		end
		
		if(hposCount == HORIZ_START_BACK_PORCH) begin
			hsync <= 0;
		end
	end
endmodule
