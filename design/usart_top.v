`timescale 1ns / 1ps
`ifndef	___USART_TOP___
`define	___USART_TOP___

module usart_top(	i_fosk,
					i_rst_n,
					i_clk,
					i_rxd,
					i_addr,
					i_word,
					i_we,
					i_DDR_XCL,
					o_word,
					o_clk,
					o_txd
				);

input			i_fosk;
input			i_rst_n;
input			i_clk;
input			i_rxd;
input	[7:0]	i_addr;
input	[7:0]	i_word;
input			i_we;
input			i_DDR_XCL;

output	[7:0]	o_word;
output			o_clk;
output			o_txd;

////////////////////////////////////////////////////////////////////////////////////
//				Variables
////////////////////////////////////////////////////////////////////////////////////
//	inputs of register-module
wire 			udre;
wire			dor;
wire	[7:0]	udr_rc;
wire	 		rx8;
wire 			fe;
wire			pe;
wire 			rxc;
wire			txc;
//	outputs of register - module
wire 	[11:0]	ubrr;
wire			ucpol;
wire			u2x;
wire			we_ubrrh;
wire			we_ubrrl;
wire			txen;
wire	[2:0]	ucsz;
wire			usbs;
wire	[1:0]	upm;
wire			we_udr_tr;
wire	[7:0]	udr_tr;
wire			tx8;
wire			rxen;
wire			we_udr_rc;
wire			mpcm;
//	clock for transmitter and receiver
wire 			txclk;
wire			rxclk;

////////////////////////////////////////////////////////////////////////////////////
//				Registers
////////////////////////////////////////////////////////////////////////////////////
registers	registers_inst1(	.i_fosk(i_fosk),											
								.i_rst_n(i_rst_n),										
								.i_addr(i_addr),
								.i_word(i_word),
								.i_we(i_we),
								.i_udre(udre),
								.i_dor(dor),
								.i_udr_rc(udr_rc),
								.i_rx8(rx8),
								.i_fe(fe),
								.i_pe(pe),
								.i_rxc(rxc),
								.i_txc(txc),
								.o_word(o_word),
								.o_ubrr(ubrr),
								.o_ucpol(ucpol),
								.o_u2x(u2x),
								.o_umsel(umsel),
								.o_we_ubrrh(we_ubrrh),
								.o_we_ubrrl(we_ubrrl),
								.o_txen(txen),
								.o_ucsz(ucsz),
								.o_usbs(usbs),
								.o_upm(upm),
								.o_we_udr_tr(we_udr_tr),
								.o_udr_tr(udr_tr),
								.o_tx8(tx8),
								.o_rxen(rxen),
								.o_we_udr_rc(we_udr_rc),
								.o_mpcm(mpcm)
								);

////////////////////////////////////////////////////////////////////////////////////
//				Clock generator
////////////////////////////////////////////////////////////////////////////////////
clock_generator clock_generator_inst1 (	.i_fosk(i_fosk),	
										.i_rst_n(i_rst_n),		
										.i_clk(i_clk),
										.i_UBRR(ubrr),
										.i_UCPOL(ucpol),
										.i_U2X(u2x),
										.i_DDR_XCK(i_DDR_XCL),
										.i_UMSEL(umsel),
										.i_we_ubrrh(we_ubrrh),
										.i_we_ubrrl(we_ubrrl),
										.i_data(i_word),
										.o_txclk(txclk),
										.o_rxclk(rxclk),
										.o_clk(o_clk)
									);

////////////////////////////////////////////////////////////////////////////////////
//				Transmitter
////////////////////////////////////////////////////////////////////////////////////
transmitter transmitter_inst1(	.i_fosk(i_fosk),
								.i_rst_n(i_rst_n),
								.i_TXEN(txen),
								.i_txclk(txclk),
								.i_ucsz(ucsz),
								.i_usbs(usbs),
								.i_upm(upm),
								.i_we_udr_tr(we_udr_tr),
								.i_udr(udr_tr),
								.i_tx8(tx8),
								.o_TxD(o_txd),
								.o_udre(udre),
								.o_txc(txc)
								);

////////////////////////////////////////////////////////////////////////////////////
//				Receiver
////////////////////////////////////////////////////////////////////////////////////
receiver receiver_inst1(			.i_fosk(i_fosk),
									.i_rst_n(i_rst_n),
									.i_RXEN(rxen),
									.i_RxD(i_rxd),
									.i_rxclk(rxclk),
									.i_ucsz(ucsz),
									.i_upm(upm),
									.i_umsel(umsel),
									.i_u2x(u2x),
									.i_w_addr(we_udr_rc),
									.i_mpcm(mpcm),
									.o_dor(dor),
									.o_udr(udr_rc),
									.o_RX8(rx8),
									.o_FE(fe),
									.o_PE(pe),
									.o_RXC(rxc)
									);

endmodule

`endif	//	___USART_TOP___