module adder_pcincrement(
	output logic [15:0] s,
 	input logic [15:0] a
	);

	assign s = a + 16'b0000000000000001;

endmodule