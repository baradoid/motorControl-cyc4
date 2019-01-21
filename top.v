module top(

	//////////// CLOCK //////////
	input  CLOCK_25,
	output LED,

	// Motor 
output [9:0] step,
output [9:0] dir,
input [9:0] term,

input 	UART_RX,
output 	UART_TX,
output DebugPin1 = 0,
output reg DebugPin2 = 0,
output reg DebugPin3 = 0,
output DebugPin_85,
output DebugPin5,
output DebugPin6,
output DebugPin7,
output DebugPin8,
output DebugPin9,
output debugPin106,
output DebugPin_86,
output DebugPin_87
);


assign LED = ledReg[24];

reg [24:0] ledReg;
always @(posedge CLOCK_25) begin
	ledReg <= ledReg + 1;	
end


wire rst;

//reg [32:0] counter = 0; 
//always @(posedge CLK_SE_AR) begin
//	USER_LED0 <= counter[24];
//	counter <= counter + 1;
//end

reg [9:0] posReset = 0;
//reg [9:0] fifoWrReq=0;
//wire [31:0] fifoDataOut[9:0];
wire [9:0] fifoEmpty;

wire [9:0] mrCtrlActive;
reg [9:0] mrCtrlActiveR;

reg [15:0] divider[9:0];
reg [15:0] stepCounter[9:0];
reg dirReg[9:0];

reg [9:0] dataPending = 0;


assign DebugPin_87 = step[0];
assign DebugPin_86 = dir[0];
assign DebugPin5 = mrCtrlActive[0];
assign DebugPin6 = dataPending[0];
genvar i;
generate
for(i = 0; i < 10; i = i + 1 ) begin : motorControlBlock

motorCtrlSimple_v2 mr(.CLK(CLOCK_25), 
							 .reset(posReset[i]),
							 .divider(divider[i][15:0]), 
							 .stepsToGo(stepCounter[i][15:0]), 
							 .dirInput(dirReg[i]),
							 .dir(dir[i]), 
							 .step(step[i]), 
							 .activeMode(mrCtrlActive[i]));
end
endgenerate

reg [31:0] timerCounter; always @(posedge CLOCK_25) timerCounter <= timerCounter + 31'h1;

wire uartRxDataReady;
wire [7:0] uartRxData;
reg uartRxDataReadyL=1'b0; always @(posedge CLOCK_25) uartRxDataReadyL <= uartRxDataReady;
wire uartRxDataReadyPE = ((uartRxDataReady==1'b1)&&(uartRxDataReadyL==1'b0));
wire uartRxDataReadyNE = ((uartRxDataReady==1'b0)&&(uartRxDataReadyL==1'b1));

reg uartRxDataReadyPEregDebug; always @(posedge CLOCK_25) uartRxDataReadyPEregDebug <= ((uartRxDataReady==1'b1)&&(uartRxDataReadyL==1'b0));

assign DebugPin1 = uartRxDataReadyPE;
//assign DebugPin3 = uartRxDataReadyPE;
assign DebugPin7 = uartRxDataReady;
//wire RxD_endofpacket_wire, RxD_idle_wire;
//assign DebugPin8 = RxD_endofpacket_wire;
//assign DebugPin9 = RxD_idle_wire;

async_receiver #(.ClkFrequency(25000000), .Baud(115200)) RX(.clk(CLOCK_25),
													 								//.BitTick(uartTick1),
																					.RxD(UART_RX), 
																					.RxD_data_ready(uartRxDataReady), 
																					.RxD_data(uartRxData)/*,
																					.RxD_endofpacket(RxD_endofpacket_wire),
																					.RxD_idle(RxD_idle_wire)*/);



assign DebugPin_87 = step[0];
assign DebugPin_86 = dir[0];
assign DebugPin5 = mrCtrlActive[0];
assign DebugPin6 = dataPending[0];
	
reg [3:0] uartRecvState = 0;	
reg [3:0] curMrCtrl = 0;
reg [47:0] uartCmd;
reg [17:0] uartTimeOutCounter = 18'h0;

wire sendDriveStatus = uartRxDataReady && (uartRecvState==0) && (uartRxData[3:0] == 4'hF);
assign debugPin106 = sendDriveStatus;
integer c;
always @(posedge CLOCK_25) begin
	if(uartRxDataReadyPE) begin
		if(uartRecvState == 0) begin
			if(uartRxData[3:0] == 4'hF) begin				
				uartRecvState <= 0;					
			end
			else begin
				curMrCtrl <= uartRxData[3:0];
				uartRecvState <= uartRecvState + 4'h1;
			end		
		end
		else begin
			uartRecvState <= uartRecvState + 4'h1;		
			
			//uartCmdRecvData[curMrCtrl] <= {uartRxData[7:0], uartCmdRecvData[curMrCtrl][31:8]};			
			//DebugPin1 <= 1'b1;				
		end
		uartCmd[47:0] <= {uartRxData[7:0], uartCmd[47:8]}; 		
	end	
	else begin		
		if(uartTimeOutCounter == 18'h0) begin
			uartRecvState <= 4'h0;	
			DebugPin3 <= 1;
		end
		else begin
			DebugPin3 <= 0;
		end
	end
	
	
	if(uartRxDataReadyPE) begin
		uartTimeOutCounter <= 18'h3ffff;		 
	end
	else if(uartTimeOutCounter>0) begin
		uartTimeOutCounter <= uartTimeOutCounter - 18'h1;		
	end
	
	DebugPin2 <=  uartRxDataReadyNE && (uartRecvState == 5);
	if(uartRxDataReadyNE) begin	
		if(uartRecvState == 6) begin
			uartRecvState <= 0;		
			//fifoWrReq[curMrCtrl] <= 1'b1;
			//uartCmd <= {uartRxData[7:0], uartCmdRecvData[curMrCtrl][31:8]};
			//uartCmdRecvData[curMrCtrl] <= uartCmd;
			if(dataPending[curMrCtrl] == 0) begin
				divider[curMrCtrl] <= uartCmd[31:16];
				stepCounter[curMrCtrl] <= uartCmd[47:32];		
				dirReg[curMrCtrl] <= uartCmd[15];
				dataPending[curMrCtrl] <= 1;
				
				//divider[9] <= 15'hff;
				//stepCounter[9] <= 14'h6;
			end
			//DebugPin2 <= 1'b1;						
		end		
	end
	else begin	
		//fifoWrReq <= 10'h0;
		//DebugPin1 <= 1'b0;			
		mrCtrlActiveR <= mrCtrlActive;		
		for ( c = 0; c < 10; c = c + 1) begin: lbl        
			if({mrCtrlActive[c], mrCtrlActiveR[c]}==2'b10) begin
				dataPending[c] <= 0;
				stepCounter[c] <= 0;
			end	
		end		
	end
	

end




reg [17:0] sendDelay;
wire uartBusy; reg uartBusyR; 

reg [2:0] uartSendState = 3'b111;
//reg uartSendPartNum = 0;
reg uartStartSignal = 0;
reg [7:0] uartTxData;
assign DebugPin8 = uartStartSignal;
//wire uart19200StartSignal = (timerCounter[12:0] == 13'h1FFF);
async_transmitter #(.ClkFrequency(25000000), .Baud(115200)) TX(.clk(CLOCK_25),
																					//.BitTick(uartTick1),
																					.TxD(UART_TX), 
																					.TxD_start(uartStartSignal), 
																					.TxD_data(uartTxData),
																					.TxD_busy(uartBusy));
																					
parameter delay_between_bytes=18'hfff;
parameter delay_between_packs=18'h3ffff;

always @(posedge CLOCK_25) begin
	case(uartSendState)
		3'b000:  begin
			if(sendDriveStatus == 1) begin
			//if(dataPending[9:0] != 10'h3ff) begin				
				uartTxData[7:0] <= {2'h0, 1'b0, dataPending[4:0]};
				//uartTxData[7:0] <= {uartSendPartNum, 3'h0, uartSendPartNum+4'h1};
				//uartSendPartNum <= uartSendPartNum + 1'h1;				
				uartStartSignal <= 1;				
				sendDelay <= delay_between_bytes;	
				uartSendState <= 3'b001;			
			end		
			else begin
				uartStartSignal <= 0;
			end
		end
		3'b001: begin
			uartStartSignal <= 0;			
			if(sendDelay == 0) begin
				uartSendState <= 3'b010;
			end
			else begin
				sendDelay <= sendDelay - 18'h1;
			end			
		end		
		3'b010: begin			
			uartTxData[7:0] <= {2'h1, 1'b0, dataPending[9:5]};
			uartStartSignal <= 1;									
			sendDelay <= delay_between_bytes;
			uartSendState <= 3'b011;
		end
		3'b011: begin
			uartStartSignal <= 0;					
			if(sendDelay == 0) begin
				uartSendState <= 3'b100;
			end
			else begin
				sendDelay <= sendDelay - 18'h1;
			end	
		end				
		
		
		3'b100: begin
			uartTxData[7:0] <= {2'h2, 1'b0, ~term[4:0]};
			//uartTxData[7:0] <= {uartSendPartNum, 3'h0, uartSendPartNum+4'h1};
			//uartSendPartNum <= uartSendPartNum + 1'h1;				
			uartStartSignal <= 1;				
			sendDelay <= delay_between_bytes;
			uartSendState <= 3'b101;	
		end	
		3'b101: begin
			uartStartSignal <= 0;			
			if(sendDelay == 0) begin
				uartSendState <= 3'b110;
			end
			else begin
				sendDelay <= sendDelay - 18'h1;
			end	
		end	
		3'b110: begin
			uartTxData[7:0] <= {2'h3, 1'b0, ~term[9:5]};
			uartStartSignal <= 1;									
			sendDelay <= delay_between_packs;
			uartSendState <= 3'b111;
		end	
		3'b111: begin
			uartStartSignal <= 0;					
			//if(sendDriveStatus == 1) begin
				uartSendState <= 3'b000;
			//end
		end	
		
		default: begin
			uartStartSignal <= 0;		
		end

	endcase	
end
																					
endmodule
