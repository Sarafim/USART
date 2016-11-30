// ---------------------------------------------------------------------------
//
// Description:
//  <Description text here, indented multiple lines allowed>
//
// File:        $Source: /var/cvsmucontrol/users/tgu/Tools/merlin2/DigitalFlow/Templates/verilog.v.tpl,v $
// Created:     Tue Jul 12 14:31:01 EEST 2016
//      by:     smy
// Updated:     $Date: 2011/08/09 12:38:38 $
//              $Author: tgu $
// Revision:    $Revision: 1.1 $
//
// Copyright (c) Melexis Digital Competence Center
//
// ---------------------------------------------------------------------------
`timescale 1ns / 1ps
module transmitter(	i_fosk,
					i_rst_n,
					i_TXEN,
					i_txclk,
					i_ucsz,
					i_usbs,
					i_upm,
					i_we_udr_tr,
					i_udr,
					i_tx8,
					o_TxD,
					o_udre,
					o_txc
					);

input 		i_fosk;				//	system clock
input 		i_rst_n;			//	reset
input 		i_TXEN;				//  TXEN 
input 		i_txclk;			//  transmitter clock enable
input [2:0]	i_ucsz;				//	data size bits UCSZ[2:0]
input 		i_usbs;				//	stop bit size bit USBS
input [1:0]	i_upm;				//	parity bits disabled/enabled  even/odd
input 		i_we_udr_tr;		//	write enable for transmit register 
input [7:0]	i_udr;				//	UDR[7:0]
input 		i_tx8;				//  TX8 => UDR[8]
	
output		o_TxD;				//  output value TxD
output		o_udre;				// 	UDRE flag
output 		o_txc;				//	txc flag
////////////////////////////////////////////////////////////////////////////////////
//				Variables
////////////////////////////////////////////////////////////////////////////////////
//Design
wire fsm_we;					//  transmit data from UDR to shift register
wire fsm_ps;					//  parity and start or stop bit
wire fsm_ad;					//  alternative or data bit 
wire fsm_pi;					//  parity initialization bit 
wire fsm_dp;					//  alternative or parity bit 
//Output
wire udre;						//  output value TxD
wire TxD;						// 	UDRE flag
wire txc;						//	txc flag
////////////////////////////////////////////////////////////////////////////////////
//				Design
////////////////////////////////////////////////////////////////////////////////////
FSM_transmitter FSM_transmitter_inst1(	.i_fosk(i_fosk),
										.i_rst_n(i_rst_n),
										.i_TXEN(i_TXEN),
										.i_txclk(i_txclk),
										.i_udre(udre),
										.i_ucsz(i_ucsz),
										.i_usbs(i_usbs),
										.i_upm1(i_upm[1]),
										.o_fsm_we(fsm_we),
										.o_fsm_ps(fsm_ps),
										.o_fsm_ad(fsm_ad),
										.o_fsm_pi(fsm_pi),
										.o_fsm_dp(fsm_dp),
										.o_txc(txc)
										);

data_path_transmitter data_path_transmitter_inst1(	.i_fosk(i_fosk),
													.i_rst_n(i_rst_n),
													.i_txclk(i_txclk),
													.i_we_udr_tr(i_we_udr_tr),
													.i_tx(i_udr),
													.i_tx8(i_tx8),
													.i_UPM0(i_upm[0]),
													.i_fsm_we(fsm_we),
													.i_fsm_ps(fsm_ps),
													.i_fsm_ad(fsm_ad),
													.i_fsm_pi(fsm_pi),
													.i_fsm_dp(fsm_dp),
													.o_TxD(TxD),
													.o_udre(udre)
													);

////////////////////////////////////////////////////////////////////////////////////
//				Output
////////////////////////////////////////////////////////////////////////////////////
 assign o_udre = udre;
 assign o_TxD = TxD;
 assign o_txc = txc;


endmodule