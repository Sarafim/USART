`timescale 1ns / 1ps
module clock_generator (	i_fosk,	
							i_rst_n,		
							i_clk,
							i_UBRR,
							i_UCPOL,
							i_U2X,
							i_DDR_XCK,
							i_UMSEL,
							i_we_ubrrh,
							i_we_ubrrl,
							i_data,
							o_txclk,
							o_rxclk,
							o_clk
						);

input 			i_fosk;			//	system clock
input 			i_rst_n;		//	reset
input 			i_clk;			//	clock used for synchronous slave operation
input [11:0]	i_UBRR;			//	UBRR[11:0]: USART Baud Rate Register
input			i_UCPOL;		//	UCSRC Bit 0 - UCPOL: Clock polarity	
input 			i_U2X;			//	UCSRA Bit 1 – U2X: Double the USART transmission speed
input 			i_DDR_XCK;		//	data direct register 
input 			i_UMSEL;
input			i_we_ubrrh;		// 	write enable for Baud Rate Register High
input			i_we_ubrrl;		//	write enable for Baud Rate Register Low
input [7:0]		i_data;

output 			o_txclk;		//	transmitter clock enable
output			o_rxclk;		//	receiver clock enable
output			o_clk;			//	clock used for synchronous master operation

////////////////////////////////////////////////////////////////////////////////////
//				Variables
////////////////////////////////////////////////////////////////////////////////////
//Prescaling Down-Counter
reg 	[11:0] 	counter;								//	Prescaling Down-counter
wire 			f_div;									//	frequency divided by UBRR
//Double flopping for synchronous slave operation
reg 			first_flop;						
reg 			second_flop;
//Edge detector for synchronous slave operation
reg 			edge_flop;								//	flip_flop for edge detection 
// Clock for synchronous slave operation	
reg 			f_slave;								//  synchronous slave frequency
//Modes
wire			f_master;								//  synchronous master frequency
wire			mode_8;									//	asynchronous double speed mode
wire			mode_16;								//	asynchronous normal mode	
reg		[3:0]	mode_counter;							//  counter for divide
//Output 
wire 			f_txclk;								//	write enable for transmit
wire            f_rxclk;								//	write enable for receive
reg 			txclk;									//  flip_flop for edge detection
reg 			rxclk;									//  flip_flop for edge detection
wire 			f_syn;									//  output flip_flop
////////////////////////////////////////////////////////////////////////////////////
//				Asynchronous part
////////////////////////////////////////////////////////////////////////////////////
//Prescaling Down-Counter
always @( posedge i_fosk, negedge i_rst_n) begin
	if( !i_rst_n ) 
		counter <= 12'h000;
	else 
		case(1'b1)													//  synopsys parallel_case 
			i_we_ubrrl:	counter <= 	{4'h0,i_data};					//	new UBRRH value
			i_we_ubrrh:	counter <= 	{i_data[3:0], 8'h00};			//	new UBRRL value
			~(|counter):counter <=	i_UBRR;
		default: counter <=	counter - 1'b1;
		endcase 	
end
assign f_div = ~(|counter);
//Modes
always@(posedge i_fosk, negedge i_rst_n) begin
	if(!i_rst_n) 
		mode_counter <= 4'h0;
	else if(f_div)
		mode_counter <= mode_counter - 1;
end
assign	f_master = mode_counter[0];				// divided by 2
assign	mode_8 = mode_counter[2];				// divided by 8
assign	mode_16 = mode_counter[3];				// divided by 16

////////////////////////////////////////////////////////////////////////////////////
//				Synchronous part
////////////////////////////////////////////////////////////////////////////////////
//Double flopping for synchronous slave operation
always@(posedge i_fosk, negedge i_rst_n) begin
	if(!i_rst_n) begin
		first_flop <= 1'b0;
		second_flop<= 1'b0;
	end
	else begin
		first_flop <= i_clk;
		second_flop<= first_flop;
	end
end

//Edge detector for synchronous slave operation
always@(posedge i_fosk, negedge i_rst_n) begin
	if(!i_rst_n) begin
		edge_flop <= 1'b0;
	end
	else begin
		edge_flop <= i_UCPOL ? 	( second_flop & ~first_flop) : 	//	negedge
								(~second_flop &  first_flop);	// 	posedge
	end
end
// Clock for synchronous slave operation
always@(posedge i_fosk, negedge i_rst_n) begin
	if(!i_rst_n) 
		f_slave <= 1'b0;
	else if(edge_flop)
		f_slave <= edge_flop;
	else
		f_slave <= 1'b0;	// ~f_slave;
end

////////////////////////////////////////////////////////////////////////////////////
//				Output 
////////////////////////////////////////////////////////////////////////////////////
//Master or slave mode in synchronous operation 
assign f_syn = i_DDR_XCK ? f_master : f_slave;										// direction transmit or receive
assign f_txclk = (i_UMSEL ? f_syn : (i_U2X ? mode_8 : mode_16));
assign f_rxclk = (i_UMSEL ? f_syn : f_div);	

//Edge detector (decrease duty cycle)
always@(posedge i_fosk, negedge i_rst_n) begin
	if(!i_rst_n) begin
		txclk 	<= 1'b0;
		rxclk 	<= 1'b0;
	end
	else begin
		txclk 	<= f_txclk;			//write enable for transmit
		rxclk  	<= f_rxclk;			//write enable for receive		
	end
end


assign o_txclk =  	~txclk & f_txclk;	
assign o_rxclk = 	~rxclk & f_rxclk;
assign o_clk   = 	f_master;

endmodule