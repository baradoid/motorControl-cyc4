module motorCtrlSimple_v2(
	input CLK,
	input reset,
	input [14:0] divider,
	//input moveDir,
	//input moveDirInvers,
	//input stepClockEna,	
	input [11:0] stepsToGo,
	input dirInput,
	output reg dir = 0,
	output step,
	//output reg signed [18:0] cur_position = 0,
	output reg activeMode = 0
);

reg [14:0] clockCounter = 0;
reg [14:0] dividerLoc= 0;
reg [11:0] stepsCnt = 0;

reg stepInt = 0;
assign step = stepInt; //& state[1];
reg [7:0] delayCounter = 0;
reg [1:0] state = 2'b00;
always @(posedge CLK) begin
	
	case(state)
	2'b00: begin
		activeMode <= 0;		
		stepsCnt <= stepsToGo[11:0];	
		dividerLoc <= divider;
		dir <= dirInput;
		delayCounter <= 8'hff;
	
		if(stepsToGo[11:0] != 0) begin
			
			if(dir != dirInput) begin
				state <= 2'b01;	
			end
			else if(dir == dirInput) begin
				state <= 2'b11;
			end
		end

	end
	2'b01: begin			
		if(delayCounter == 0) begin
			state <= 2'b11;		
		end
		else begin			
			delayCounter <= delayCounter - 1;
		end
	end
	2'b11: begin		
		activeMode <= 1;	
		if((stepsCnt==12'h0)&&(clockCounter==15'h0)) begin
			state <= 2'b00;	
		end
		else begin		
			if(clockCounter == 0) begin
				stepInt <= 1;	
				clockCounter <= dividerLoc;	
				stepsCnt <= stepsCnt - 12'h1;
			end
			else begin
				clockCounter <= clockCounter - 15'h1;						
				if(clockCounter == {1'b0, dividerLoc[14:1]})
					stepInt <= 0;	
			end
		end
	end
	endcase



end
endmodule


