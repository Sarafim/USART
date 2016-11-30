// ---------------------------------------------------------------------------
//
// Description:
//  <Description text here, indented multiple lines allowed>
//
// File:        $Source: /var/cvsmucontrol/users/tgu/Tools/merlin2/DigitalFlow/Templates/verilog.v.tpl,v $
// Created:     Tue Jul 12 15:59:07 EEST 2016
//      by:     smy
// Updated:     $Date: 2011/08/09 12:38:38 $
//              $Author: tgu $
// Revision:    $Revision: 1.1 $
//
// Copyright (c) Melexis Digital Competence Center
//
// ---------------------------------------------------------------------------
`timescale 1ns/ 1ps
module data_path_receiver(	i_fosk,
							i_rst_n,
							i_RxD,
							i_rxclk,
							i_umsel,
							i_upm0,
							i_u2x,
							i_ucsz,
							i_shr_empty_set,
							i_fsm_empty_rst,
							i_fsm_start,
							i_fsm_parity,
							i_fsm_stop,
							i_fsm_data,
							i_dor_disable,
							i_sh_reg_i_r,
							o_det_start,
							o_next_state,
							o_state_count,
							o_empty,
							o_shr_data,
							o_mpcm_addr
							);


input 			i_fosk;					//	system clock
input 			i_rst_n;				//	reset
input 			i_RxD;					// 	data from outside
input 			i_rxclk;				//  receiver clock enable
input 			i_umsel;				//	USART Mode Select	0 - Asynchronous Operation, 1 - Synchronous Operation
input 			i_upm0;					//  parity mode
input 			i_u2x;					//	UCSRA Bit 1 – U2X: Double the USART transmission speed
input	[2:0]	i_ucsz;					//  data size bits UCSZ[2:0]
input 			i_shr_empty_set;		//  FIFO take data from shift register
input 			i_fsm_empty_rst;		//  FSM write new data into shift register
input 			i_fsm_start;			//  receive start bit 
input 			i_fsm_parity;			//  receive parity bit
input 			i_fsm_stop;				//	receive stop bit
input 			i_fsm_data;				//  receive data bit
input			i_dor_disable;			//  if data overrun, wait for the next start bit
input			i_sh_reg_i_r;			// 	reset enable for input_shift_register after stop bit


output			o_mpcm_addr;			//  address bit in multiprocessor mode
output			o_next_state;			//  next state enable 
output			o_det_start;			//	start bit came
output	[3:0]	o_state_count;			//	state counter for fsm
output 			o_empty;				//  empty flag for shift register
output	[10:0]	o_shr_data;				//  shift register 10 - PE
										//  				9 - FE
										//				  8-0 - DATA bits
////////////////////////////////////////////////////////////////////////////////////
//				Variables
////////////////////////////////////////////////////////////////////////////////////
//Shift registr: write and take data 
reg 			fsm_empty_rst;			// flop for edge detection of empty flag from fsm
reg 			empty;					// flop for empty flag
reg				det_start;	
reg				mpcm_addr;			
//Input Logic 	
reg 	[9:0] 	sh_reg_i;				// input shift register 
wire 			data_in_s;				// input data, Synchronous Operation
wire			data_in_a;				// input data after recovery block, Asynchronous Operation
wire 			data_in;				// input data 
//Counter
reg 	[7:0]	counter;				// counter
reg				next_state;				// next state enable 
wire    [3:0]   state_count;			// state counter for fsm
//"Shift" register
reg 			parity_r;				// register for counting parity bit
reg 			shr_count_we;			// write enable for shift register from counter
reg 	[10:0]	sh_reg_r;				// receive "shift" register
reg 			help;					// flag for reset of shift register at the beginning of transaction 
////////////////////////////////////////////////////////////////////////////////////
//				Shift register empty flag: write(FSM) - reset flag and take data(FIFO) - set flag
////////////////////////////////////////////////////////////////////////////////////
always@(posedge i_fosk, negedge i_rst_n) begin
	if(!i_rst_n) begin
		empty <= 1'b1;
		fsm_empty_rst<= 0;
	end
	else begin
		fsm_empty_rst <= i_fsm_empty_rst;
		empty <= ~(i_fsm_empty_rst &(!fsm_empty_rst)) & (i_shr_empty_set | empty );				// reset part & set part
	end
end

////////////////////////////////////////////////////////////////////////////////////
//				Input Logic  
////////////////////////////////////////////////////////////////////////////////////
//	Input shift register
always@(posedge i_fosk, negedge i_rst_n) begin
	if(!i_rst_n) 
		sh_reg_i <= 10'h3FF;
	else 
		if(i_umsel)begin												//	if synchronous mode
			sh_reg_i <= {i_RxD, sh_reg_i[9:1]};		
		end
		else begin														//	if asynchronous mode
			if(i_sh_reg_i_r)											//	reset shift register after stop bit
					sh_reg_i <= 10'h3FF;
			else if(i_rxclk) 											//	shift each rxclk 
					sh_reg_i <= {i_RxD, sh_reg_i[9:1]};	
		end																			
end

assign 	data_in_a = ((sh_reg_i[9]&sh_reg_i[8]) | (sh_reg_i[9]&sh_reg_i[7])  | (sh_reg_i[8]&sh_reg_i[7])) ;	// 	input data in asynchronous mode
assign  data_in_s =  sh_reg_i[2];																			// 	input data in asynchronous mode (shift register is used as "double flopping")
assign  data_in = i_umsel ?  data_in_s : data_in_a;															//	synchronous or asynchronous mode

//	start bit dector
always@(posedge i_fosk, negedge i_rst_n)begin
	if(!i_rst_n) 
		det_start <= 0;
	else begin
		det_start <=  ~(i_umsel ?  data_in_s : ( data_in_a | (i_u2x ? sh_reg_i[4]: sh_reg_i[0] )));			//	different condition in different modes
	end
end

////////////////////////////////////////////////////////////////////////////////////
//				Counter
////////////////////////////////////////////////////////////////////////////////////
always@(posedge i_fosk, negedge i_rst_n) begin
	if(!i_rst_n) 
			counter <= 7'b0000000;
	else begin
		if(!i_umsel)																											// Asynchronous mode
			if(((!det_start)&(~(i_umsel ?  data_in_s : ( data_in_a | (i_u2x ? sh_reg_i[4]: sh_reg_i[0] ) )))) & i_fsm_start) 	// if FSM in start_state and posedge of det_start was detected, reset counter (negedge of the RxD)
				counter <= i_u2x ? 7'b0000111 : 7'b0001011; 																	// set 6 - double speed mode, set 10 - normal mode												
			else if(i_rxclk) 
				counter <= counter + 1'b1;																						
			
		if(i_umsel)																												// Synchronous mode
			if(i_fsm_start & det_start)																							// if FSM in start_state and start bit was detected, reset counter																					
				counter <= 7'h02;									
			else if(i_rxclk) 
				counter <= counter + 1'b1;
		end	
end

assign state_count = i_umsel? counter [3:0]: (i_u2x ? counter[6:3] : counter [7:4]) ;											// state counter for FSM (Synchronous or (Double speed or Normal))

//	flop for edge detector 
always@(posedge i_fosk, negedge i_rst_n) begin																		
	if(!i_rst_n) 
		next_state <= 0;
	else
		next_state <= state_count;	
end
////////////////////////////////////////////////////////////////////////////////////
//				"Shift" register
////////////////////////////////////////////////////////////////////////////////////
// write enable for shift register \from counter
always@* begin
	if(i_umsel)																			// 	Synchronous Operation 
		shr_count_we = !i_umsel;
	else																				//	Asynchronous Operation
		if(i_u2x)																		//	counter[2:0] == 6
			shr_count_we = (!counter[0]) & counter[1] & counter [2] ;
		else																			// 	counter[3:0] == 10 
			shr_count_we = (!counter[0]) & counter[1] & (!counter [2]) & counter[3];			
end

//	parity
always@(posedge i_fosk, negedge i_rst_n) begin
	if(!i_rst_n)
		parity_r <= 0;
	else 
		if(i_rxclk )
			if(i_fsm_start)																// initialization
				parity_r <= i_upm0;
			else if(shr_count_we| i_umsel)												// count parity every new bit data bit
				parity_r <=  parity_r ^ data_in;
end

//	receive "shift" register
always@(posedge i_fosk, negedge i_rst_n) begin
	if(!i_rst_n) begin
		sh_reg_r <= 11'h000;
		mpcm_addr <= 0;
		help <= 0;
	end
	else
		if(i_rxclk) begin
			if(i_fsm_start) begin
				help <= 1;
			end
			if((shr_count_we | i_umsel) & i_fsm_data &i_dor_disable) begin					// data bits
				if(help)
					sh_reg_r<= 0;
				help <= 0;
				sh_reg_r[7:0] <= sh_reg_r[8:1];												// sfift
				case(i_ucsz)
					3'b000: sh_reg_r[4] <= data_in;											// 5 data bits
					3'b001:	sh_reg_r[5] <= data_in;											// 6 data bits
					3'b010:	sh_reg_r[6] <= data_in;											// 7 data bits
					3'b011:	sh_reg_r[7] <= data_in;											// 8 data bits
					3'b111:	sh_reg_r[8] <= data_in;											// 9 data bits
					default:sh_reg_r <= 10'h000;											// something wrong
				endcase	
				mpcm_addr <= data_in;														// flop for address in mpcm
			end
			if(i_fsm_stop & (shr_count_we|i_umsel)&i_dor_disable)							// stop bit detection => frame error flag
				sh_reg_r[9]  <=	!data_in;	
			if(i_fsm_parity&i_dor_disable)	
				sh_reg_r[10] <= (parity_r&!i_umsel)|(i_umsel& (parity_r ^ data_in));												// count differnt for differnt modes
		end
end

////////////////////////////////////////////////////////////////////////////////////
//				OUTPUT
////////////////////////////////////////////////////////////////////////////////////
assign 	o_det_start = det_start;
assign 	o_empty = empty;
assign  o_next_state = next_state ^ state_count;
assign	o_state_count = state_count;
assign	o_shr_data = sh_reg_r;
assign 	o_mpcm_addr = mpcm_addr;

endmodule
