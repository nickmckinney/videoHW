module backgroundControlPipeline (
	input clk,
	input [3:0] panOffset,
	input lineStarting,
	
	output charAddrOut,
	output charDataIn,
	output palAddrOut,
	output palDataIn,
	output tileLowAddrOut,
	output tileHighAddrOut,
	output tileLowDataIn,
	output tileHighDataIn,
	output pixelOut
);

	reg [11:0] cycle;
	reg [6:0] tileCount;
	reg live;
	
	always @(posedge clk) begin
		if(lineStarting) begin
			live <= 1;
			cycle <= 12'b1;
			tileCount <= 7'b0;
		end else begin
			cycle <= live ? {cycle[10:0], cycle[11]} : 12'b0;  // barrel shift
			
			if(cycle[11]) tileCount <= tileCount + 1;
			if(tileCount == (|panOffset ? 7'd41 : 7'd40)) live <= 0;  // should be 41 and 40
		end
	end
	
	assign charAddrOut = live & cycle[0];
	assign charDataIn = live & cycle[1];
	assign palAddrOut = live & cycle[2];
	assign palDataIn = live & cycle[3];
	assign tileLowAddrOut = live & cycle[2];
	assign tileLowDataIn = live & cycle[3];
	assign tileHighAddrOut = live & cycle[4];
	assign tileHighDataIn = live & cycle[5];
	assign pixelOut = live & (|cycle[11:4]);
	
endmodule
