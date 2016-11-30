`ifndef	___DUT_INTERFACE___
`define	___DUT_INTERFACE___

interface dut_interface (
	input 	clk,
	input	rst);
endinterface:	dut_interface
`endif	//	___DUT_INTERFACE___

`ifndef	___INOUT_INTERFACE___
`define	___INOUT_INTERFACE___

interface 	inout_interface();
	logic	clk_i;
	logic	rxd;
	logic	clk_o;
	logic	txd;

	//	Driver port
	modport drprt(
		output	clk_i,
		output	rxd,
		input	clk_o,
		output	txd
	);	

	//	Monnitor port
	modport monprt(
		input	clk_i,
		input	rxd,
		input	clk_o,
		input	txd
	);
endinterface:	inout_interface
`endif	//	INOUT_INTERFACE

`ifndef	___USART_INTERFACE___
`define	___USART_INTERFACE___

interface usart_interface();
	logic	[7:0]	addr;
	logic	[7:0]	word_i;
	logic	we;
	logic	DDR_XCl;
	logic	[7:0]	word_o;

	//	Driver port
	modport	drprt(
		output	addr,
		output	word_i,
		output	we,
		output	DDR_XCl,
		input	word_o
	);

	//	Monitor Port
	modport	monprt(
		output 	addr,
		output	word_i,
		output	we,
		output	DDR_XCl,
		output	word_o
	);
endinterface:	usart_interface
`endif	//___USART_INTERFACE___