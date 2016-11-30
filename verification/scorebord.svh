`ifndef	___SCOREBOARD_SVH___
`define ___SCOREBOARD_SVH___

`include "interface.svh"
`include "usart_mon.svh"
`include "checker.svh"


class scoreboard;
	virtual usart_interface usart_if;
	virtual inout_interface inout_if;
	virtual dut_interface dut_if;

	usart_monitor 	usart_mon;								//	usart monitor for output signals
	
	mailbox #(base_usart_transaction)		usart_txb_mb;	//	usart mailbox for output signals
	mailbox #(base_usart_transaction)		usart_rxb_mb;	
	mailbox #(base_usart_transaction)		out_txb_mb;		
	mailbox #(base_usart_transaction)		out_rxb_mb;		

	//	usart Transaction
	base_usart_transaction		mon_frm;

	mon_usart_txb 			usart_txb;				
	mon_usart_rxb 			usart_rxb;
	mon_out_rxb				out_rxb;
	mon_out_txb				out_txb;
	
	// Check rule
	static bit chk_enabled;
	mailbox #(base_usart_transaction) in_chk_mb;
	checker usart_chk;

	//	class constructor
	function new( virtual usart_interface usart_if,  virtual dut_interface dut_if, virtual inout_interface inout_if);
		this.usart_if = usart_if;
		this.inout_if = inout_if;
		this.dut_if = dut_if;

		usart_txb_mb = new();
		usart_rxb_mb = new();
		out_txb_mb = new();
		out_rxb_mb = new();
		usart_mon = new(usart_if, inout_if, dut_if,usart_txb_mb, usart_rxb_mb, out_txb_mb, out_rxb_mb);

		chk_enabled = 1;
		in_chk_mb = new();
		usart_chk = new(in_chk_mb);

	// Runscoreboard task
		fork
			this.transaction_filter();
		join_none
	endfunction : new

	task transaction_filter();
		fork
			//	usart OUTPUT Transaction
			forever	begin
				usart_txb_mb.get(mon_frm);	//	Get usart Transaction
				// Filter by its type
				if($cast(usart_txb,mon_frm))begin
					usart_txb = new();
					$cast(usart_txb, mon_frm);
					in_chk_mb.put(usart_txb);
				end	
			end

			forever	begin
				usart_rxb_mb.get(mon_frm);	//	Get usart Transaction
				// Filter by its type
				if($cast(usart_rxb,mon_frm))begin
					usart_rxb = new();
					$cast(usart_rxb, mon_frm);
					in_chk_mb.put(usart_rxb);
				end	
			end

			forever	begin
				out_rxb_mb.get(mon_frm);	//	Get usart Transaction
				// Filter by its type
				if($cast(out_rxb,mon_frm))begin
					out_rxb = new();
					$cast(out_rxb, mon_frm);
					in_chk_mb.put(out_rxb);
				end	
			end

			forever	begin
				out_txb_mb.get(mon_frm);	//	Get usart Transaction
				// Filter by its type
				if($cast(out_txb,mon_frm))begin
					out_txb = new();
					$cast(out_txb, mon_frm);
					in_chk_mb.put(out_txb);
				end	
			end
		join_none	
	endtask : transaction_filter


	function void report_final_status();	
		$display("=======================================================");
		$display("[%d] [SEQ] FINAL REPORT", $time());
		usart_chk.final_error();
	endfunction : report_final_status
endclass : scoreboard

`endif	// ___SCOREBOARD_SVH___