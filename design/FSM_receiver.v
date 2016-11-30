// ---------------------------------------------------------------------------
//
// Description:
//  <Description text here, indented multiple lines allowed>
//
// File:        $Source: /var/cvsmucontrol/users/tgu/Tools/merlin2/DigitalFlow/Templates/verilog.v.tpl,v $
// Created:     Wed Jul 13 13:30:49 EEST 2016
//      by:     smy
// Updated:     $Date: 2011/08/09 12:38:38 $
//              $Author: tgu $
// Revision:    $Revision: 1.1 $
//
// Copyright (c) Melexis Digital Competence Center
//
// ---------------------------------------------------------------------------
`timescale 1ns/ 1ps

module FSM_receiver(	i_fosk,
						i_rst_n,
						i_RXEN,
						i_rxclk,
						i_ucsz,
						i_upm1,
						i_umsel,
						i_det_start,
						i_next_state,
						i_state_count,	
						i_empty,
						o_fsm_empty_rst,
						o_fsm_start,
						o_fsm_parity,
						o_fsm_stop,
						o_fsm_data,
						o_dor,
						o_sh_reg_i_r,
						o_dor_disable
					);

input 			i_fosk;				//	system clock	
input			i_rst_n;			//	reset
input 			i_RXEN;				//  RXEN 
input 			i_rxclk;			//  receiver clock enable
input 	[2:0]	i_ucsz;				//	data size bits UCSZ[2:0]
input 			i_upm1;				//	parity bit even/odd
input 			i_umsel;			//	USART Mode Select	0 - Asynchronous Operation, 1 - Synchronous Operation
input 			i_det_start;		//  start bit came
input			i_next_state;		//	next state enable
input 	[3:0]	i_state_count;		//	state counter
input 			i_empty;			//  empty flag for shift register


output 	reg		o_fsm_empty_rst;	//  FSM write new data into shift register
output	reg		o_fsm_start;		//  receive start bit
output	reg		o_fsm_parity;		//  receive parity bit
output	reg		o_fsm_stop;			//	receive stop bit
output	reg		o_fsm_data;			//  receive data bit
output	reg		o_dor;				//	data overrun
output  		o_sh_reg_i_r;		// 	reset enable for input_shift_register after stop bit
output  reg 	o_dor_disable;		//  if data overrun, wait for the next start bit
////////////////////////////////////////////////////////////////////////////////////
//				FSM states
////////////////////////////////////////////////////////////////////////////////////\
localparam	IDLE = 0; 
localparam	START_0 = 1;
localparam	DATA = 2;
localparam	PARITY = 3;
localparam	STOP = 4;
localparam 	START_1 = 5;
////////////////////////////////////////////////////////////////////////////////////
//				Variables
////////////////////////////////////////////////////////////////////////////////////
reg [3:0]	state;
reg [3:0]	next_state;

reg			fsm_start;
reg 		fsm_empty_rst;
reg			fsm_parity;
reg			fsm_stop;
reg 		fsm_data;
reg			dor;
reg			sh_reg_i_r;	

reg [3:0]	last_data;			// 	value of count for the last data bit
reg 		b_sh_reg_i_r;		//	variable for edge detector of sh_reg_i_r
reg			trans;				//	for transation from asynchronous to synchronous mode
reg 		trans_r;			//	for transation from asynchronous to synchronous mode
////////////////////////////////////////////////////////////////////////////////////
//				FSM
////////////////////////////////////////////////////////////////////////////////////
always@(posedge i_fosk, negedge i_rst_n) begin
	if(!i_rst_n)begin
		state <= IDLE;
		o_fsm_empty_rst <= 1'b0;
		o_fsm_start <= 1'b0;
		o_fsm_parity <= 1'b0;
		o_fsm_stop <= 1'b0;
		o_fsm_data <= 1'b0;
		o_dor <= 1'b0;
		b_sh_reg_i_r <= 1;
		o_dor_disable <= 1;
		trans_r <= 1;
	end
	else begin
		b_sh_reg_i_r <= sh_reg_i_r;																// for edge detector
		
		trans_r <= trans;
		if(state == IDLE & i_RXEN) 																// can leave IDLE state every posedge of MCU clock
			state <= next_state;
		else
			if((i_next_state&!i_umsel)|(i_rxclk&i_umsel)) begin									// Asynchronous | Synchronous modes
					o_fsm_empty_rst <= fsm_empty_rst;
					state <= next_state;
					o_fsm_start <= fsm_start;
					o_fsm_parity <= fsm_parity;
					o_fsm_stop <= fsm_stop;
					o_fsm_data <= fsm_data;
					o_dor <= dor;
					if(state == START_1)														
						o_dor_disable <= ~dor;
			end
	end
end

assign 		o_sh_reg_i_r = b_sh_reg_i_r & !sh_reg_i_r;											// edge detector

always@* begin
	next_state 	= 	state;
	fsm_empty_rst = 1'b0;
	fsm_start = 1'b0;
	fsm_parity = 1'b0;
	fsm_stop = 1'b0;
	fsm_data = 1'b0;
	dor = 1'b0;
	sh_reg_i_r = 0;
	trans = trans_r;
	if(i_RXEN)begin																			// if receiver is on
		case(state)
			IDLE:	if(i_RXEN)begin
						next_state = START_0;
						fsm_start = 1'b1;	
					end
			START_0:if(i_det_start & i_empty) begin
							next_state = DATA;
							fsm_data = 1'b1;
					end
					else begin
						next_state = START_0;
						fsm_start = 1'b1;	
					end
			DATA:	begin
						case(i_ucsz)														// amount of data bits
							3'b000:	last_data = 6;											// 5
							3'b001: last_data = 7;											// 6
							3'b010:	last_data = 8;											// 7
							3'b011:	last_data = 9;											// 8
							3'b111:	last_data = 10;											// 9
							default: last_data = 0;											// ERROR
						endcase
						if(i_state_count == last_data)										
							if(i_upm1)begin
								next_state = PARITY;
								fsm_parity = i_upm1;
							end
							else begin
								next_state = STOP;
								fsm_stop = 1;
							end
						else begin
							next_state = DATA;
							fsm_data = 1'b1;
							trans = 1;
						end	
					end
			PARITY:	begin
						begin
							next_state = STOP;
							fsm_stop = 1;
						end
					end
			STOP:	begin
						next_state = START_1;
						fsm_start = 1;
						if(!i_umsel)	 begin												//	data overrun processing in Asynchronous mode
							fsm_empty_rst = o_dor_disable;
							trans = 0;
						end
						sh_reg_i_r = 1;
					end
			START_1:begin
						sh_reg_i_r = 0;
						if(i_umsel&trans_r)														//	data overrun processing in Synchronous mode
							fsm_empty_rst = o_dor_disable;

						if(i_det_start)
							if(i_empty) begin
								next_state = DATA;
								fsm_data = 1'b1;
							end
							else begin
								next_state = DATA;
								fsm_data = 1'b1;
								dor = i_det_start;
							end
						else begin
							fsm_start = 1;
						end	
					end
			default:next_state = IDLE;
		endcase
	end
	else 																				// if receiver is off
		next_state = IDLE;
end
endmodule
