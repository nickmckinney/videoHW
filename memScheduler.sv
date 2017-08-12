// usage:
//  - reset line, which latches in supplied scan line, pan offset, scroll offset
//  - pixel out enable, which starts the machine
//    - 

// possible memory scheduling: rotation
// threads A, B, C, D
// priority always goes to the thread after the currently accessing thread
// so for example, if A has the bus now and A, C, and D are requesting, bus goes to C

// combinatorial module that calculates the next bus owner given the current bus owner and who is requesting it

// TODO: seems to work now. there's probably opportunities to make it not wait as long in some cases.

interface memInternal;
	logic [15:0] addr;
	logic readReq;
	logic readNext;
	logic busy;
	logic dataReady;
	logic [15:0] data;
	modport consumer(output addr, readReq, input busy, dataReady, data);
	modport internalConsumer(output addr, readReq, input readNext, dataReady, data);
	modport supplier(input addr, readReq, output busy, dataReady, data);
	modport internalSupplier(input addr, readReq, output readNext, dataReady, data);
endinterface

// each port may only have one request outstanding
// requests are ignored if that port's busy signal is asserted
// if this turns out to be too limiting, a short queue can be added to each port
module memScheduler #(PORTCOUNT = 4) (
	input logic clk,
	input logic rst_n,
	memInternal.supplier client[PORTCOUNT - 1:0],
	memInternal.consumer upstream
);

	//logic [15:0] inProgressAddr [PORTCOUNT-1:0];
	//logic [PORTCOUNT-1:0] inProgress;
	logic [PORTCOUNT-1:0] requestOwnerBuffer [7:0];  // circular buffer holding the port the response should go back to
	logic [2:0] reqOwnBufHead;
	logic [2:0] reqOwnBufTail;
	logic [PORTCOUNT-1:0] allClientReadReq;
	memInternal sched [PORTCOUNT-1:0]();
	genvar prt;
	
	generate
		for(prt = 0; prt < PORTCOUNT; prt++) begin:genMemSchedPort
			memSchedPort schedPort (
				.clk(clk),
				.rst_n(rst_n),
				.client(client[prt]),
				.scheduler(sched[prt].internalConsumer)
			);
		end:genMemSchedPort
	endgenerate
	
	//########################
	logic [PORTCOUNT-1:0] nextReq;
	
	generate
		for(prt = 0; prt < PORTCOUNT; prt++) begin:portAssign
			always_comb begin
					allClientReadReq[prt] = sched[prt].readReq;
					sched[prt].readNext = nextReq[prt] & !upstream.busy;
			end
		end:portAssign
	endgenerate
	
	memSchedNextReqReg #(.PORTCOUNT(PORTCOUNT)) nextReq_inst (
		.clk(clk),
		.rst_n(rst_n),
		.en(!upstream.busy),
		.requests(allClientReadReq),
		.current(nextReq)
	);
	
	//#######################
	logic [15:0] nextAddress;
	logic [15:0] portAddress [PORTCOUNT-1:0];
	
	
	generate
		for(prt = 0; prt < PORTCOUNT; prt++) begin:portAssignx
			assign portAddress[prt] = sched[prt].addr;
		end:portAssignx
	endgenerate
	
	always_comb begin
		nextAddress = 16'h0;
		
		for(int i = 0; i < PORTCOUNT; i++) begin
			if(nextReq == (1 << i)) begin
				nextAddress = portAddress[i];
			end
		end
	end
	
	//#######################
	// next, get nextAddress and the requesting port onto the circular buffer,
	// send them along to upstream, and tell the port that we started its request
	// (but only do these things if upstream is not busy)
	logic [2:0] reqOwnBufNextHead;

	assign reqOwnBufNextHead = (reqOwnBufHead + 1);
	
	always_ff @(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			reqOwnBufHead <= 0;
			upstream.addr <= 16'h0;
			upstream.readReq <= 1'b0;
		end else begin
			if(|nextReq && !upstream.busy) begin
				requestOwnerBuffer[reqOwnBufHead] <= nextReq;
				reqOwnBufHead <= reqOwnBufNextHead;
				upstream.addr <= nextAddress;
				upstream.readReq <= 1'b1;
			end else begin
				upstream.readReq <= 1'b0;
			end
		end
	end
	
	//#######################
	// the port at the tail of the circular buffer should have upstream's dataReady
	// and data sent to it. if dataReady is asserted, on the next clock the tail pointer
	// should advance
	logic [PORTCOUNT-1:0] allDataReady;
	
	generate
		for(prt = 0; prt < PORTCOUNT; prt++) begin:dataReadyGen
			assign sched[prt].dataReady = allDataReady[prt];
			assign sched[prt].data = upstream.data;
		end:dataReadyGen
	endgenerate
	
	assign allDataReady = requestOwnerBuffer[reqOwnBufTail] & {PORTCOUNT{upstream.dataReady}};
	
	always_ff @(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			reqOwnBufTail <= 0;
		end else begin
			if(upstream.dataReady) begin
				reqOwnBufTail <= reqOwnBufTail + 1;
			end
		end
	end
endmodule

module memSchedPort (
	input logic clk,
	input logic rst_n,
	memInternal.supplier client,
	memInternal.internalConsumer scheduler
);

	logic [1:0] state;
	// state 0: waiting for request
	// state 1: request received, waiting for scheduler to pick it up
	// state 2: scheduler picked up request, waiting for data
	//          once data is ready, goes directly to state 0 or 1 depending on
	//          whether a request is immediately ready or not
	//          (dataReady and data are non-registered and come through directly
	//          from scheduler)
	logic [15:0] requestedAddr;
	logic internalReadReq;
	
	// this signal needs to go low as soon as possible after readNext is asserted
	assign scheduler.readReq = internalReadReq & ~scheduler.readNext;
	
	always_ff @(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			state <= 2'h0;
			client.busy <= 1'b0;
			internalReadReq <= 1'b0;
			client.dataReady <= 1'b0;
			client.data <= 16'h0;
		end else begin
			unique case(state)
				2'h0:
					begin
						client.dataReady <= 1'b0;  // in case state 2 was most recent state
						client.data <= 16'h0;
						
						if (client.readReq) begin
							state <= 2'h1;
							scheduler.addr <= client.addr;
							internalReadReq <= 1'b1;
							client.busy <= 1'b1;
						end
					end

				2'h1:
					begin
						client.dataReady <= 1'b0;  // in case state 2 was most recent state
						client.data <= 16'h0;
						
						if (scheduler.readNext) begin
							state <= 2'h2;
							internalReadReq <= 1'b0;
						end
					end
					
				2'h2:
					begin
						client.dataReady <= scheduler.dataReady;
						if (scheduler.dataReady) begin
							client.data <= scheduler.data;
							
							if (client.readReq) begin
								state <= 2'h1;
								scheduler.addr <= client.addr;
								internalReadReq <= 1'b1;
							end else begin
								state <= 2'h0;
								client.busy <= 1'b0;
							end
						end
					end
			endcase
		end
	end
endmodule

module memSchedNextReqReg #(PORTCOUNT = 4) (
	input logic clk,
	input logic rst_n,
	input logic en,
	input logic [PORTCOUNT-1:0] requests,
	output logic [PORTCOUNT-1:0] current
);

	logic [7:0] nextReq;
	
	memSchedNextReq scheduler (
		.current({{(8-PORTCOUNT){1'b0}},current}),
		.requests({{(8-PORTCOUNT){1'b0}},requests}),
		.next(nextReq)
	);
	
	always_ff @(posedge clk or negedge rst_n) begin
		if (!rst_n) current <= 0;
		else if (en) current <= nextReq[PORTCOUNT-1:0];
	end
endmodule

module memSchedNextReq (
	input logic [7:0] current,
	input logic [7:0] requests,
	output logic [7:0] next
);

	logic [7:0] nextTable [7:0];
	
	assign nextTable[7] = {
		requests[7] && ~|requests[6:0],

		requests[6],
		requests[5] && ~|requests[6:6],
		requests[4] && ~|requests[6:5],
		requests[3] && ~|requests[6:4],
		requests[2] && ~|requests[6:3],
		requests[1] && ~|requests[6:2],
		requests[0] && ~|requests[6:1]
		};

	assign nextTable[6] = {
		requests[7] && ~|requests[5:0],
		requests[6] && ~|{requests[5:0],requests[7:7]},

		requests[5],
		requests[4] && ~|requests[5:5],
		requests[3] && ~|requests[5:4],
		requests[2] && ~|requests[5:3],
		requests[1] && ~|requests[5:2],
		requests[0] && ~|requests[5:1]
		};

	assign nextTable[5] = {
		requests[7] && ~|requests[4:0],
		requests[6] && ~|{requests[4:0],requests[7:7]},
		requests[5] && ~|{requests[4:0],requests[7:6]},

		requests[4],
		requests[3] && ~|requests[4:4],
		requests[2] && ~|requests[4:3],
		requests[1] && ~|requests[4:2],
		requests[0] && ~|requests[4:1]
		};

	assign nextTable[4] = {
		requests[7] && ~|requests[3:0],
		requests[6] && ~|{requests[3:0],requests[7:7]},
		requests[5] && ~|{requests[3:0],requests[7:6]},
		requests[4] && ~|{requests[3:0],requests[7:5]},

		requests[3],
		requests[2] && ~|requests[3:3],
		requests[1] && ~|requests[3:2],
		requests[0] && ~|requests[3:1]
		};

	assign nextTable[3] = {
		requests[7] && ~|requests[2:0],
		requests[6] && ~|{requests[2:0],requests[7:7]},
		requests[5] && ~|{requests[2:0],requests[7:6]},
		requests[4] && ~|{requests[2:0],requests[7:5]},
		requests[3] && ~|{requests[2:0],requests[7:4]},

		requests[2],
		requests[1] && ~|requests[2:2],
		requests[0] && ~|requests[2:1]
		};

	assign nextTable[2] = {
		requests[7] && ~|requests[1:0],
		requests[6] && ~|{requests[1:0],requests[7:7]},
		requests[5] && ~|{requests[1:0],requests[7:6]},
		requests[4] && ~|{requests[1:0],requests[7:5]},
		requests[3] && ~|{requests[1:0],requests[7:4]},
		requests[2] && ~|{requests[1:0],requests[7:3]},

		requests[1],
		requests[0] && ~|requests[1:1]
		};

	assign nextTable[1] = {
		requests[7] && ~|requests[0:0],
		requests[6] && ~|{requests[0:0],requests[7:7]},
		requests[5] && ~|{requests[0:0],requests[7:6]},
		requests[4] && ~|{requests[0:0],requests[7:5]},
		requests[3] && ~|{requests[0:0],requests[7:4]},
		requests[2] && ~|{requests[0:0],requests[7:3]},
		requests[1] && ~|{requests[0:0],requests[7:2]},

		requests[0]
		};

	assign nextTable[0] = {
		requests[7],
		requests[6] && ~|requests[7:7],
		requests[5] && ~|requests[7:6],
		requests[4] && ~|requests[7:5],
		requests[3] && ~|requests[7:4],
		requests[2] && ~|requests[7:3],
		requests[1] && ~|requests[7:2],
		requests[0] && ~|requests[7:1]
		};

	always_comb begin
		unique case (current)
			8'b10000000: next = nextTable[7];
			8'b01000000: next = nextTable[6];
			8'b00100000: next = nextTable[5];
			8'b00010000: next = nextTable[4];
			8'b00001000: next = nextTable[3];
			8'b00000100: next = nextTable[2];
			8'b00000010: next = nextTable[1];
			8'b00000001: next = nextTable[0];
			8'b00000000: next = nextTable[0];
		endcase
	end
endmodule
