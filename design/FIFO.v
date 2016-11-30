`timescale 1ns/1ps

module FIFO( 	i_fosk,
				i_rst_n,
				i_shr,
				i_ready,
				i_w_addr,
				i_mpcm,
				i_mpcm_addr,
				o_shr_empty_set,
				o_udr,
				o_RX8,
				o_FE,
				o_PE,
				o_RXC
				);

input 			i_fosk;					// 	system clock
input 			i_rst_n;				// 	reset
input 	[10:0]	i_shr;					// 	receive shift register
input 			i_ready;				//	valid data in shift register
input			i_w_addr;				//	data were read from udr
input			i_mpcm;					//  MPCM bit	
input			i_mpcm_addr;			//	address bit in multiprocessor mode

output			o_shr_empty_set;		//	set flag empty of the shift register 
output 	[7:0]	o_udr;					//	udr
output			o_RX8;					//	RXB8: Receive Data Bit 8
output			o_FE;					//	frame error
output			o_PE;					//	parity Error
output 			o_RXC;					//	USART Receive Complete

////////////////////////////////////////////////////////////////////////////////////
//				Variables
////////////////////////////////////////////////////////////////////////////////////
//Writing unit
reg 		w_addr;						//	write addr
wire 		udr1_we;					//	write valid data in the udr1
wire 		udr2_we;					//	write valid data in the udr2
//Registers
reg   		rxc;						//	USART Receive Complete flag
reg [11:0]	udr1;						// 	first fifo register [valid bit, i_shr]
reg [11:0]	udr2;						// 	second fifo register[valid bit, i_shr]
//Reading unit
wire		v1_rst;						//	data from the udr1 - unvalid
wire		v2_rst;						//	data from the udr2 - unvalid
reg 		r_addr;						//	read addr
wire[11:0] 	data;						//  next data

////////////////////////////////////////////////////////////////////////////////////
//				Writing unit
////////////////////////////////////////////////////////////////////////////////////
// next address for writing 
always@(posedge i_fosk, negedge i_rst_n) begin	
	if(!i_rst_n) 
		w_addr <= 0;	
	else
		if(udr1_we|udr2_we) 																			// change address after every record 
			w_addr <= ~w_addr;
end
//write enable for each of the registers
assign 	udr1_we = !udr1[11] & !w_addr & i_ready & (!i_mpcm | (i_mpcm&i_mpcm_addr));						// for first register
assign	udr2_we = !udr2[11] & w_addr & i_ready  & (!i_mpcm | (i_mpcm&i_mpcm_addr));						// for second register

////////////////////////////////////////////////////////////////////////////////////
//				Registers
////////////////////////////////////////////////////////////////////////////////////
always@(posedge i_fosk, negedge i_rst_n) begin
	if(!i_rst_n)begin
		udr1 <= 12'h000;
		udr2 <= 12'h000;
		rxc <= 0;
	end
	else begin
			rxc <= (udr1[11] | udr2[11])&!i_w_addr;			// USART Receive Complete flag
		case(1'b1)											// first register
			udr1_we:	udr1 <= {udr1_we, i_shr};			// write new data 
			v1_rst:		udr1 <= {!v1_rst, udr1[10:0]};		// if data were read, reset valid flag
			default:    udr1 <= udr1;
		endcase

		case(1'b1)											//second register		
			udr2_we: 	udr2 <= {udr2_we, i_shr};			// write new data
			v2_rst:		udr2 <= {!v2_rst, udr2[10:0]};		// if data were read, reset valid flag
			default:    udr2 <= udr2;
		endcase
	end
end

////////////////////////////////////////////////////////////////////////////////////
//				Reading unit
////////////////////////////////////////////////////////////////////////////////////
//next address for reading
always@(posedge i_fosk, negedge i_rst_n) begin
	if(!i_rst_n)
		r_addr <= 1;
	else
		if(i_w_addr)									// change address after every reading 
			r_addr <= ~r_addr;
end

assign	v1_rst = i_w_addr & r_addr;						// reset valid bit in udr1
assign 	v2_rst = i_w_addr & !r_addr;					// reset valid bit in udr2
assign  data   =  r_addr ?  udr1: udr2;					// output data

////////////////////////////////////////////////////////////////////////////////////
//				Output 
////////////////////////////////////////////////////////////////////////////////////
assign 	o_udr = data[7:0];					//	udr
assign	o_RX8 = data[8];					//	RXB8: Receive Data Bit 8
assign	o_FE  = data[9];					//	frame error
assign	o_PE  = data [10];					//	parity Error
assign 	o_RXC = rxc;						//	USART Receive Complete


assign o_shr_empty_set = (udr1_we|udr2_we) & i_ready;	//	set if it exist valid data in FIFO and shift register is empty

endmodule 
