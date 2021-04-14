//this design unit analyses the outcomes of our branch circuit to effectively determine
//whether a branch was correctly or incorrectly taken or not taken

module branch_analyser(
	input logic Dbranchcircuitout,
	input logic Fmuxbranch1,
	input logic [1:0] Dbranch,
	output logic [1:0] muxbranch2,
	output logic brclear
	);

	//assign brclear = Fmuxbranch1 ? (Dbranchcircuitout ? 1'b0 : 1'b1) : (Dbranchcircuitout ? 1'b1 : 1'b0);
	//assign muxbranch2 = Fmuxbranch1 ? (Dbranchcircuitout ? 2'b00 : 2'b10) : (Dbranchcircuitout ? 2'b01 : 2'b00); 
	
	always_comb begin
		if (Fmuxbranch1==1'b1 && Dbranchcircuitout==1'b0 && (Dbranch==2'b00 || Dbranch==2'b01)) begin
			assign brclear = 1'b1;
			assign muxbranch2 = 2'b01;
		end
		else if (Fmuxbranch1==1'b0 && Dbranchcircuitout==1'b1 && (Dbranch==2'b00 || Dbranch==2'b01)) begin
			assign brclear = 1'b1;
			assign muxbranch2 = 2'b10;
		end
		else begin
			assign brclear = 1'b0;
			assign muxbranch2 = 2'b00;
		end
	end

endmodule