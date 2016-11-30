`timescale 1ns / 1ps
module data_path_transmitter(	i_fosk,
								i_rst_n,
								i_txclk,
								i_we_udr_tr,
								i_tx,
								i_tx8,
								i_UPM0,
								i_fsm_we,
								i_fsm_ps,
								i_fsm_ad,
								i_fsm_pi,
								i_fsm_dp,
								o_TxD,
								o_udre
								);

input 			i_fosk;			//	system clock
input 			i_rst_n;		//	reset
input 			i_txclk;		//  transmitter clock enable
input 			i_we_udr_tr;	// 	new data in UDR
input	[7:0]	i_tx;			// 	UDR[7:0]
input			i_tx8;			//  UDR[8]
input 			i_UPM0;			//  parity mode
input			i_fsm_we;		//	transmit data from UDR to shift register
input			i_fsm_ps;		//  parity and start or stop bit
input			i_fsm_ad;		//  alternative or data bit 
input			i_fsm_pi;		//  parity initialization bit 
input			i_fsm_dp;		//  alternative or parity bit 

output			o_TxD;			//  output value
output 			o_udre;			// 	UDRE flag
////////////////////////////////////////////////////////////////////////////////////
//				Variables
////////////////////////////////////////////////////////////////////////////////////
//UDRE
reg udre; 						//	UDRE flag	set
reg udre_o;						//	UDRE flag 	reset
//Shift register
reg [8:0]		tx_data;		//	Shift Register
//Logic
wire			frame_bit;		//	selection between data bit and alternative bit
reg 			parity_bit;		
reg 			TxD;			//	output flip_flop
////////////////////////////////////////////////////////////////////////////////////
//				UDRE
////////////////////////////////////////////////////////////////////////////////////
always@(posedge i_fosk, negedge i_rst_n) begin
	if(!i_rst_n) begin
		udre <= 1'b1;
		udre_o <= 1'b1;
	end
	else begin 
		if(udre_o == 1)
			udre_o <= (~i_we_udr_tr);	//udre reset-logic
		else if(i_txclk)
			udre_o <= i_fsm_we;		//udre set-logic
	end
end

////////////////////////////////////////////////////////////////////////////////////
//				Shift Register
////////////////////////////////////////////////////////////////////////////////////
always@(posedge i_fosk, negedge i_rst_n) begin
	if(!i_rst_n) 
		tx_data <= 1'b0;	
	else 
		if(i_txclk) begin
			if(i_fsm_we) 
				tx_data <= {i_tx8,i_tx};
			else
				tx_data <= {1'b0,tx_data[8:1]};
		end
end

////////////////////////////////////////////////////////////////////////////////////
//				Logic
////////////////////////////////////////////////////////////////////////////////////
assign  frame_bit = i_fsm_ad ? tx_data[0] : i_fsm_ps; 						//select data bit or (start | stop | parity)

always@(posedge i_fosk, negedge i_rst_n) begin
	if(!i_rst_n) begin
		parity_bit <= 0;
		TxD <= 1;
	end
	else 
		if(i_txclk) begin
			parity_bit <= i_fsm_pi ? i_UPM0 : (parity_bit ^ frame_bit);		// parity bit initialization(even or odd) or calculation 
			TxD <= i_fsm_dp ? parity_bit : frame_bit;						// select parity bit or (start | stop | data) 
		end
end

////////////////////////////////////////////////////////////////////////////////////
//				OUTPUT
////////////////////////////////////////////////////////////////////////////////////
assign o_TxD = TxD;
assign o_udre = udre_o;


endmodule 