`include "interface.svh"
`include "usart_uvc.svh"
/***************************/

`ifndef	__USART_MONITOR__
`define __USART_MONITOR__

class mon_usart_txb extends base_usart_transaction;
	bit [7:0] 	txb;
	bit 		txb8;

	function new();
		txb = 0;
		txb8 = 0;
	endfunction : new
endclass : mon_usart_txb

class mon_usart_rxb extends base_usart_transaction;
	bit [7:0] 	rxb;
	bit 		rxb8;

	function new();
		rxb = 0;
		rxb8 = 0;
	endfunction : new
endclass : mon_usart_rxb

class mon_out_rxb extends base_usart_transaction;
	bit [7:0] 	rxb;
	bit 		rxb8;

	function new();
		rxb = 0;
		rxb8 = 0;
	endfunction : new
endclass : mon_out_rxb

class mon_out_txb extends base_usart_transaction;
	bit [7:0] 	txb;
	bit 		txb8;

	function new();
		txb = 0;
		txb8 = 0;
	endfunction : new
endclass : mon_out_txb

class usart_monitor;

	// Virtual Interfaces
	virtual usart_interface.monprt usart_if;
	virtual inout_interface.monprt	inout_if;
	virtual dut_interface			dut_if;

	// Mailbox
	mailbox #(base_usart_transaction)		usart_txb_mb;	//	usart mailbox for output signals
	mailbox #(base_usart_transaction)		usart_rxb_mb;	
	mailbox #(base_usart_transaction)		out_txb_mb;		
	mailbox #(base_usart_transaction)		out_rxb_mb;
	// Monitor Transaction
	mon_usart_rxb	usart_rxb;
	mon_usart_txb	usart_txb;
	mon_out_rxb		out_rxb;
	mon_out_txb		out_txb;

	bit	[7:0]	ucsra;	
	bit	[7:0]	ucsrb;
	bit	[7:0]	ucsrc;
	bit	[7:0]	ubrrh;
	bit	[7:0]	ubrrl;
	bit 		ddr_xcl;
	// Class constructor
	function new(virtual usart_interface.monprt usart_if, virtual inout_interface.monprt inout_if, virtual dut_interface dut_if, mailbox #(base_usart_transaction) usart_txb_mb,mailbox #(base_usart_transaction) usart_rxb_mb, mailbox #(base_usart_transaction) out_txb_mb, mailbox #(base_usart_transaction) out_rxb_mb );
		this.usart_if = usart_if;
		this.inout_if = inout_if;
		this.dut_if = dut_if;

		this.usart_txb_mb = usart_txb_mb;
		this.usart_rxb_mb = usart_rxb_mb;
		this.out_txb_mb = out_txb_mb;
		this.out_rxb_mb = out_rxb_mb;
		// Run monitor
		fork 
			this.run_monitor();
		join_none
	endfunction : new

	task run_monitor();
		while(usart_if.we === 1'bx)	@(posedge dut_if.clk);
		
		forever begin
			fork
				data_collect();
				begin
					repeat(5)
						@(posedge dut_if.clk);
					forever begin
						if( !(	(ucsrb[2] == 1) && (ucsrc[2:1] == 2'b00) ||
								(ucsrb[2] == 1) && (ucsrc[2:1] == 2'b01) ||
								(ucsrb[2] == 1) && (ucsrc[2:1] == 2'b10)
							 )) 
							read_txb();
						else
							@(posedge dut_if.clk);						
					end
				end
				begin
					repeat(5)
						@(posedge dut_if.clk);
					forever begin
						if( !(	(ucsrb[2] == 1) && (ucsrc[2:1] == 2'b00) ||
								(ucsrb[2] == 1) && (ucsrc[2:1] == 2'b01) ||
								(ucsrb[2] == 1) && (ucsrc[2:1] == 2'b10)
						 )) 
							read_rxb();
						else
							@(posedge dut_if.clk);
					end
				end
			join_any
			disable fork;
		end
	endtask: run_monitor
	
	task data_collect();
		bit stop;
		stop = 0;

		monitor_read(`UCSRA_ADDR,ucsra);
		monitor_read(`UCSRC_ADDR,ucsrc);
		monitor_read(`UBRRH_ADDR,ubrrh);
		monitor_read(`UBRRL_ADDR,ubrrl);
		monitor_read(`UCSRB_ADDR,ucsrb);
		ddr_xcl = usart_if.DDR_XCl;
		while(!stop) read_CPU(stop);				// data from CPU
	endtask : data_collect

	task monitor_read;
	input	bit [7:0] addr;
	output  bit [7:0] word;
	begin	
		while(!usart_if.we)
			@(posedge dut_if.clk);

		if(usart_if.addr !== addr) 
			$display("[%d][USART_MON] ERROR, INVALID SETUP", $time());
		else 
			word = usart_if.word_i;
		
		@(posedge dut_if.clk);
	end
	endtask: monitor_read

	task read_CPU;
	output  bit stop;
	begin
		integer num;
		stop = 0;

		if(usart_if.we) begin
			if(usart_if.addr === `UCSRA_ADDR) begin
				stop = 1;
				return;
			end

			usart_txb = new();
			if(usart_if.addr == `UCSRB_ADDR) begin
				usart_txb.txb8 = usart_if.word_i[0];
				@(posedge dut_if.clk);
			end	

			if(usart_if.addr == `UDR_ADDR) begin
				usart_txb.txb = usart_if.word_i;
				case({ucsrb[2],ucsrc[2:1]})					// data bits
					3'b111: usart_txb.txb = usart_if.word_i[7:0];
					3'b011: usart_txb.txb = usart_if.word_i[7:0];
					3'b010:	usart_txb.txb = usart_if.word_i[6:0];
					3'b001: usart_txb.txb = usart_if.word_i[5:0];
					3'b000: usart_txb.txb = usart_if.word_i[4:0];
					default: usart_txb.txb = usart_if.word_i[7:0];
				endcase
				usart_txb_mb.put(usart_txb);
			end
		end
		else begin
			if( !(	(ucsrb[2] == 1) && (ucsrc[2:1] == 2'b00) ||
					(ucsrb[2] == 1) && (ucsrc[2:1] == 2'b01) ||
					(ucsrb[2] == 1) && (ucsrc[2:1] == 2'b10)
				 )) 
			begin			
				usart_rxb = new();
				if(usart_if.addr == `UDR_ADDR) begin
					usart_rxb.rxb8 = usart_testbench.dut.dut.registers_inst1.i_rx8;
					case({ucsrb[2],ucsrc[2:1]})					// data bits
						3'b111: usart_rxb.rxb = usart_if.word_o[7:0];
						3'b011: usart_rxb.rxb = usart_if.word_o[7:0];
						3'b010:	usart_rxb.rxb = usart_if.word_o[6:0];
						3'b001: usart_rxb.rxb = usart_if.word_o[5:0];
						3'b000: usart_rxb.rxb = usart_if.word_o[4:0];
						default: usart_rxb.rxb = usart_if.word_o[7:0];
					endcase
					
					usart_rxb_mb.put(usart_rxb);
				end	
			end
		end		
		@(posedge dut_if.clk);
	end	
	endtask:read_CPU

	task read_rxb();
		
		int k;
		int num;
		bit [7:0] buff;

		out_rxb=new();
		while(inout_if.rxd == 1) begin				// wait for start bit
			clock_calc();
		end	

		clock_calc();
		case({ucsrb[2],ucsrc[2:1]})					// data bits
			3'b111: num=9;
			3'b011:	num=8;
			3'b010:	num=7;
			3'b001: num=6;
			3'b000: num=5;
			default: num=-1;
		endcase
		for(k=0; k<num; k++) begin
			if(k==8)
				out_rxb.rxb8=inout_if.rxd;
			else
				buff[k]=inout_if.rxd;
			clock_calc();
		end 
		out_rxb.rxb = buff;

		if(ucsrb[4])
			out_rxb_mb.put(out_rxb);
		
		if(ucsrc[5])
			clock_calc();								// clock for parity bit 
		if(ucsrc[3])
			clock_calc();								// clock for stop bit 
		clock_calc();

	endtask:read_rxb

	task read_txb();

		int k;
		int num;
		bit [7:0] buff;	

		out_txb = new();
		while(inout_if.txd == 1) begin				// wait for start bit
			clock_calc();
		end	
		clock_calc();
		case({ucsrb[2],ucsrc[2:1]})					// data bits
			3'b111: num=9;
			3'b011:	num=8;
			3'b010:	num=7;
			3'b001: num=6;
			3'b000: num=5;
			default: num=8;
		endcase
			
		for(k=0; k<num; k++) begin
			if(k==8)
				out_txb.txb8=inout_if.txd;
			else
				buff[k]=inout_if.txd;

			clock_calc();
		end 
		out_txb.txb = buff;
		
		if(ucsrb[3])
			out_txb_mb.put(out_txb);
		
		if(ucsrc[5]) 
			clock_calc();
		if(ucsrc[3])
			clock_calc();
		clock_calc();	
	endtask:read_txb

	task clock_calc();
		//	Asynchronous mode 
		if(!ucsrc[6]) begin
			if(!ucsra[1])
			repeat(16*({ubrrh[3:0],ubrrl}+1)) begin
				@(posedge dut_if.clk);
			end
			if(ucsra[1])
			repeat(8*({ubrrh[3:0],ubrrl}+1)) begin
				@(posedge dut_if.clk);
			end
		end
		//	Synchronous mode 
		if(ucsrc[6]) begin
			if(ddr_xcl) 
				@(negedge inout_if.clk_o);
			if(!ddr_xcl)
				@(negedge inout_if.clk_i);
		end
	endtask

endclass : usart_monitor

`endif //__USART_MONITOR__

