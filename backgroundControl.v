module backgroundControl (
	input clk,
	input lineStarting,
	input [4:0] layer0Pan,
	input [4:0] layer1Pan,
	input [4:0] layer2Pan,
	input [4:0] layer3Pan,

	output [3:0] charAddrOut,
	output [3:0] charDataIn,
	output [3:0] palAddrOut,
	output [3:0] palDataIn,
	output [3:0] tileLowAddrOut,
	output [3:0] tileHighAddrOut,
	output [3:0] tileLowDataIn,
	output [3:0] tileHighDataIn,
	output [3:0] pixelOut
);

	reg [13:0] startQueue;
	
	initial begin
		startQueue <= 7'b0;
	end

	always @(posedge clk) begin
		if(lineStarting) startQueue <= 14'b11_10_00_00_00_00_01;
		else startQueue <= {2'b00, startQueue[13:2]};
	end
	
	backgroundControlPipeline layer0 (
		.clk(clk),
		.panOffset(layer0Pan),
		.lineStarting(lineStarting),
	
		.charAddrOut(charAddrOut[0]),
		.charDataIn(charDataIn[0]),
		.palAddrOut(palAddrOut[0]),
		.palDataIn(palDataIn[0]),
		.tileLowAddrOut(tileLowAddrOut[0]),
		.tileHighAddrOut(tileHighAddrOut[0]),
		.tileLowDataIn(tileLowDataIn[0]),
		.tileHighDataIn(tileHighDataIn[0]),
		.pixelOut(pixelOut[0])
	);
	
	assign charAddrOut[3:1] = 0;
	assign charDataIn[3:1] = 0;
	assign palAddrOut[3:1] = 0;
	assign palDataIn[3:1] = 0;
	assign tileLowAddrOut[3:1] = 0;
	assign tileHighAddrOut[3:1] = 0;
	assign tileLowDataIn[3:1] = 0;
	assign tileHighDataIn[3:1] = 0;
	assign pixelOut[3:1] = 0;
	
endmodule