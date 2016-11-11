module backgroundControlPipeline (
	input clk,
	input [2:0] panOffset,
	input lineStarting,
	
	output charAddrOut,
	output charDataIn,
	output palAddrOut,
	output palDataIn,
	output tileLowAddrOut,
	output tileHighAddrOut,
	output tileLowDataIn,
	output tileHighDataIn,
	output pixelOut,
	output pixelMask
);

	reg [11:0] cycle;
	reg [6:0] tileCount;
	reg [7:0] panMaskReg;  // register this for safety; shouldn't be changed in midline
	reg live;
	
	wire [7:0] panMask;
	wire [7:0] currentPanMask;
	
	assign panMask =	panOffset == 3'h1 ? 8'b11111110 :
							panOffset == 3'h2 ? 8'b11111100 :
							panOffset == 3'h3 ? 8'b11111000 :
							panOffset == 3'h4 ? 8'b11110000 :
							panOffset == 3'h5 ? 8'b11100000 :
							panOffset == 3'h6 ? 8'b11000000 :
							panOffset == 3'h7 ? 8'b10000000 : 8'hFF;

	wire isFirstTile, isExtraTile, isStopTile;
	assign isStopTile = tileCount == (|panOffset ? 7'd41 : 7'd40);
	assign isExtraTile = tileCount == 7'd40;
	assign isFirstTile = tileCount == 7'd0;
	assign currentPanMask = isFirstTile ? panMaskReg :
									isExtraTile ? ~panMaskReg :
									8'hFF;

	always @(posedge clk) begin
		if(lineStarting) begin
			live <= 1;
			cycle <= 12'b1;
			tileCount <= 7'b0;
			panMaskReg <= panMask;
		end else begin
			cycle <= live ? {cycle[10:0], cycle[11]} : 12'b0;  // barrel shift
			
			if(cycle[11]) tileCount <= tileCount + 1;
			if(isStopTile) live <= 0;  // should be 41 and 40
		end
	end
	
	assign charAddrOut = live & cycle[0];
	assign charDataIn = live & cycle[1];
	assign palAddrOut = live & cycle[1];
	assign palDataIn = live & cycle[3];
	assign tileLowAddrOut = live & cycle[2];
	assign tileLowDataIn = live & cycle[3];
	assign tileHighAddrOut = live & cycle[4];
	assign tileHighDataIn = live & cycle[5];
	assign pixelOut = live & (|cycle[11:4]);
	assign pixelMask = live & (|(cycle[11:4] & currentPanMask));
	
endmodule
