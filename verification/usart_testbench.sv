`timescale 1ns / 1ps
`include	"interface.svh"

`define	SYSTEM_CLOCK_PERIOD	 10;
`define	OUTSIDE_CLOCK_PERID	 160;

module	usart_testbench;

	bit clk;
	bit	clk_i;
	bit	rst;

	usart_interface	usart_if();
	inout_interface	inout_if();
	dut_interface	dut_if(clk,rst);
	enviroment		env(usart_if, dut_if, inout_if);
	dut_top			dut(usart_if, dut_if, inout_if);

	initial	begin
		rst = 0;
		#40 rst = 1;
		forever	begin
		 	#`SYSTEM_CLOCK_PERIOD	clk = ~clk;
		end
	end

endmodule:	usart_testbench


