`timescale 1ns / 1ps
`ifndef		___DUT_TOP___
`define		___DUT_TOP___

`include	"interface.svh"


module dut_top(	
	usart_interface usart_if,
	dut_interface	dut_if,
	inout_interface	inout_if
);
	
usart_top dut(	
	.i_fosk		(dut_if.clk),
	.i_rst_n	(dut_if.rst),
	.i_clk		(inout_if.clk_i),
	.i_rxd		(inout_if.rxd),
	.o_clk		(inout_if.clk_o),
	.o_txd		(inout_if.txd),
	.i_addr		(usart_if.addr),
	.i_word		(usart_if.word_i),
	.i_we		(usart_if.we),
	.i_DDR_XCL	(usart_if.DDR_XCl),
	.o_word		(usart_if.word_o)
);

endmodule:dut_top

`endif	//	___DUT_TOP___