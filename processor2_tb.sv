module processor2_tb();

	logic clk;

	processor2 processor2TEST(
	.clk(clk)
	);

	initial begin
	clk = 0;
	processor2TEST.processor2_datapath.data_counter.counter = 8'b00000000;
	processor2TEST.processor2_datapath.data_PC.pc=16'b0000000000000000;
	processor2TEST.processor2_datapath.data_two_bit_branch_predictor.counters[0] = 16'b0000000000000000;
	processor2TEST.processor2_datapath.data_two_bit_branch_predictor.counters[1] = 16'b0000000000000000;
	processor2TEST.processor2_datapath.data_two_bit_branch_predictor.counters[2] = 16'b0000000000000000;
	processor2TEST.processor2_datapath.data_two_bit_branch_predictor.counters[3] = 16'b0000000000000000;
	processor2TEST.processor2_datapath.data_two_bit_branch_predictor.counters[4] = 16'b0000000000000000;
	processor2TEST.processor2_datapath.data_two_bit_branch_predictor.counters[5] = 16'b0000000000000000;
	processor2TEST.processor2_datapath.data_two_bit_branch_predictor.counters[6] = 16'b0000000000000000;
	processor2TEST.processor2_datapath.data_two_bit_branch_predictor.counters[7] = 16'b0000000000000000;
	processor2TEST.processor2_datapath.data_two_bit_branch_predictor.counters[8] = 16'b0000000000000000;
	processor2TEST.processor2_datapath.data_two_bit_branch_predictor.counters[9] = 16'b0000000000000000;
	processor2TEST.processor2_datapath.data_two_bit_branch_predictor.counters[10] = 16'b0000000000000000;
	processor2TEST.processor2_datapath.data_two_bit_branch_predictor.counters[11] = 16'b0000000000000000;
	processor2TEST.processor2_datapath.data_two_bit_branch_predictor.counters[12] = 16'b0000000000000000;
	processor2TEST.processor2_datapath.data_two_bit_branch_predictor.counters[13] = 16'b0000000000000000;
	processor2TEST.processor2_datapath.data_two_bit_branch_predictor.counters[14] = 16'b0000000000000000;
	processor2TEST.processor2_datapath.data_two_bit_branch_predictor.counters[15] = 16'b0000000000000000;
	processor2TEST.processor2_datapath.data_two_bit_branch_predictor.counters[16] = 16'b0000000000000000;
	processor2TEST.processor2_datapath.data_two_bit_branch_predictor.counters[17] = 16'b0000000000000000;
	processor2TEST.processor2_datapath.data_two_bit_branch_predictor.counters[18] = 16'b0000000000000000;
	processor2TEST.processor2_datapath.data_two_bit_branch_predictor.counters[19] = 16'b0000000000000000;
	processor2TEST.processor2_datapath.data_two_bit_branch_predictor.counters[20] = 16'b0000000000000000;
	processor2TEST.processor2_datapath.data_two_bit_branch_predictor.counters[21] = 16'b0000000000000000;
	processor2TEST.processor2_datapath.data_two_bit_branch_predictor.counters[22] = 16'b0000000000000000;
	processor2TEST.processor2_datapath.data_two_bit_branch_predictor.counters[23] = 16'b0000000000000000;
	processor2TEST.processor2_datapath.data_two_bit_branch_predictor.counters[24] = 16'b0000000000000000;
	processor2TEST.processor2_datapath.data_two_bit_branch_predictor.counters[25] = 16'b0000000000000000;
	processor2TEST.processor2_datapath.data_two_bit_branch_predictor.counters[26] = 16'b0000000000000000;
	processor2TEST.processor2_datapath.data_two_bit_branch_predictor.counters[27] = 16'b0000000000000000;
	$readmemh("cheeky.dat",processor2TEST.processor2_datapath.data_im.SRAM);
	forever #10ps clk = ~clk;
	end

endmodule
	
