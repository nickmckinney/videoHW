module backgroundControl (
	input clk,
	input lineStarting,
	input [2:0] layer0Pan,
	input [2:0] layer1Pan,
	input [2:0] layer2Pan,
	input [2:0] layer3Pan,

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

	backgroundControlPipeline layer1 (
		.clk(clk),
		.panOffset(layer1Pan),
		.lineStarting(startQueue[1:0] == 2'h1),
	
		.charAddrOut(charAddrOut[1]),
		.charDataIn(charDataIn[1]),
		.palAddrOut(palAddrOut[1]),
		.palDataIn(palDataIn[1]),
		.tileLowAddrOut(tileLowAddrOut[1]),
		.tileHighAddrOut(tileHighAddrOut[1]),
		.tileLowDataIn(tileLowDataIn[1]),
		.tileHighDataIn(tileHighDataIn[1]),
		.pixelOut(pixelOut[1])
	);

	backgroundControlPipeline layer2 (
		.clk(clk),
		.panOffset(layer2Pan),
		.lineStarting(startQueue[1:0] == 2'h2),
	
		.charAddrOut(charAddrOut[2]),
		.charDataIn(charDataIn[2]),
		.palAddrOut(palAddrOut[2]),
		.palDataIn(palDataIn[2]),
		.tileLowAddrOut(tileLowAddrOut[2]),
		.tileHighAddrOut(tileHighAddrOut[2]),
		.tileLowDataIn(tileLowDataIn[2]),
		.tileHighDataIn(tileHighDataIn[2]),
		.pixelOut(pixelOut[2])
	);
	
	backgroundControlPipeline layer3 (
		.clk(clk),
		.panOffset(layer3Pan),
		.lineStarting(startQueue[1:0] == 2'h3),
	
		.charAddrOut(charAddrOut[3]),
		.charDataIn(charDataIn[3]),
		.palAddrOut(palAddrOut[3]),
		.palDataIn(palDataIn[3]),
		.tileLowAddrOut(tileLowAddrOut[3]),
		.tileHighAddrOut(tileHighAddrOut[3]),
		.tileLowDataIn(tileLowDataIn[3]),
		.tileHighDataIn(tileHighDataIn[3]),
		.pixelOut(pixelOut[3])
	);
	
endmodule