// ---------------------------------------------------------------------------
//
// Description:
//  <Description text here, indented multiple lines allowed>
//
// File:        $Source: /var/cvsmucontrol/users/tgu/Tools/merlin2/DigitalFlow/Templates/verilog.v.tpl,v $
// Created:     Wed Jul 13 14:57:49 EEST 2016
//      by:     smy
// Updated:     $Date: 2011/08/09 12:38:38 $
//              $Author: tgu $
// Revision:    $Revision: 1.1 $
//
// Copyright (c) Melexis Digital Competence Center
//
// ---------------------------------------------------------------------------
`timescale 1ns/1ps
module receiver(		i_fosk,
						i_rst_n,
						i_RXEN,
						i_RxD,
						i_rxclk,
						i_ucsz,
						i_upm,
						i_umsel,
						i_u2x,
						i_w_addr,
						i_mpcm,
						o_dor,
						o_udr,
						o_RX8,
						o_FE,
						o_PE,
						o_RXC
						);
	
input 			i_fosk;						//	system clock
input 			i_rst_n;					//	reset
input 			i_RXEN;						//  RXEN 
input			i_RxD;						//	data from outside
input 			i_rxclk;					//  receiver clock enable
input [2:0]		i_ucsz;						//	data size bits UCSZ[2:0]
input [1:0]		i_upm;						//	parity bits disabled/enabled  even/odd
input 			i_umsel;					//	USART Mode Select	0 - Asynchronous Operation, 1 - Synchronous Operation
input			i_u2x;						//	UCSRA Bit 1 – U2X: Double the USART transmission speed
input			i_w_addr;					//	data were read from udr
input			i_mpcm;						//  MPCM bit

output 	reg		o_dor;						//  data overrun flag
output 	[7:0]	o_udr;						//	udr
output			o_RX8;						//	RXB8: Receive Data Bit 8
output			o_FE;						//	frame error
output			o_PE;						//	parity Error
output 			o_RXC;						//	USART Receive Complete
////////////////////////////////////////////////////////////////////////////////////
//				Variables
////////////////////////////////////////////////////////////////////////////////////
//Design
wire		det_start;						//	start bit detection 
wire		next_state;						//	time for the next state FSM/ Enable next state
wire[3:0]	state_count;					//	state counter for fsm
wire		empty;							//  empty flag for shift register
wire		fsm_empty_rst;					//  FSM write new data into shift register
wire		fsm_start;						//  receive start bit
wire		fsm_parity;						//  receive parity bit
wire		fsm_stop;						//	receive stop bit
wire		fsm_data;						//  receive data bit
wire		shr_empty_set;					//  FIFO take data from shift register
wire [10:0]	shr_data;						// 	shift register 
wire		mpcm_addr;						//	address bit in multiprocessor mode
//Output
wire		dor;							//	data overrun
wire		dor_disable;					//  if data overrun, wait for the next start bit
wire        sh_reg_i_r;						// 	reset enable for input_shift_register after stop bit
////////////////////////////////////////////////////////////////////////////////////
//				Design
////////////////////////////////////////////////////////////////////////////////////
FSM_receiver FSM_receiver_inst1(	.i_fosk(i_fosk),
									.i_rst_n(i_rst_n),
									.i_RXEN(i_RXEN),
									.i_rxclk(i_rxclk),
									.i_ucsz(i_ucsz),
									.i_upm1(i_upm[1]),
									.i_umsel(i_umsel),
									.i_det_start(det_start),
									.i_next_state(next_state),
									.i_state_count(state_count),	
									.i_empty(empty),
									.o_fsm_empty_rst(fsm_empty_rst),
									.o_fsm_start(fsm_start),
									.o_fsm_parity(fsm_parity),
									.o_fsm_stop(fsm_stop),
									.o_fsm_data(fsm_data),
									.o_dor(dor),
									.o_sh_reg_i_r(sh_reg_i_r),
									.o_dor_disable(dor_disable)
								);

data_path_receiver data_path_receiver_inst1(	.i_fosk(i_fosk),
												.i_rst_n(i_rst_n),
												.i_RxD(i_RxD),
												.i_rxclk(i_rxclk),
												.i_umsel(i_umsel),
												.i_upm0(i_upm[0]),
												.i_u2x(i_u2x),
												.i_ucsz(i_ucsz),
												.i_shr_empty_set(shr_empty_set),
												.i_fsm_empty_rst(fsm_empty_rst),
												.i_fsm_start(fsm_start),
												.i_fsm_parity(fsm_parity),
												.i_fsm_stop(fsm_stop),
												.i_fsm_data(fsm_data),
												.i_dor_disable(dor_disable),
												.i_sh_reg_i_r(sh_reg_i_r),
												.o_mpcm_addr(mpcm_addr),
												.o_det_start(det_start),
												.o_next_state(next_state),
												.o_state_count(state_count),
												.o_empty(empty),
												.o_shr_data(shr_data)
												);

FIFO FIFO_inst1( 	.i_fosk(i_fosk),
					.i_rst_n(i_rst_n),
					.i_shr(shr_data),
					.i_ready(!empty),
					.i_w_addr(i_w_addr),
					.i_mpcm(i_mpcm),
					.i_mpcm_addr(mpcm_addr),
					.o_shr_empty_set(shr_empty_set),
					.o_udr(o_udr),
					.o_RX8(o_RX8),
					.o_FE(o_FE),
					.o_PE(o_PE),
					.o_RXC(o_RXC)
					);
					
////////////////////////////////////////////////////////////////////////////////////
//				Output
////////////////////////////////////////////////////////////////////////////////////
always@(posedge i_fosk, negedge i_rst_n) begin
	if(!i_rst_n)
		o_dor <= 0;
	else
		o_dor <= ~shr_empty_set & (o_dor | dor);			// set/reset logic for data overrun flag
end



endmodule
