module test2(

	//////////// CLOCK //////////
	input  CLOCK_25,
	output LED
);


assign LED = ledReg[24];

reg [24:0] ledReg;
always @(posedge CLOCK_25) begin
	ledReg <= ledReg + 1;	
end

endmodule
