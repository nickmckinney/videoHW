module backgroundControl_tb ();

	reg clk, lineStarting;
	wire [3:0] charAddrOut;
	wire [3:0] charDataIn;
	wire [3:0] palAddrOut;
	wire [3:0] palDataIn;
	wire [3:0] tileLowAddrOut;
	wire [3:0] tileHighAddrOut;
	wire [3:0] tileLowDataIn;
	wire [3:0] tileHighDataIn;
	wire [3:0] pixelOut;
	
	initial begin
		clk = 0;
		lineStarting = 0;
		
		#4
		lineStarting = 1;
		
		#2
		lineStarting = 0;
		
		#50
		$stop;
	end
	
	always #1 clk = !clk;
	
	backgroundControl testSubject (
		.clk(clk),
		.lineStarting(lineStarting),
		.layer0Pan(4'h0),
		.layer1Pan(4'h0),
		.layer2Pan(4'h0),
		.layer3Pan(4'h0),

		.charAddrOut(charAddrOut),
		.charDataIn(charDataIn),
		.palAddrOut(palAddrOut),
		.palDataIn(palDataIn),
		.tileLowAddrOut(tileLowAddrOut),
		.tileHighAddrOut(tileHighAddrOut),
		.tileLowDataIn(tileLowDataIn),
		.tileHighDataIn(tileHighDataIn),
		.pixelOut(pixelOut)
	);

endmodule
