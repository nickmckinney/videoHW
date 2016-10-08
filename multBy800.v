// multiply by 800
// 800x = 768x + 32x
// 800x = 3*256x + 32x
// 800x = 3*(x << 8) + (x << 5)

module multBy800 (
	input [9:0] inNum,
	output [19:0] outNum
);

	wire [17:0] firstFactor = inNum << 8;
	
	assign outNum = firstFactor + firstFactor + firstFactor + (inNum << 5);

endmodule
