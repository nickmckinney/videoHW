module memSchedNextReq_tb();

	logic [7:0] current;
	logic [7:0] requests;
	logic [7:0] next;
	
	memSchedNextReq dut (
		.current(current),
		.requests(requests),
		.next(next)
	);
	
	initial begin
		current = 8'h0;
		requests = 8'hC5;
		
		while (requests != 0) begin
			#2 requests = requests & ~next;
			current = next;
		end
		
		#5 $stop;
	end

endmodule
