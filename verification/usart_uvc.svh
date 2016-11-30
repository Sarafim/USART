`include	"interface.svh"
///////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////

`ifndef ___USART_UVC_DEFINES___
`define ___USART_UVC_DEFINES___

typedef enum bit{
	NORMAL_MODE,
	DOUBLE_SPEED_MODE
}	usart_u2x;

typedef enum bit{
	MPCM_DISEBLE,
	MPCM_ENABLE
}	usart_mpcm;

typedef enum bit{
	RXEN_DISABLE,
	RXEN_ENABLE
} usart_rxen;

typedef enum bit{
	TXEN_DISABLE,
	TXEN_ENABLE
} usart_txen;

typedef enum bit [2:0]{
	BIT_5,
	BIT_6,
	BIT_7,
	BIT_8,
	RESERVED_1,
	RESERVED_2,
	RESERVED_3,
	BIT_9
} usart_ucsz;

typedef enum bit{
	ASYNCHRONOUS,
	SYNCHRONOUS
}	usart_umsel;

typedef enum bit[1:0]{
	DISABLE,
	RESERVED,
	ENABLE_EVEN,
	ENABLE_ODD
}	usart_upm;

typedef enum bit{
	STOP_1,
	STOP_2
}	usart_usbs;

typedef enum bit{
	POSEDGE,
	NEGEDGE
}	usart_ucpol;

typedef enum bit{
	SLAVE,
	MASTER
} usart_ddr_xcl;

class 	sequence_item;
	rand usart_u2x				u2x;
	rand usart_mpcm				mpcm;
	rand usart_rxen				rxen;
	rand usart_txen				txen;
	rand usart_ucsz				ucsz;
	rand usart_umsel			umsel;
	rand usart_upm 				upm;
	rand usart_usbs				usbs;
	rand usart_ucpol 			ucpol;
	rand bit 			[11:0]	ubrr;
	rand usart_ddr_xcl   		ddr_xcl;
endclass:sequence_item

class base_usart_transaction;
	string name;

	function new();
		name = "base_usart-transaction";
	endfunction : new	
endclass : base_usart_transaction

`endif	//___USART_UVC_DEFINES___


///////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////
`ifndef ___USART_TRANSACTION___
`define ___USART_TRANSACTION___

`define	DATA_AMOUNT  8'h10

class usart_frame extends base_usart_transaction;

	rand usart_u2x				u2x;
	rand usart_mpcm				mpcm;
	rand usart_rxen				rxen;
	rand usart_txen				txen;
	rand usart_ucsz		[2:0]	ucsz;
	rand usart_umsel			umsel;
	rand usart_upm 		[1:0]	upm;
	rand usart_usbs				usbs;
	rand usart_ucpol 			ucpol;
	rand bit 			[11:0]	ubrr;
	rand usart_ddr_xcl   		ddr_xcl;

	rand bit	[7:0]	ucsra;	
	rand bit	[7:0]	ucsrb;
	rand bit	[7:0]	ucsrc;
	rand bit	[7:0]	ubrrh;
	rand bit	[7:0]	ubrrl;
	rand bit			txb8	[0:`DATA_AMOUNT-1];

	rand bit 			o_ddr_xcl;

	bit					start_num;
	rand bit	[4:0]	data_num;
	rand bit			parity_num;

	constraint c_u2x{
		if(u2x == NORMAL_MODE) 			ucsra[1] == 0;
		if(u2x == DOUBLE_SPEED_MODE)	ucsra[1] == 1;
	}
	constraint c_mpcm{
		if(mpcm == MPCM_DISEBLE)	ucsra[0] == 0;
		if(mpcm == MPCM_ENABLE)		ucsra[0] == 1;
	}
	constraint c_rxen{
		if(rxen == RXEN_DISABLE) 	ucsrb[4] == 0;
		if(rxen == RXEN_ENABLE)		ucsrb[4] == 1;
	}
	constraint c_txen{
		if(txen == TXEN_DISABLE) 	ucsrb[3] == 0;
		if(txen == TXEN_ENABLE)		ucsrb[3] == 1;
	}
	constraint c_ucsz{
		if(ucsz == BIT_5)	{ 
								ucsrb[2] == 0;
								ucsrc[2:1] == 2'b00;
								data_num == 5;
							}
		if(ucsz == BIT_6)	{ 
								ucsrb[2] == 0;
								ucsrc[2:1] == 2'b01;
								data_num == 6;
							}
		if(ucsz == BIT_7)	{ 
								ucsrb[2] == 0;
								ucsrc[2:1] == 2'b10;
								data_num == 7;
							}
		if(ucsz == BIT_8)	{ 
								ucsrb[2] == 0;
								ucsrc[2:1] == 2'b11;
								data_num == 8;
							}
		if(ucsz == BIT_9)	{ 
								ucsrb[2] == 1;
								ucsrc[2:1] == 2'b11;
								data_num == 9;
							}
		if(ucsz == RESERVED_1)	{ 
								ucsrb[2] == 1;
								ucsrc[2:1] == 2'b00;
								data_num == 0;
								}
		if(ucsz == RESERVED_2)	{ 
								ucsrb[2] == 1;
								ucsrc[2:1] == 2'b01;
								data_num == 0;
								}
		if(ucsz == RESERVED_3)	{ 
								ucsrb[2] == 1;
								ucsrc[2:1] == 2'b10;
								data_num == 0;
								}	
	}
	constraint c_umsel{
		if( umsel == ASYNCHRONOUS) 	ucsrc[6] == 0;
		if( umsel == SYNCHRONOUS)	ucsrc[6] == 1;
	}
	constraint c_upm{
		if(upm == DISABLE) 		{
									ucsrc[5:4] == 2'b00;
									parity_num == 0;
								}
		if(upm == RESERVED) 	{	
									ucsrc[5:4] == 2'b01;
									parity_num == 0;
								}
		if(upm == ENABLE_EVEN) 	{
									ucsrc[5:4] == 2'b10;
									parity_num == 1;
								}
		if(upm == ENABLE_ODD) 	{
									ucsrc[5:4] == 2'b11;
									parity_num == 1;
								}
	}
	constraint c_usbs{
		if(usbs == STOP_1) 	{
								ucsrc[3] == 0;
							}
		if(usbs == STOP_2)	{
								ucsrc[3] == 1;
							}
	}
	constraint c_ucpol{ 
		if(ucpol == POSEDGE) ucsrc[0] == 0;
		if(ucpol == NEGEDGE) ucsrc[0] == 1;
	}
	constraint c_ddr_xcl{
		if( ddr_xcl == MASTER) o_ddr_xcl == 1;
		if( ddr_xcl == SLAVE)  o_ddr_xcl == 0;
	}
	constraint c_ursel{
		ucsrc[7] == 1;
		ubrrh[7] == 0;
		ubrrh[3:0] == ubrr[11:8];
		ubrrl == ubrr[7:0];
	}

	rand bit	[7:0]	udr_tr		[0:`DATA_AMOUNT - 1];
	rand bit			rxd_data	[0:`DATA_AMOUNT - 1][0:8];
	rand bit			rxd_parity	[0:`DATA_AMOUNT - 1];

	function new();
	endfunction : new
endclass : usart_frame


`endif	//___USART_TRANSACTION___

///////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////
`ifndef ___USART_DRIVER___
`define	___USART_DRIVER___

`define	UDR_ADDR	8'h0
`define	UCSRA_ADDR 	8'h1
`define	UCSRB_ADDR 	8'h2
`define	UCSRC_ADDR 	8'h3
`define	UBRRH_ADDR 	8'h3
`define	UBRRL_ADDR 	8'h4
`define DISABLE_ADDR 8'h5
`define	CLOCK_PERIOD_SLAVE 32'h32

class usart_driver;

	//	Virtual usart interface

	virtual usart_interface.drprt	usart_drv_prt;
	virtual dut_interface 			dut_if;
	virtual inout_interface.drprt  inout_drv_prt;

	//	Mailbox for sending transaction to driver
	mailbox	#(base_usart_transaction) trn_mb;

	//	Semaphore for locking the driver
	semaphore trn_done;

	// USART Transactions
	base_usart_transaction trn;
	usart_frame frm;

	//	Class constructor

	function new(virtual usart_interface.drprt usart_drv_prt, virtual dut_interface dut_if, virtual inout_interface.drprt inout_drv_prt,	mailbox	#(base_usart_transaction)	trn_mb,semaphore trn_done);

		//	Init usart bus
		this.dut_if = dut_if;
		this.usart_drv_prt = usart_drv_prt;
		this.inout_drv_prt = inout_drv_prt;
		this.trn_mb = trn_mb;
		this.trn_done = trn_done;

		//	Run driver
		fork
			this.run_driver();
		join_none
	endfunction : new

	//	Driver task
	task run_driver();
		forever begin
			trn_mb.get(trn);	// Get transaction from mail box (waits for any transaction from transactor in the mailbox)
			if($cast(frm, trn)) begin
				$display("[%d][USART_DRV] DRIVE_FRM_TRN START", $time());
				drive_frm_trn(frm);
				$display("[%d][USART_DRV] DRIVE_FRM_TRN COMPLETE", $time());
			end
			else begin
				$display("[%d][USART_DRV][SIM_ERR] Unknown Transaction in Driver. TypeName: %s", $time(),$typename(trn));
			end
			trn_done.put();		//	Unlock semaphore - driver is ready for next transaction
		end
	endtask : run_driver

	//	Sent new frame to the usart
	task drive_frm_trn( usart_frame frm);
		@(negedge dut_if.clk);
		drive_write(`UCSRA_ADDR,frm.ucsra);
		drive_write(`UCSRC_ADDR,frm.ucsrc);
		drive_write(`UBRRH_ADDR,frm.ubrrh);
		drive_write(`UBRRL_ADDR,frm.ubrrl);
		drive_write(`UCSRB_ADDR,frm.ucsrb);
		usart_drv_prt.DDR_XCl = frm.ddr_xcl;

		inout_drv_prt.rxd = 1;
		repeat(16)
			clock_calc(frm);
		drive_transmit(frm);
	endtask : drive_frm_trn

	//	Write word in usart register
	task drive_write(bit [7:0] addr, bit [7:0] word);
		usart_drv_prt.we = 1;
		usart_drv_prt.addr = addr;
		usart_drv_prt.word_i = word;
		@(negedge dut_if.clk);
		usart_drv_prt.we = 0;
		usart_drv_prt.addr = `DISABLE_ADDR;
	endtask:drive_write

	//	Read word from usart register
	task drive_read;
	input	bit [7:0] addr;
	output	bit [7:0] word;
	begin
		usart_drv_prt.we = 0;
		usart_drv_prt.addr = addr;
		@(negedge dut_if.clk);

		word = usart_drv_prt.word_o;
		usart_drv_prt.addr = `DISABLE_ADDR;
	end
	endtask

	//	Count clock
	task clock_calc(usart_frame frm); 
		//	Asynchronous mode 
		if(frm.umsel == ASYNCHRONOUS ) begin
			if(frm.u2x == NORMAL_MODE)
			repeat(16*(frm.ubrr+1)) begin
				@(negedge dut_if.clk);
			end
			if(frm.u2x == DOUBLE_SPEED_MODE)
			repeat(8*(frm.ubrr+1)) begin
				@(negedge dut_if.clk);
			end
		end
		//	Synchronous mode 
		if(frm.umsel == SYNCHRONOUS) begin
			if(frm.ddr_xcl == MASTER) begin
				// repeat(2*frm.ubrr) begin
				@(negedge inout_drv_prt.clk_o);
			end
			if(frm.ddr_xcl == SLAVE)begin
				this.inout_drv_prt.clk_i = 0;
				repeat(`CLOCK_PERIOD_SLAVE/2) begin
					@(negedge dut_if.clk);
				end
				this.inout_drv_prt.clk_i = 1; 
				repeat(`CLOCK_PERIOD_SLAVE/2) begin
					@(negedge dut_if.clk);
				end
			end
		end
	endtask	: clock_calc

	//	drive transmit mode
	task drive_udr_tr( usart_frame frm);
		int i;
		bit [7:0] flag_reg;
		bit	[7:0] word;
		if( !((frm.ucsz == RESERVED_1) ||
			  (frm.ucsz == RESERVED_2) ||
			  (frm.ucsz == RESERVED_3)
			 )) begin
			for(i = 0; i < `DATA_AMOUNT; i++ ) begin
				do begin
					drive_read(`UCSRA_ADDR, flag_reg);
					if(flag_reg[7]&frm.rxen == RXEN_ENABLE)begin
						drive_read(`UDR_ADDR, word);
					end	
					if(flag_reg[5]&(frm.txen == TXEN_ENABLE)) begin
						if(frm.ucsz===BIT_9)
							drive_write(`UCSRB_ADDR, {frm.ucsrb[7:1], frm.txb8[i]});
						drive_write(`UDR_ADDR, frm.udr_tr[i]);
					end
				end while	((!flag_reg[5])|
							 (!flag_reg[7])&(frm.rxen == RXEN_ENABLE)&(frm.txen == TXEN_DISABLE));
			end

			if(frm.txen == TXEN_ENABLE && (frm.data_num !==0)) begin
				// Receiver DISABLE
				if(frm.rxen == RXEN_DISABLE) begin
					drive_read(`UCSRA_ADDR, flag_reg);
					while(!flag_reg[6]) begin
						drive_read(`UCSRA_ADDR, flag_reg);
					end
				end
				//	Reciever ENABLE
				if(frm.rxen == RXEN_ENABLE  )
					repeat(2) begin
						drive_read(`UCSRA_ADDR, flag_reg);
						while(!flag_reg[7]) begin
							drive_read(`UCSRA_ADDR, flag_reg);
						end
						drive_read(`UDR_ADDR, word);
					end
			end		
		end		
	endtask : drive_udr_tr

	//	drive receive mode
	task drive_rxd(usart_frame frm);
		int k;
		int j;

		inout_drv_prt.rxd = 1;
		clock_calc(frm);
		if( !((frm.ucsz == RESERVED_1) ||
			  (frm.ucsz == RESERVED_2) ||
			  (frm.ucsz == RESERVED_3)
			 )) begin
			for(j = 0; j < `DATA_AMOUNT; j++) begin
				inout_drv_prt.rxd = 0;
				clock_calc(frm);
				for(k=0; k<frm.data_num; k++) begin
					inout_drv_prt.rxd = frm.rxd_data[j][k];
					clock_calc(frm);
				end 
				if(frm.parity_num) begin
					inout_drv_prt.rxd = frm.rxd_parity[j];
					clock_calc(frm);
				end 
				if(frm.usbs == STOP_2) begin
					inout_drv_prt.rxd = 1;
					clock_calc(frm);
				end
				inout_drv_prt.rxd = 1;
				clock_calc(frm);	
			end
		end
		clock_calc(frm);
		clock_calc(frm);		
		clock_calc(frm);
	endtask : drive_rxd

	//	update udr register and rxd
	task drive_transmit(usart_frame frm);
		bit [7:0] word;
		fork 
			begin
				$display("[%d][USART_TRN] DRIVE_RXD START", $time());
				drive_rxd(frm);
				$display("[%d][USART_TRN] DRIVE_RXD COMPLETE", $time());
			end
			begin
				$display("[%d][USART_TRN] DRIVE_UDR_TR START", $time());
				drive_udr_tr(frm);
				$display("[%d][USART_TRN] DRIVE_UDR_TR COMPLETE", $time());			
			end
		join
		
		repeat(10)
			clock_calc(frm);
		drive_write(`UCSRB_ADDR,frm.ucsrb&8'b1110_0111);
		drive_read(`UCSRA_ADDR, word);
		if(word[7]&frm.ucsrb[4]) 
			drive_read(`UDR_ADDR, word);
	
	endtask : drive_transmit
endclass : usart_driver 

`endif

///////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////
`ifndef	___USART_TRANSACTOR___
`define	___USART_TRANSACTOR___

class 	usart_transactor;
	//	Virtual usart interface
	virtual usart_interface usart_if;
	virtual dut_interface	dut_if;
	virtual inout_interface inout_if;

	//	Mailbox for senting transactions to driver
	mailbox	#(base_usart_transaction)	trn_mb;

	//	Semaphore for locking the driver
	semaphore	 trn_done;
	usart_driver usart_drv;		//	usart_bus driver

	//	USART Transaction
	usart_frame frm;			//	USART Frame Transaction

	function new( virtual usart_interface usart_if,  virtual dut_interface dut_if,virtual inout_interface inout_if);
		this.usart_if = usart_if;
		this.dut_if = dut_if;
		this.inout_if = inout_if;
		// Create mailbox
		trn_mb = new();
		// Create semaphore
		trn_done = new();
		// Create driver
		usart_drv = new(  usart_if.drprt, dut_if, inout_if.drprt, trn_mb , trn_done);

	endfunction : new

	task display_frm(usart_frame frm);
		case(frm.u2x)
			0:$display("\n[%d][USART_TRN] NORMAL_MODE",$time());
			1:$display("\n[%d][USART_TRN] DOUBLE_SPEED",$time());
		endcase
		case(frm.mpcm)
			0:$display("[%d][USART_TRN] MPCM_DISABLE",$time());
			1:$display("[%d][USART_TRN] MPCM_ENABLE",$time());
		endcase
		case(frm.rxen)
			0:$display("[%d][USART_TRN] RXEN_DISABLE",$time());
			1:$display("[%d][USART_TRN] RXEN_ENABLE",$time());
		endcase
		case(frm.txen)
			0:$display("[%d][USART_TRN] TXEN_DISABLE",$time());
			1:$display("[%d][USART_TRN] TXEN_ENABLE",$time());
		endcase
		case(frm.ucsz)
			3'b000:$display("[%d][USART_TRN] BIT_5",$time());
			3'b001:$display("[%d][USART_TRN] BIT_6",$time());
			3'b010:$display("[%d][USART_TRN] BIT_7",$time());
			3'b011:$display("[%d][USART_TRN] BIT_8",$time());
			3'b100:$display("[%d][USART_TRN] RESERVED_1",$time());
			3'b101:$display("[%d][USART_TRN] RESERVED_2",$time());
			3'b110:$display("[%d][USART_TRN] RESERVED_3",$time());			
			3'b111:$display("[%d][USART_TRN] BIT_9",$time());
		endcase
		case(frm.umsel)
			0:$display("[%d][USART_TRN] ASYNCHRONOUS",$time());
			1:$display("[%d][USART_TRN] SYNCHRONOUS",$time());
		endcase
		case(frm.upm)
			2'b00:$display("[%d][USART_TRN] DISABLE",$time());
			2'b10:$display("[%d][USART_TRN] ENABLE_EVEN",$time());
			2'b11:$display("[%d][USART_TRN] ENABLE_ODD",$time());
		endcase
		case(frm.usbs)
			0:$display("[%d][USART_TRN] STOP_1",$time());
			1:$display("[%d][USART_TRN] STOP_2",$time());
		endcase
		case(frm.ucpol)
			0:$display("[%d][USART_TRN] POSEDGE",$time());
			1:$display("[%d][USART_TRN] NEGEDGE",$time());
		endcase
		case(frm.ddr_xcl)
			0:$display("[%d][USART_TRN] SLAVE\n",$time());
			1:$display("[%d][USART_TRN] MASTER\n",$time());
		endcase
	endtask
	
	task usart_sent( sequence_item 	item );
		$display("[%d][USART_TRN] USART START TEST", $time());
		// Create Transaction
		frm = new();
		assert(frm.randomize() with{
			this.u2x == item.u2x;
			this.mpcm == item.mpcm;
			this.rxen == item.rxen;
			this.txen == item.txen;
			this.ucsz == item.ucsz;
			this.umsel == item.umsel;
			this.upm == item.upm;
			this.usbs == item.usbs;
			this.ucpol == item.ucpol;
			this.ubrr == item.ubrr;
			this.ddr_xcl == item.ddr_xcl;
			});

		display_frm(frm);
		
		trn_mb.put(frm);
		trn_done.get();
		$display("[%d][USART_TRN] USART TEST COMPLETE", $time());
		$display("--------------------------------------------------------------------");
	endtask: usart_sent
endclass : usart_transactor

`endif	//___USART_TRANSACTOR


