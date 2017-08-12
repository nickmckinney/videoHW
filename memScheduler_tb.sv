module memScheduler_tb();

	memInternal upstream();
	memInternal ports [3:0]();
	logic clk;
	logic rst_n;
	
	memScheduler dut(
		.clk(clk),
		.rst_n(rst_n),
		.client(ports),
		.upstream(upstream)
	);
	
	fakeRam dutRam (
		.clk(clk),
		.rst_n(rst_n),
		.upstream(upstream)
	);
	
	initial begin
		clk = 0;
	end
	
	always #5 clk = ~clk;
	
	initial begin
		ports[0].readReq = 1'b0;
		ports[0].addr = 16'h0;
		ports[1].readReq = 1'b0;
		ports[1].addr = 16'h0;
		ports[2].readReq = 1'b0;
		ports[2].addr = 16'h0;
		ports[3].readReq = 1'b0;
		ports[3].addr = 16'h0;
		
		#2 rst_n = 1'b0;
		#13 rst_n = 1'b1;
		
		// let's try a request!
		#10 ports[0].addr = 16'h1234;
		ports[0].readReq = 1'b1;
		
		#10 ports[0].readReq = 1'b0;
		
		while(ports[0].busy) #10;
		
		// let's try two requests at the same time!
		#10 ports[0].addr = 16'ha222;
		ports[1].addr = 16'ha333;
		ports[0].readReq = 1'b1;
		ports[1].readReq = 1'b1;
		
		#10 ports[0].readReq = 1'b0;
		ports[1].readReq = 1'b0;
		
		
		#100 $stop;
	end
	
	initial begin
		upstream.busy = 1'b0;
		#95 upstream.busy = 1'b1;
		#30 upstream.busy = 1'b0;
	end
	
	initial begin
		#25 ;
		for(int x = 0; x < 10; x++) begin
			while(ports[2].busy) #10;
			ports[2].addr = 16'ha222;
			ports[2].readReq = 1'b1;
			#10 ports[2].readReq = 1'b0;
		end
	end
	
endmodule

module fakeRam(
	input logic clk,
	input logic rst_n,
	memInternal.supplier upstream
);

	logic [15:0] delayedData;
	logic delayedDataReady;

	always_ff @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			upstream.data <= 16'h0;
			upstream.dataReady <= 1'b0;
			delayedData <= 16'h0;
			delayedDataReady <= 1'b0;
		end else begin
			if (upstream.readReq && !upstream.busy) begin
				delayedDataReady <= 1'b1;
				case (upstream.addr)
					16'h1234: delayedData <= 16'hbeef;
					16'ha222: delayedData <= 16'hd222;
					16'ha333: delayedData <= 16'hd333;
					default: delayedData <= 16'hFFFF;
				endcase
			end else begin
				delayedData <= 16'h0000;
				delayedDataReady <= 1'b0;
			end
			
			upstream.data <= delayedData;
			upstream.dataReady <= delayedDataReady;
		end
	end
endmodule
