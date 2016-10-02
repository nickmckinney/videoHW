module frameGenerator (
	input clk40,
	output reg hsync,
	output reg vsync,
	output videoActive,
	output [9:0] hPos,
	output [9:0] vPos
);

	reg [10:0] hposCount;
	reg [9:0] vposCount;
	wire frameActive;
	wire lineActive;
	
	initial begin
		hposCount <= 0;
		vposCount <= 0;
		hsync <= 0;
		vsync <= 0;
	end
	
	assign lineActive = (hposCount < 11'd800);
	assign frameActive = (vposCount < 10'd600);
	assign videoActive = lineActive && frameActive;
	
	assign hPos = lineActive ? hposCount[9:0] : 10'h0;
	assign vPos = frameActive ? vposCount : 9'h0;
	
	always @(posedge clk40) begin
		if(hposCount == 11'd1055) begin
			hposCount <= 0;
			if(vposCount == 10'd627) begin
				vposCount <= 0;
			end else begin
				vposCount <= vposCount + 1;
			end
			
			if(vposCount == 10'd600) begin
				vsync <= 1;
			end
			
			if(vposCount == 10'd604) begin
				vsync <= 0;
			end
		end else begin
			hposCount <= hposCount + 1;
		end

		if(hposCount == 11'd839) begin
			hsync <= 1;
		end
		
		if(hposCount == 11'd967) begin
			hsync <= 0;
		end
	end
endmodule
