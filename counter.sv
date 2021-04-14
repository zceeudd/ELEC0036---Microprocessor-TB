
module counter(
	input logic clk,
	input logic [1:0] enable,
	output logic [7:0] count
	);

	reg [7:0] counter;

	always_ff@(posedge clk) begin
		if(enable==2'b01 || enable==2'b10) begin	
			counter <= counter+8'b00000001;	
		end
	
		else begin
			counter <= counter;
		end
	end

	assign count = counter;


endmodule