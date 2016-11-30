// ---------------------------------------------------------------------------
//
// Description:
//  <Description text here, indented multiple lines allowed>
//
// File:        $Source: /var/cvsmucontrol/users/tgu/Tools/merlin2/DigitalFlow/Templates/verilog.v.tpl,v $
// Created:     Tue Jul 12 11:05:30 EEST 2016
//      by:     smy
// Updated:     $Date: 2011/08/09 12:38:38 $
//              $Author: tgu $
// Revision:    $Revision: 1.1 $
//
// Copyright (c) Melexis Digital Competence Center
//
// ---------------------------------------------------------------------------
`timescale 1ns / 1ps
module FSM_transmitter(	i_fosk,
						i_rst_n,
						i_TXEN,
						i_txclk,
						i_udre,
						i_ucsz,
						i_usbs,
						i_upm1,
						o_fsm_we,
						o_fsm_ps,
						o_fsm_ad,
						o_fsm_pi,
						o_fsm_dp,
						o_txc
						);

input			i_fosk;				//	system clock
input			i_rst_n;			//	reset
input 			i_TXEN;				//  TXEN 
input			i_txclk;			//  transmitter clock enable
input			i_udre;				// 	UDRE flag
input	[2:0]	i_ucsz;				//	data size bits UCSZ[2:0]
input			i_usbs;				//	stop bit size bit USBS
input			i_upm1;				//	parity bit even/odd

output	reg		o_fsm_we;			//  transmit data from UDR to shift register
output	reg		o_fsm_ps;			//  parity and start or stop bit
output	reg		o_fsm_ad;			//  alternative or data bit 
output	reg		o_fsm_pi;			//  parity initialization bit 
output	reg		o_fsm_dp;			//  alternative or parity bit 
output	reg		o_txc;				// 	flag txc
////////////////////////////////////////////////////////////////////////////////////
//				FSM states
////////////////////////////////////////////////////////////////////////////////////\
localparam	IDLE = 0;
localparam	START = 1;
localparam	DATA_0 = 2;
localparam	DATA_1 = 3;
localparam	DATA_2 = 4;
localparam	DATA_3 = 5;
localparam	DATA_4 = 6;
localparam	DATA_5 = 7;
localparam	DATA_6 = 8;
localparam	DATA_7 = 9;
localparam	DATA_8 = 10;
localparam	PARITY = 11;
localparam	STOP_1 = 12;
localparam	STOP_2 = 13;
////////////////////////////////////////////////////////////////////////////////////
//				Variables
////////////////////////////////////////////////////////////////////////////////////
reg [3:0]	state;
reg [3:0]	next_state;

reg			fsm_we;
reg			fsm_ps;
reg			fsm_ad;
reg			fsm_pi;
reg			fsm_dp;
reg			fsm_txc;
////////////////////////////////////////////////////////////////////////////////////
//				FSM
////////////////////////////////////////////////////////////////////////////////////
always@(posedge i_fosk, negedge i_rst_n) begin
	if(!i_rst_n)begin
		state <= IDLE;
		o_fsm_we <= 1'b0;
		o_fsm_ps <= 1'b1;
		o_fsm_ad <= 1'b0;
		o_fsm_pi <= 1'b0;
		o_fsm_dp <= 1'b0;
		o_txc <=1'b0;
	end
	else if(i_txclk) begin
		state <= next_state;
		o_fsm_we <= fsm_we;
		o_fsm_ps <= fsm_ps;
		o_fsm_ad <= fsm_ad;
		o_fsm_pi <= fsm_pi;
		o_fsm_dp <= fsm_dp;
		o_txc <= fsm_txc;
	end
end

always@* begin
	next_state 	= 	state;
	fsm_we		=	1'b0;
	fsm_ps		=	1'b1;
	fsm_ad 		=	1'b0;
	fsm_pi 		=	1'b0;
	fsm_dp 		=	1'b0;
	fsm_txc		= 	1'b0;
	case(state)
		IDLE:	if( (i_udre == 0) & (i_TXEN == 1)) begin		
					next_state  = START;					
					fsm_we = 1'b1;
					fsm_ps = 1'b0;
					fsm_pi = 1'b1;
				end
		START:  begin
					if(	(i_ucsz[2:0] == 3'b100)|
						(i_ucsz[2:0] == 3'b101)|
						(i_ucsz[2:0] == 3'b110)) begin
						if (i_upm1 == 1'b1) begin			// if parity bit exists
							next_state = PARITY;
							fsm_ps = 1'b0;
							fsm_ad = 1'b1;
							fsm_dp = 1'b1;
						end
						else begin							// if parity bit doesn't exist
							next_state = STOP_1;
						end
					end	
					else begin									
						next_state = DATA_0;
						fsm_ad = 1'b1;
					end
				end
		DATA_0: begin	
					next_state = DATA_1;
					fsm_ad = 1'b1;
				end
		DATA_1: begin	
					next_state = DATA_2;
					fsm_ad = 1'b1;
				end
		DATA_2: begin	
					next_state = DATA_3;
					fsm_ad = 1'b1;
				end
		DATA_3: begin	
					next_state = DATA_4;
					fsm_ad = 1'b1;
				end
		DATA_4: begin	
					if(i_ucsz[2:0] == 3'b000)				// if 5 data bits 
						if (i_upm1 == 1'b1) begin			// if parity bit exists
							next_state = PARITY;
							fsm_ps = 1'b0;
							fsm_ad = 1'b1;
							fsm_dp = 1'b1;
						end
						else begin							// if parity bit doesn't exist
							next_state = STOP_1;
						end
					else begin
						next_state = DATA_5;				// if more than 5 data bits
						fsm_ad = 1'b1;
					end
					end
		DATA_5: begin	
					if(i_ucsz[2:0] == 3'b001)				// if 6 data bits 
						if (i_upm1 == 1'b1) begin			// if parity bit exists
							next_state = PARITY;
							fsm_ps = 1'b0;
							fsm_ad = 1'b1;
							fsm_dp = 1'b1;
						end
						else begin							// if parity bit doesn't exist
							next_state = STOP_1;
						end
					else begin								// if more than 6 data bits
						next_state = DATA_6;
						fsm_ad = 1'b1;
					end
					end
		DATA_6: begin	
					if(i_ucsz[2:0] == 3'b010)				// if 7 data bits 
						if (i_upm1 == 1'b1) begin			// if parity bit exists
							next_state = PARITY;
							fsm_ps = 1'b0;
							fsm_ad = 1'b1;
							fsm_dp = 1'b1;
						end	
						else begin							// if parity bit doesn't exist
							next_state = STOP_1;
						end
					else begin
						next_state = DATA_7;				// if more than 7 data bits
						fsm_ad = 1'b1;
					end
					end
		DATA_7: begin	
					if(i_ucsz[2:0] == 3'b011)				// if 8 data bits
						if (i_upm1 == 1'b1) begin			// if parity bit exists
							next_state = PARITY;
							fsm_ps = 1'b0;
							fsm_ad = 1'b1;
							fsm_dp = 1'b1;
						end
						else begin							// if parity bit doesn't exist
							next_state = STOP_1;
						end
					else begin								// if more than 8 data bits
						next_state = DATA_8;
						fsm_ad = 1'b1;
					end
					end
		DATA_8: begin		
					if (i_upm1 == 1'b1) begin				// if parity bit exists
						next_state = PARITY;
						fsm_ps = 1'b0;
						fsm_ad = 1'b1;
						fsm_dp = 1'b1;
					end
					else begin								// if parity bit doesn't exist
						next_state = STOP_1;
					end
				end
		PARITY: next_state = STOP_1;
		STOP_1: begin 
					if(i_usbs == 1'b1)						// if second stop bit exists 
						next_state = STOP_2;
					else begin								// if second stop bit doesn't exist 
						if(i_udre == 1)	begin				// if udr is empty
							next_state = IDLE;	
							fsm_txc  = 1'b1;
						end
						else begin							// if udr is full
							next_state = START;
							fsm_we = 1'b1;
							fsm_ps = 1'b0;
							fsm_pi = 1'b1;
						end
					end
				end
		STOP_2: begin 
					if(i_udre == 1)	begin					// if udr is empty
						next_state = IDLE;
						fsm_txc  = 1'b1;
					end	
					else begin
						next_state = START;					// if udr is full
						fsm_we = 1'b1;
						fsm_ps = 1'b0;
						fsm_pi = 1'b1;
					end
				end
	default:	next_state = IDLE;							// something is wrong
	endcase
 end

endmodule 