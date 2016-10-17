module alphaBlend (
	input clk,
	input [15:0] composited,
	input [15:0] toAdd,
	output reg [15:0] out
);

// each channel: out = prev + alpha * (curr - prev)
// where prev, alpha, and curr are all 5-bit fixed-point numbers where the MSB is a sign bit and the other 4 are the original integer numbers

	wire [4:0] prevRed;
	wire [4:0] prevGreen;
	wire [4:0] prevBlue;
	wire [4:0] newRed;
	wire [4:0] newGreen;
	wire [4:0] newBlue;
	wire [4:0] alpha;
	
	assign prevRed = {1'b0, composited[3:0]};
	assign prevGreen = {1'b0, composited[7:4]};
	assign prevBlue = {1'b0, composited[11:8]};

	assign newRed = {1'b0, toAdd[3:0]};
	assign newGreen = {1'b0, toAdd[7:4]};
	assign newBlue = {1'b0, toAdd[11:8]};
	assign alpha = {1'b0, toAdd[15:12]};

	wire [9:0] blendedRed;
	wire [9:0] blendedGreen;
	wire [9:0] blendedBlue;
	assign blendedRed = alpha * (newRed - prevRed);
	assign blendedGreen = alpha * (newGreen - prevGreen);
	assign blendedBlue = alpha * (newBlue - prevBlue);
	
	wire [4:0] outRed;
	wire [4:0] outGreen;
	wire [4:0] outBlue;
	
	assign outRed = prevRed + blendedRed[8:4];
	assign outGreen = prevGreen + blendedGreen[8:4];
	assign outBlue = prevBlue + blendedBlue[8:4];
	
	always @(posedge clk) begin
		out <= {4'b1111, outBlue[3:0], outGreen[3:0], outRed[3:0]};
	end
endmodule
