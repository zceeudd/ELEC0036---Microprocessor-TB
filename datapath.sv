module datapath(
	input logic clk,
	input logic we3, //rf write-enable signal
	input logic ALUsrc, //ALU input mux select 
	input logic [4:0] ALUcontrol, //ALU control signal (selects ALU operation)
	output logic ALUcout, //ALU carryout 
	input logic we, //datamemory write enable
	input logic [1:0] regdata, //select signal for 4x1 mux (for selecting rf write data value)
	input logic [1:0] regwrite, //select signal for 4x1 mux (for selecting rf write address)
	input logic j, //select signal for 2x1 mux 'PC_J_MUX' (for selecting jump address if we have a j instruction)
	input logic wehilo, //write enable signal for hi and lo registers (single write enable signal shared by both 
	//for now since we assume they are both written to together)
	input logic jr, //jr select signal for selecting the jr mux 
	input logic multdiv, //This is the select signal for the mux's into the hi and lo registers (chooses between loading from
	//mult or from div)
	input logic mod,
	input logic [1:0] branch, //this is the control signal for the branch circuit
	output logic [5:0] opcode //this is the opcode from the instruction, that is to be sent to the control unit (in the DECODE stage 
	);

	//Control signal inputs to this datapath are generated from
	//a controller module	

	///////////////////////////////////////////////////////INTERNAL SIGNALS////////////////////////////////////////////////////////
	wire [15:0] pcinput;
	wire [15:0] Fpcoutput; //PC OUTPUT IN THE FETCH STAGE
	wire [15:0] Dpcoutput; //PC OUTPUT IN THE DECODE STAGE
	wire [17:0] Finstructionmemoryoutput; //this is an Instruction memory output in the FETCH stage
	wire [17:0] Dinstructionmemoryoutput; //this is an Instruction memory output in the DECODE stage
	wire [3:0] Erfwriteaddress; //4-bit register address (rf input) from multiplexer
	wire [15:0] Wrfwritedata; //data to be written to rf (rf input) selected from 16x1 mux, signal is generated in the WRITEBACK stage 
	wire zeroflag;
	wire [15:0] Dsignx_immediate; //sign-extended immediate (from instruction) in the DECODE stage
	wire [15:0] Ealuoutput; //ALU output in the EXECUTE stage
	wire [15:0] Maluoutput; //ALU output in the MEMORY stage
	wire branchsrc; //generated via the branch circuit (i.e.output of branch circuit)
	wire [15:0] F_J_MUX_INPUT; //zero extended address from j instruction, in the DECODE stage 	
	wire [15:0] Ehiregout; //16-bit output of the hi register in the EXECUTE stage
	wire [15:0] Eloregout; //16-bit output of the lo register in the EXECUTE stage
	wire [15:0] Ehiregin; //16-bit input of the hi register (selected from a mux depending on whether we do mult or div) in the EXECUTE stage
	wire [15:0] Eloregin; //16-bit input of the lo register (selected from a mux depending on whether we do mult or div) in the EXECUTE stage
	wire [31:0] Emultout; //32-bit output (result of our multiply circuit) in the EXECUTE stage
	wire [31:0] Edivout; //32-bit output (result of our divide circuit) in the EXECUTE stage
	wire [15:0] Fzerox_immediate; //this is the 16-bit zero extended immediate value from our instruction - in the FETCH stage
	wire [1:0] Dpcinputmuxsel; //this is the select signal for the pc input mux in the DECODE stage
	wire [15:0] Dinstruction_increment; //this is the incremented program counter in the DECODE stage
	wire [3:0] Daddress1; //this is the first address for the RF in the DECODE stage
	wire [3:0] Daddress2; //this is the second address for the RF in the DECODE stage
	wire [3:0] Dimmediate; //this is the immediate from the instruction in the DECODE stage
	wire [11:0] Djumpaddress; //this is the jump address (from jump instructions) in the DECODE stage
	wire [5:0] Dopcode; //this is the opcdoe in the DECODE stage
	wire [15:0] Drfreadoutput1; //this is the output read from the RF (port 1) in the DECODE stage
	wire [15:0] Drfreadoutput2; //this is the output read from the RF (port 2) in the DECODE stage
	wire [15:0] Esignx_immediate; //sign-extended immediate (from instruction) in the EXECUTE stage
	wire [3:0] Eaddress1; //this is the first address for the RF in the EXECUTE stage
	wire [3:0] Eaddress2; //this is the second address for the RF in the EXECUTE stage
	wire [3:0] Eimmediate; //this is the immediate from the instruction in the EXECUTE stage (this would be used for specifying RF write destination 
	//address
	wire [15:0] Erfreadoutput1; //this is the output read from the RF (port 1) in the EXECUTE stage
	wire [15:0] Erfreadoutput2; //this is the output read from the RF (port 2) in the EXECUTE stage
	wire Ewe3; //this is the write enable signal for the RF in the EXECUTE stage 
	wire [1:0] Eregwrite; //this is the select signal for the MUX choosing the RF write address, in the EXECUTE stage
	wire Ealusrc; //this is the select signal for the ALU input mux in the EXECUTE stage 
	wire Emultdiv; //this is the mux select signal for mult/div operation in the EXECUTE stage
	wire Ewehilo; //write enable for the hi and lo registers in the EXECUTE stage
	wire [4:0] Ealucontrol; //ALU control signal in the execute stage
	wire [15:0] E_forwarding_mux_ALU_1; //output of the ALU's first forwarding mux in the EXECUTE stage
	wire [15:0] E_forwarding_mux_ALU_2; //output of the ALU's second forwarding mux in the EXECUTE stage
	wire [15:0] EaluinputA; //Input 'A' of the ALU in the EXECUTE stage
	wire [15:0] EaluinputB; //Input 'A' of the ALU in the EXECUTE stage (comes from the first ALU forwarding mux)
	wire Ewe; //write enable for the data memory in the EXECUTE stage
	wire [1:0] Eregdata; //mux select for choosing data for RF write in the EXECUTE stage
	wire [15:0] Mhiregout; //this is the output of the hi register in the MEMORY stage
	wire [15:0] Mloregout; //this is the output of the lo register in the MEMORY stage
	wire [15:0] Mdmwritedata; //this is the data to be written to DM (if we are doing this) in the MEMORY stage
	wire Mwe; //write enable for the data memory in the MEMORY stage
	wire Mwe3; //write enable for the RF in the MEMORY stage
	wire [3:0] Mrfwriteaddress; //RF write address in the MEMORY stage
	wire [1:0] Mregdata; //mux select for choosing data for RF write in the MEMORY stage
	wire [15:0] Mdmout; //output of DM in the MEMORY stage
	wire [15:0] Wdmout; //output of DM in the WRITEBACK stage
	wire [1:0] Wregdata; //mux select for choosing data for RF write in the WRITEBACK stage
	wire [15:0] Waluoutput; //ALU output in the WRITEBACK stage
	wire [15:0] Whiregout; //this is the output of the hi register in the WRITEBACK stage
	wire [15:0] Wloregout; //this is the output of the lo register in the WRITEBACK stage
	wire [3:0] Wrfwriteaddress; //RF write address in the WRITEBACK stage
	wire Wwe3; //write enable for the RF in the WRITEBACK stage	
	wire [15:0] PCinputmux3; //output of the forwarding mux that goes into the PC input mux option 3
	wire [15:0] Dequalitycomparitorinput1; //input to the equality comparitor (for branch instruction) in the DECODE stage
	wire [15:0] Dequalitycomparitorinput2; //input to the equality comparitor (for branch instruction) in the DECODE stage
	wire equalityflag; //output of equality comparator, which is high if inputs are equal
	wire [2:0] Dforward1; //select for the first forwarding mux for branching (in the decode stage)
	wire [2:0] Dforward2; //select for the second forwarding mux for branching (in the decode stage)
	wire [2:0] Dforward3; //select for forwarding mux for one of the PC input mux inputs (in the decode stage)
	wire [2:0] Eforward1; //select for the first forwarding mux for ALU (in the execute stage)
	wire [2:0] Eforward2; //select for the second forwarding mux for ALU (in the execute stage)
	wire Fstall;
	wire Dstall;
	wire Eflush;
	wire fetch_decode_clear; //signal for clearing the fetch/decode pipeline register
	wire branchcircuitout; //output of the branch circuit in the DECODE stage
	wire [15:0] Fbranchaddress; //address to branch to in branch instruction
	wire Fmuxbranch1; //select for mux that chooses branch address or not in the FETCH stage
	wire brclear; //signal indicating if we need to clear the FETCH/DECODE pipeline register as a result of a branch instruction
	wire [1:0] muxbranch2; //select signal for the final pc mux (basically for selecting the correct address if a branch instruction was incorrectly predicted/not predicted)
	wire [15:0] muxbranch1OUT; //output of the first branching mux
	wire [15:0] PCincrement; //PC value+1
	wire [15:0] Dsignx_immediate_shouldve_branched; //sign extended branch target address from the DECODE stage 
	wire [15:0] Dsignx_immediate_shouldve_branched_plus_pc; //the final address to branch to 
	wire [15:0] muxbranch2OUT; //output of the second branching mux
	wire [7:0] nops; //number of NOPs we have
	wire [15:0] finalpcmuxout; //output of the final mux for jump which goes into the PC
	wire jumpmuxselect; //select signal for the jump mux
	wire [15:0] modout;
	wire [15:0] Mmodout;
	wire [15:0] Wmodout;
	wire [15:0] Wmodmuxout;
	wire Emod;
	wire Mmod;
	wire Wmod;
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	assign opcode = Dopcode;

	logic Dj;
	assign Dj = j;	
	logic Djr;
	assign Djr = jr;

	wire [1:0] workout;
	wire [1:0] chaos;

	logic [3:0] Finstruction_branchaddress; //branch address of our instruction (output of instruction memory) in the FETCH stage
	assign Finstruction_branchaddress = Finstructionmemoryoutput[3:0];

	logic [11:0] Finstructionjumpaddress; //adress to jump to in the FETCH stage
	assign Finstructionjumpaddress = Finstructionmemoryoutput[11:0];
	logic [5:0] Fop; //opcode in the FETCH stage
	assign Fop = Finstructionmemoryoutput[17:12];

	////////////ZERO EXTENDER - J INSTRUCTION ADDRESS//////////////
	//input signal 'a1' into this mux is the zero (because address isnt signed) extended address in the J instruction
	zeroextender_j data_zeroextender_j(
	.nextended(Finstructionjumpaddress),.extended(F_J_MUX_INPUT)
	);
	////////////////////////////////////////////////////////////

	/////////////////////PC INPUT MUX SELECT/////////////////////
	/*THIS IS CAUSING ISSUES WITH ENSURING THE J AND JR ARE PROPERLY
	//SHARED ACROSS DATAPATH, CONTROL UNIT AND PROCESSOR1
	//
	logic [1] jism;
	assign jism = j;
	logic [1] jrism;
	assign jrism = jr;
	PCinputselectmux data_PCinputselectmux(
	.out(pcinputmuxsel),.branch(branchsrc),.j(jism),.jr(jrism)
	);
	//instantiates the circuit which takes the branch, j and jr
	//signals and decides what the input to the PC should be based
	//on these
	/////////////////////////////////////////////////////////////
	*/

	///////////////////////PC INPUT MUX/////////////////////////
	fourTOone_mux2 PCinputmux(
	.a0(PCincrement),.a1(16'b0000000000000000),.a2(16'b0000000000000000),.a3(PCinputmux3),.sel(workout),.out(pcinput)
	);
	//a0 - simply increment pc
	//a1 - branch: increment of pc added to a branch value
	//specified by instruction immediate
	//a2 - j: jump to address specified by the instruction - this
	//value is bits [11:0] of the instruction which are zero extended
	//to generate a 16-bit value for our PC
	//a3 - jr: jump to an address specified in a register 
	////////////////////////////////////////////////////////////
	
	///////////////////////PC + 1 INCREMENTER//////////////////
	adder_pcincrement data_adder_pcincrement(
	.a(Fpcoutput),.s(PCincrement)
	);
	///////////////////////////////////////////////////////////

	/////////////////////////////PC/////////////////////////////
	PC data_PC(
	.clk(clk),.pcnext(finalpcmuxout),.pcout(Fpcoutput),.Fstall(Fstall),
	.muxbranch1(muxbranch1),.Fmuxbranch1(Fmuxbranch1)
	);
	////////////////////////////////////////////////////////////

	/////////////////////INSTRUCTION MEMORY/////////////////////
	instructionmemory data_im(
	.a(Fpcoutput),.rd(Finstructionmemoryoutput)
	);
	////////////////////////////////////////////////////////////

	///////////////////////REGISTER FILE////////////////////////	
	registerfile data_rf(
	.rd1(Drfreadoutput1),.rd2(Drfreadoutput2),.clk(clk),.we3(Wwe3),.ra1(Daddress1),
	.ra2(Daddress2),.wa3(Wrfwriteaddress),.wd3(Wmodmuxout)
	);
	//////////////////////INSTANTIATE ALU///////////////////////
	ALU data_ALU(
	.a(EaluinputA),.b(E_forwarding_mux_ALU_1),.ALUcontrol(Ealucontrol),.y(Ealuoutput),.Cout(ALUcout),.zeroflag(zeroflag)
	);	
	//what we defined as 'b' for the ALU is the output 1 of the rf
	//what we defined as 'a' for the ALU is either output 2 of the rf or the sign-extended immediate
	/////////////////////ALU INPUT MUX//////////////////////////
	//This is the ALU input MUX that selects ALU input 'A' (rf output or sign-extended immediate)
	twoTOone_mux ALUinputselectmux(
	.a0(E_forwarding_mux_ALU_2),.a1(Esignx_immediate),.sel(Ealusrc),.out(EaluinputA)
	);
	////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////

	//////////////////BRANCH ADDER///////////////////////////////////
	//adder for constructing new branch address 
	negadder data_negadder(
	.A(Fzerox_immediate),.B(PCincrement),.S(Fbranchaddress)
	);
	//////////////////////////////////////////////////////////////////

	////////////////////////BRANCH ZERO EXTENDER////////////////
	//LABELLED AS ZERO EXTENDER BUT IN THIS ITERATION IT IS A SIGN EXTENDER, TO ALLOW FOR BACKWARDS BRANCHING
	//zeroextender_immediate data_zeroextender_immediate(
	//.nextended(Dimmediate),.extended(Dzerox_immediate)
	//);
	sign_extension data_zeroextender_immediate(
	.imm(Finstruction_branchaddress),.signimm(Fzerox_immediate)
	);
	////////////////////////////////////////////////////////////

	///////////////////////SIGN-EXTENDER////////////////////////
	//sign_extension data_signx_immediate(
	//.imm(Dimmediate),.signimm(Dsignx_immediate)
	//);
	zeroextender_immediate data_signx_immediate(
	.nextended(Dimmediate),.extended(Dsignx_immediate)
	);
	//LABELLED AS SIGN EXTENDED BUT IS ACTUALLY ZERO EXTENDED
	////////////////////////////////////////////////////////////

	////////////////////////DATA MEMORY/////////////////////////
	datamemory data_datamemory(
	.clk(clk),.we(Mwe),.a(Maluoutput),.wd(Mdmwritedata),.rd(Mdmout)
	);
	//value written to data memory is only ever the second output from the rf
	////////////////////////////////////////////////////////////

	///////////////////4x1 MUX FOR RF WRITE DATA///////////////
	//This MUX selects the value to be written to the register file
	//MUX is selected with regdata control signal
	fourTOone_mux2 data_rfwritedata_mux(
	.a0(Waluoutput),.a1(Wdmout),.a2(Whiregout),.a3(Wloregout),.sel(Wregdata),.out(Wrfwritedata)
	);
	////////////////////////////////////////////////////////////

	/////////////////4x1 MUX FOR RF WRITE ADDRESS///////////////
	//This MUX takes the regwrite signal to determine the RF address to write to
	fourTOone_mux data_rfwriteaddress_mux(
	.a0(Eaddress2),.a1(Eimmediate),.a2(4'b0000),.a3(4'b0000),.sel(Eregwrite),.out(Erfwriteaddress)
	);
	////////////////////////////////////////////////////////////

	/////////HILO REGISTERS (SPECIAL PURPOSE REGISTER)//////////
	twoTOone_mux hiMUX(
	.a0(Emultout[31:16]),.a1(Edivout[31:16]),.sel(Emultdiv),.out(Ehiregin)
	);
	twoTOone_mux loMUX(
	.a0(Emultout[15:0]),.a1(Edivout[15:0]),.sel(Emultdiv),.out(Eloregin)
	);	
	//MAY BE INDEXING PROBLEMS
	/////////////////////////HI/////////////////////////////////
	hiloreg data_hi(
	.rd(Ehiregout),.clk(clk),.wehilo(Ewehilo),.wd(Ehiregin)
	);
	/////////////////////////LO/////////////////////////////////
	hiloreg data_lo(
	.rd(Eloregout),.clk(clk),.wehilo(Ewehilo),.wd(Eloregin)
	);
	////////////////////////////////////////////////////////////

	//////////////////////BRANCH CIRCUIT////////////////////////
	//Branch circuit determines branchsrc
	branchcircuit data_branchcircuit(
	.branch(branch),.zeroflag(equalityflag),.branchcircuitout(branchcircuitout)	
	);
	//branch is a control signal generated from the control unit
	////////////////////////////////////////////////////////////

	//////////////////////MULTIPLIER////////////////////////////
	multiply data_multiply(
	.a(E_forwarding_mux_ALU_1),.b(E_forwarding_mux_ALU_2),.y(Emultout)
	);
	//The multiplication function carried out by the multiply module is coded behaviourally - the structural model for multiplication
	//is complicated
	////////////////////////////////////////////////////////////

	////////////////////////DIVIDE//////////////////////////////
	/////NEED TO DO THIS - TEMPORARILY USING MULTIPLY AGAIN/////
	divide data_divide(
	.a(E_forwarding_mux_ALU_1),.b(E_forwarding_mux_ALU_2),.y(Edivout),.modout(modout)
	);
	////////////////////////////////////////////////////////////

	/////////////////////FETCH/DECODE PIPELINE//////////////////
	//FETCH-DECODE PIPELINE REGISTER (RED)
	pipeline_register_FetchDecode fetch_decode(
	.clk(clk),.reset(fetch_decode_clear),.Dstall(Dstall),.Finstruction(Finstructionmemoryoutput),.Dinstruction(Dinstructionmemoryoutput),.Finstruction_increment(PCincrement),
	.Dinstruction_increment(Dinstruction_increment),.Daddress1(Daddress1),.Daddress2(Daddress2),.Dimmediate(Dimmediate),.Djumpaddress(Djumpaddress),.Dopcode(Dopcode),
	.Fpc(Fpcoutput),.Dpc(Dpcoutput)  
	);
	////////////////////////////////////////////////////////////

	////////////OR GATE TO GENERATE FETCH/DECODE CLEAR//////////
	or_into_fetch_decode_clear or_into_fetch_decode_clear(
	.jr(Djr),.branchout(brclear),.fetch_decode_clear(fetch_decode_clear)
	);
	////////////////////////////////////////////////////////////

	///////////////////DECODE/EXECUTE PIPELINE//////////////////
	//DECODE-EXECUTE PIPELINE REGISTER (BLUE)
	pipeline_register_DecodeExecute decode_execute(
	.clk(clk),.reset(Eflush),.Drd1(Drfreadoutput1),.Drd2(Drfreadoutput2),.Da1(Daddress1),.Da2(Daddress2),.Dsignextimm(Dsignx_immediate),.Da3(Dimmediate),.Dhilowrite(wehilo),.Dmultdiv(multdiv),.Dalucontrol(ALUcontrol),.Dalusrc(ALUsrc),.Dregwrite(regwrite),.Dwe3(we3),.Dwe(we),.Dregdata(regdata),
	.Erd1(Erfreadoutput1),.Erd2(Erfreadoutput2),.Ea1(Eaddress1),.Ea2(Eaddress2),.Esignextimm(Esignx_immediate),.Ea3(Eimmediate),.Ehilowrite(Ewehilo),.Emultdiv(Emultdiv),.Ealucontrol(Ealucontrol),.Ealusrc(Ealusrc),.Eregwrite(Eregwrite),.Ewe3(Ewe3),.Ewe(Ewe),.Eregdata(Eregdata),.Dmod(mod),.Emod(Emod)
	);
	////////////////////////////////////////////////////////////

	//////////////////EXECUTE/MEMORY PIPELINE///////////////////
	//EXECUTE-MEMORY PIPELINE REGISTER (GREEN)
	pipeline_register_ExecuteMemory execute_memory(
	.clk(clk),.Ehi(Ehiregout),.Elo(Eloregout),.Ealu(Ealuoutput),.Edmwrite(E_forwarding_mux_ALU_2),.Ewe3(Ewe3),.Ewe(Ewe),.Eregdata(Eregdata),.Ewriteadd(Erfwriteaddress),
	.Mhi(Mhiregout),.Mlo(Mloregout),.Malu(Maluoutput),.Mdmwrite(Mdmwritedata),.Mwe3(Mwe3),.Mwe(Mwe),.Mregdata(Mregdata),.Mwriteadd(Mrfwriteaddress),.Emodout(modout),.Mmodout(Mmodout),.Emod(Emod),.Mmod(Mmod)
	);
	////////////////////////////////////////////////////////////

	/////////////////MEMORY/WRITEBACK PIPELINE//////////////////
	//MEMORY-WRITEBACK PIPELINE REGISTER (YELLOW)
	pipeline_register_MemoryWriteback memory_writeback(	
	.clk(clk),.Mhi(Mhiregout),.Mlo(Mloregout),.Malu(Maluoutput),.Mdmout(Mdmout),.Mwriteadd(Mrfwriteaddress),.Mregdata(Mregdata),.Mwe3(Mwe3),
	.Whi(Whiregout),.Wlo(Wloregout),.Walu(Waluoutput),.Wdmout(Wdmout),.Wwriteadd(Wrfwriteaddress),.Wregdata(Wregdata),.Wwe3(Wwe3),.Mmodout(Mmodout),.Wmodout(Wmodout),.Mmod(Mmod),.Wmod(Wmod)
	);
	////////////////////////////////////////////////////////////

	//////////////////ALU FORWARDING MUX////////////////////////
	//these are the forwarding muxs for the input to the ALU	
	eightTOone_mux forwarding_mux_ALU_1(
	.sel(Eforward1),.out(E_forwarding_mux_ALU_1),.a0(Erfreadoutput1),.a1(Wmodmuxout),.a2(Maluoutput),.a3(Mhiregout),.a4(Mloregout),.a5(Mmodout),.a6(16'b0000000000000000),.a7(16'b0000000000000000)
	);
	eightTOone_mux forwarding_mux_ALU_2(
	.sel(Eforward2),.out(E_forwarding_mux_ALU_2),.a0(Erfreadoutput2),.a1(Wmodmuxout),.a2(Maluoutput),.a3(Mhiregout),.a4(Mloregout),.a5(Mmodout),.a6(16'b0000000000000000),.a7(16'b0000000000000000)
	);
	////////////////////////////////////////////////////////////

	//////////////////DECODE FORWARDING MUX////////////////////////
	//this is the forwarding mux that sits in the DECODE stage, used at the PC input MUX
	//twoTOone_mux_PC_input forwarding_mux_PC_input_DECODE(
	//.a0(Drfreadoutput1),.a1(Maluoutput),.sel(Dforward3),.out(PCinputmux3)
	//);
	eightTOone_mux forwarding_mux_PC_input_DECODE(
	.a0(Drfreadoutput1),.a1(Maluoutput),.a2(Mhiregout),.a3(Mloregout),.a4(Mmodout),.a5(16'b0000000000000000),.a6(16'b0000000000000000),.a7(16'b0000000000000000),.sel(Dforward3),.out(PCinputmux3)
	);
	///////////////////////////////////////////////////////////////

	//////////////////BRANCH FORWARDING MUX////////////////////////
	//these are the forwarding mux that sits in the DECODE stage, used for BRANCHING
	//forwarding_mux forwarding_mux_branch1(
	//.a0(Drfreadoutput1),.a1(Maluoutput),.sel(Dforward1),.out(Dequalitycomparitorinput1)
	//);
	//forwarding_mux forwarding_mux_branch2(
	//.a0(Drfreadoutput2),.a1(Maluoutput),.sel(Dforward2),.out(Dequalitycomparitorinput2)
	//);
	eightTOone_mux forwarding_mux_branch1(
	.a0(Drfreadoutput1),.a1(Maluoutput),.a2(Mhiregout),.a3(Mloregout),.a4(Mmodout),.a5(16'b0000000000000000),.a6(16'b0000000000000000),.a7(16'b0000000000000000),.sel(Dforward1),.out(Dequalitycomparitorinput1)
	);
	eightTOone_mux forwarding_mux_branch2(
	.a0(Drfreadoutput2),.a1(Maluoutput),.a2(Mhiregout),.a3(Mloregout),.a4(Mmodout),.a5(16'b0000000000000000),.a6(16'b0000000000000000),.a7(16'b0000000000000000),.sel(Dforward2),.out(Dequalitycomparitorinput2)
	);
	///////////////////////////////////////////////////////////////

	//////////////////EQUALITY COMPARATOR//////////////////////////
	//Equality comparator for the branch operation
	equality equality_comparator(
	.input1(Dequalitycomparitorinput1),.input2(Dequalitycomparitorinput2),.flag(equalityflag)
	);
	///////////////////////////////////////////////////////////////

	//////////////////////PC INPUT MUX SELECT//////////////////////
	//this is the circuit that takes the jump control signal, jump register control signal and
	//branch signal (generated from the branch circuit) and then determines the select signal
	//for the mux going into the PC
	//PCinputmuxselect PCinputmuxselect(
	//.br(1'b0),.j(1'b0),.jr(1'b0),.pcinputmuxselect(Dpcinputmuxsel)
	//);
	///////////////////////////////////////////////////////////////

	////////////////////PC INPUT SELECT MUX////////////////////////
	//PCinputselectmux PCinputselectmux(
	//.j(1'b0),.jr(1'b0),.branch(1'b0),.out(Dpcinputmuxsel)
	//);
	//////////////////////////////////////////////////////////////

	////////////////////////HAZARD DETECTION UNIT//////////////////
	hazard_detection_unit hazard_detection_unit(
	.Daddress1(Daddress1),.Daddress2(Daddress2),.Eaddress1(Eaddress1),.Eaddress2(Eaddress2),.Erfwriteaddress(Erfwriteaddress),.Mrfwriteaddress(Mrfwriteaddress),.Wrfwriteaddress(Wrfwriteaddress),.Ewe3(Ewe3),.Mwe3(Mwe3),.Wwe3(Wwe3),.Eregdata(Eregdata),.Mregdata(Mregdata),.Dbranch(branch),
	.Dforward1(Dforward1),.Dforward2(Dforward2),.Dforward3(Dforward3),.Eforward1(Eforward1),.Eforward2(Eforward2),.Fstall(Fstall),.Dstall(Dstall),.Eflush(Eflush), .Dj(j),.Djr(jr),.Mmod(Mmod)
	);
	///////////////////////////////////////////////////////////////

	////JUST WORK///
	justwork data_justwork(
	.jr(Djr),.justworkout(workout)
	);
	///////////////

	/////////////////////TWO BIT SATURATING COUNTER//////////////////
	//this is the 2-bit branch predictor
	two_bit_saturating_counter data_two_bit_branch_predictor(
	.Fpc(Fpcoutput),.clk(clk),.Finstruction(Finstructionmemoryoutput),.Dbranchcircuitout(branchcircuitout),.Dpc(Dpcoutput),.muxbranch1(muxbranch1),.Dbranch(branch),.Dstall(Dstall)
	);
	/////////////////////////////////////////////////////////////////

	////////////////////////////BRANCH ANALYSER//////////////////////
	//this effectively decides whether we need to clear our FETCH/DECODE pipeline or set the correct address (if one of our branch predictions was wrong)
	branch_analyser data_branch_analyser(
	.Dbranchcircuitout(branchcircuitout),.Fmuxbranch1(Fmuxbranch1),.muxbranch2(muxbranch2),.brclear(brclear),.Dbranch(branch)
	);
	/////////////////////////////////////////////////////////////////

	////////////////////////BRANCH MUX 1/////////////////////////////
	//first branch mux - basically chooses between either sticking with jump/jr/next instruction or branching
	twoTOone_mux data_branchmux1(
	.a0(pcinput),.a1(Fbranchaddress),.sel(muxbranch1),.out(muxbranch1OUT)
	);
	//////////////////////////////////////////////////////////////////

	////////////////////////BRANCH MUX 2//////////////////////////////
	//second branch mux - for feeding PC with the correct address if a branch was incorrectly taken/missed
	fourTOone_mux2 data_branchmux2(
	.a0(muxbranch1OUT),.a1(Dinstruction_increment),.a2(Dsignx_immediate_shouldve_branched_plus_pc),.a3(16'b0000000000000000),.sel(muxbranch2),.out(muxbranch2OUT)
	);
	//////////////////////////////////////////////////////////////////

	///////////////////////SIGN-EXTENDER////////////////////////
	//sign extender for a branch address in the decode stage (i.e. we haven't branched when we should have)
	sign_extension data_signx_immediate2(
	.imm(Dimmediate),.signimm(Dsignx_immediate_shouldve_branched)
	);
	////////////////////////////////////////////////////////////

	///////////////////////BRANCH MUX 2 ADDER/////////////////////////
	//our adder for computing one of the inputs to branch mux2
	negadder data_negadder2(
	.A(Dsignx_immediate_shouldve_branched),.B(Dinstruction_increment),.S(Dsignx_immediate_shouldve_branched_plus_pc)
	);
	///////////////////////////////////////////////////////////////////

	///////////////////////COUNTER/////////////////////////////////////
	//THIS COUNTER IS SIMPLY FOR COUNTING HOW MANY BRANCH PREDICTIONS ARE WRONG (BY LOOKING AT THE SELECT SIGNAL FOR 
	//MUX BRANCH 2) AND THEREFORE TELLING US HOW MANY NOPs WE HAVE
	counter data_counter(
	.clk(clk),.enable(muxbranch2),.count(nops)
	);
	///////////////////////////////////////////////////////////////////

	//////////////////////PC JUMP MUX/////////////////////////////////
	twoTOone_mux jump_2to1mux(
	.a0(muxbranch2OUT),.a1(F_J_MUX_INPUT),.sel(jumpmuxselect),.out(finalpcmuxout)
	);
	//////////////////////////////////////////////////////////////////
	
	/////////////////////MOD MUX////////////////////////////////
	//mux for selecting whether to write modulus to RF
	twoTOone_mux data_modmux(
	.a0(Wrfwritedata),.a1(Wmodout),.sel(Wmod),.out(Wmodmuxout)
	);
	/////////////////////////////////////////////////////////////

	/////////////////////////////JUMP DECIDER//////////////////////////
	jumpdecider data_jumpdecider(
	.opcode(Fop),.jumpmux(jumpmuxselect)
	);
	////////////////////////////////////////////////////////////////////

	
endmodule