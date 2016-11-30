`timescale 1ns / 1ps
`include	"interface.svh"
`include	"sequencer.svh"
`include	"scorebord.svh"

program	enviroment	(	usart_interface usart_if,	dut_interface	dut_if,		inout_interface	inout_if);

sequencer sq;			//	Sequencer	
scoreboard sb;			//  Scorebord

initial begin : start
	sq	=	new(usart_if, dut_if, inout_if);
	sb  =  	new(usart_if, dut_if, inout_if);

	//	Execute test
	$display("--------------------------------------------------------------------");
	$display("[%d][INFO] Simulation Enviroment Initialised", $time());

	#1000;
	sq.tc_randseq();
	
end : start

final begin: finish
	//	End of simulation
	$display("--------------------------------------------------------------------");
	$display("[%d][INFO] Simulation Enviroment Finished", $time());
	sb.report_final_status();
end : finish


endprogram: enviroment