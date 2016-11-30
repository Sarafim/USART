`timescale 1ns / 1ps
module	registers(	i_fosk,											
					i_rst_n,										
					i_addr,
					i_word,
					i_we,
					i_udre,
					i_dor,
					i_udr_rc,
					i_rx8,
					i_fe,
					i_pe,
					i_rxc,
					i_txc,
					o_word,
					o_ubrr,
					o_ucpol,
					o_u2x,
					o_umsel,
					o_we_ubrrh,
					o_we_ubrrl,
					o_txen,
					o_ucsz,
					o_usbs,
					o_upm,
					o_we_udr_tr,
					o_udr_tr,
					o_tx8,
					o_rxen,
					o_we_udr_rc,
					o_mpcm
					);

input			i_fosk;											
input			i_rst_n;										
input	[7:0]	i_addr;
input	[7:0]	i_word;
input			i_we;
input			i_udre;
input			i_dor;
input	[7:0]	i_udr_rc;
input			i_rx8;
input			i_fe;
input			i_pe;
input			i_rxc;
input			i_txc;

output	reg	[7:0]	o_word;
output		[11:0]	o_ubrr;
output				o_ucpol;
output				o_u2x;
output				o_umsel;
output				o_we_ubrrh;
output				o_we_ubrrl;
output				o_txen;
output		[2:0]	o_ucsz;
output				o_usbs;
output		[1:0]	o_upm;
output				o_we_udr_tr;
output		[7:0]	o_udr_tr;
output				o_tx8;
output				o_rxen;
output				o_we_udr_rc;
output				o_mpcm;
////////////////////////////////////////////////////////////////////////////////////
//				Variables
////////////////////////////////////////////////////////////////////////////////////
reg sel;					//	selection between UCSRC and UBRRH
reg	txc_r;					//	flop for detection of posedge

reg we_udr_tr;		//	write enable for transmit register 
reg we_ucsra;		//	write enable for Control and Status Register A
reg we_ucsrb;		//	write enable for Control and Status Register B
reg we_ucsrc;		//	write enable for Control and Status Register C
reg we_ubrrh;		//	write enable for Baud Rate Register High
reg we_ubrrl;		//	write enable for Baud Rate Register Low

wire we_txc_rxc;	//	write enable from TXC and RXC flags for UCSRA, UCSRB, UCSRC

// registers
reg 	[7:0]	udr_tr;
reg 			txc;
reg 			u2x;
reg 			mpcm;
reg				rxcie;
reg				txcie;
reg 			udrie;
reg 			rxen;
reg				txen;
reg 			ucsz2;
reg 			tx8;
reg				ursel1;
reg 			umsel;
reg 	[1:0]	upm;
reg				usbs;
reg		[1:0]	ucsz;
reg 			ucpol;
reg				ursel2;	
reg		[3:0]	ubrrh;
reg		[7:0]	ubrrl;

////////////////////////////////////////////////////////////////////////////////////
//				Write enable
////////////////////////////////////////////////////////////////////////////////////
//Creating write enable
always@* begin
	we_udr_tr 	= 0;		
 	we_ucsra	= 0;		
	we_ucsrb	= 0;		
 	we_ucsrc	= 0;		
	we_ubrrh	= 0;		
	we_ubrrl	= 0;	
	case(i_addr)								
			8'h00:	we_udr_tr	= i_udre & txen;					//	write enable for udr transmitter
			8'h01:	we_ucsra 	= 1'b1;						//	write enable for ucsra
			8'h02:	we_ucsrb 	= 1'b1;						//	write enable for ucsrb
			8'h03:	if(i_word[7])
						we_ucsrc 	 = 1'b1;					//	write enable for ucsrc
					else
						we_ubrrh	= 1'b1;							//	write enable for ubrrh
			8'h04:	we_ubrrl = 1'b1;								//	write enable for ubrrl
	endcase	
end

////////////////////////////////////////////////////////////////////////////////////
//				TXC flag
////////////////////////////////////////////////////////////////////////////////////

always@(posedge i_fosk, negedge i_rst_n) begin
	if(!i_rst_n) 
		txc_r <= 0;
	else
		txc_r <= i_txc;											
end

assign	txc_f = !txc_r & i_txc;							//	set by posedge of i_txc(flag from receiver)

////////////////////////////////////////////////////////////////////////////////////
//				Registers
////////////////////////////////////////////////////////////////////////////////////
always@(posedge i_fosk, negedge i_rst_n) begin
	if(!i_rst_n) begin
		udr_tr <= 0;
		txc <= 0;
		u2x <= 0;
		mpcm <= 0;
		rxcie <= 0;
		txcie <= 0;
		udrie <= 0;
		rxen <= 0;
		txen <= 0;
		ucsz2 <= 0;
		tx8 <= 0;
		ursel1 <= 0;
		umsel <= 0;
		upm <= 0;
		usbs <= 0;
		ucsz <= 0;
		ucpol <= 0;
		ursel2 <= 0;	
		ubrrh <= 0;
		ubrrl <= 0;
	end 
	else begin
		txc <= (txc_f | txc)&i_udre;					//	set/reset logic of the  txc flag
		if(i_we)begin
			case(1'b1)	
				we_udr_tr:	udr_tr <= i_word;											//	udr transmitter
				we_ucsra:	begin														//	ucsra	
								txc <= i_word[6];															
								u2x	<= i_word[1];
								mpcm <= i_word[0];
							end		
				we_ucsrb:	begin														//	ucsrb
								rxcie <= i_word[7];
								txcie <= i_word[6];
								udrie <= i_word[5];
								rxen  <= i_word[4];
								txen  <= i_word[3];
								ucsz2 <= i_word[2];
								tx8  <= i_word[0];
							end
				we_ucsrc:	begin														//	ucsrc					
								ursel1 <= i_word[7]; 
								umsel <= i_word[6];
								upm <= i_word[5:4];
								usbs <= i_word[3];
								ucsz <= i_word[2:1];
								ucpol <=i_word[0];
							end	
				we_ubrrh:	{ ursel2, ubrrh }  <= { i_word[7], i_word[3:0] };			//	ubrrh
				we_ubrrl:	ubrrl  <= i_word;											//	ubrrl
			endcase
		end
	end
end

////////////////////////////////////////////////////////////////////////////////////
//				Reading unit
////////////////////////////////////////////////////////////////////////////////////
//	Accessing UBRRH/UCSRC	Registers
always@(posedge i_fosk, negedge i_rst_n) begin
	if(!i_rst_n) 
		sel <= 1'b0;
	else 
		if(i_addr == 8'h04)
			sel <= ~sel;
		else
			sel <= 1'b0;
end

//	output of the USART
always@* begin
	case(i_addr)								
		8'h00:  o_word = i_udr_rc;							//	udr receiver
		8'h01:	begin										//	ucsra
					o_word[7] = i_rxc;
					o_word[6] = txc;
					o_word[5] = i_udre;
					o_word[4] = i_fe;
					o_word[3] = i_dor;
					o_word[2] = i_pe;
					o_word[1] = u2x;
					o_word[0] = mpcm;
				end
		8'h02:	begin										//	ucsrb		
					o_word[7] = rxcie;
					o_word[6] = txcie;
					o_word[5] = udrie;
					o_word[4] = rxen;
					o_word[3] = txen;
					o_word[2] = ucsz2;
					o_word[1] = i_rx8;
					o_word[0] = tx8;
				end
		8'h03:	begin										//	Access to UBRRH/UCSRC Registers 
					if(sel)begin							//	ucsra 
						o_word[7] = ursel1;
						o_word[6] = umsel;
						o_word[5:4] = upm;
						o_word[3] = usbs;
						o_word[2:1] = ucsz;
						o_word[0] = ucpol;
					end
					else begin
						o_word[7] = ursel2;					//	ubrrh
						o_word[6:4] = 3'b000;
						o_word[3:0] = ubrrh;
					end
				end
		8'h04:	o_word = ubrrl;								//ubrrl
		default: o_word = 8'h00;
	endcase
end

////////////////////////////////////////////////////////////////////////////////////
//				Output for inside 
////////////////////////////////////////////////////////////////////////////////////
assign	o_ubrr = {ubrrh, ubrrl};
assign	o_ucpol = ucpol;
assign	o_u2x = u2x;
assign	o_umsel = umsel;
assign	o_we_ubrrh = we_ubrrh;
assign	o_we_ubrrl = we_ubrrl;
assign	o_txen = txen;
assign	o_ucsz = {ucsz2, ucsz};
assign	o_usbs = usbs;
assign	o_upm = upm;
assign	o_we_udr_tr = we_udr_tr &i_we;
assign	o_udr_tr = udr_tr;
assign	o_tx8 = tx8;
assign	o_rxen = rxen;
assign	o_we_udr_rc = (!i_addr & !i_we);
assign	o_mpcm = mpcm;

endmodule
