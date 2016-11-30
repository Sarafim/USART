`include "interface.svh"
`include "usart_mon.svh"
`include "usart_uvc.svh"
/***************************/

`ifndef	___CHECKER_SVH___
`define ___CHECKER_SVH___

class checker;

	mailbox #(base_usart_transaction) in_chk_mb;
	
	base_usart_transaction	mon_frm;
	
	mon_usart_rxb	usart_rxb 	[integer];
	mon_usart_txb	usart_txb 	[integer];
	mon_out_rxb		out_rxb		[integer];
	mon_out_txb		out_txb		[integer];

	integer i,j,k,l;

	integer error_count;
	integer cov_edge;
	function new(mailbox #(base_usart_transaction) in_chk_mb);
		this.in_chk_mb = in_chk_mb;
		this.i=0;
		this.j=0;
		this.k=0;
		this.l=0;
		this.error_count = 0;

		this.cov_edge = 0;
		fork
			this.check();
		join_none
	endfunction:new

	task check();
		forever begin
			cov_edge=in_chk_mb.num();
			in_chk_mb.get(mon_frm);
			if($cast(usart_rxb[i],mon_frm))
				i+=1;
			if($cast(usart_txb[j],mon_frm)) 
				j+=1;
			if($cast(out_rxb[k],mon_frm)) 
				k+=1;
			if($cast(out_txb[l],mon_frm)) 
				l+=1;
		end
	endtask:check

	function void final_error();
		integer m;
		if(j===l) begin
			$display("[%d] [CHK] DATA AMOUNT IN TX_LINE %d", $time(),j);
			for(m = 0;m < j;m += 1) begin
				if(	usart_txb[m].txb !== out_txb[m].txb ||
					usart_txb[m].txb8 !== out_txb[m].txb8) begin
					$display("---- error in %d transaction ", m);
					$display("---- usart_txb.txb  = %b, out_txb.txb  = %b  ", usart_txb[m].txb,out_txb[m].txb);
					$display("---- usart_txb.txb8 = %b, out_txb.txb8 = %b  ", usart_txb[m].txb8,out_txb[m].txb8);
					error_count += 1;
				end
			end
		end
		else begin
			$display("[%d] [CHK] ERROR IN TX_LINE ", $time());
			$display("---- [CHK] DATA IN BUS	 %d ", j);
			$display("---- [CHK] DATA IN TX_LINE %d ", l);
			error_count += 1;
		end

		if(i===k) begin
			$display("[%d] [CHK] DATA AMOUNT RX_LINE %d", $time(),k);	
			for(m = 0;m < i;m += 1) begin
				if(	usart_rxb[m].rxb !== out_rxb[m].rxb||
					usart_rxb[m].rxb8 !== out_rxb[m].rxb8 ) begin
					$display("---- error in %d transaction ", m);
					$display("---- usart_rxb.rxb  = %b, out_rxb.rxb  = %b  ", usart_rxb[m].rxb,out_rxb[m].rxb);
					$display("---- usart_rxb.rxb8 = %b, out_rxb.rxb8 = %b  ", usart_rxb[m].rxb8,out_rxb[m].rxb8);
					error_count += 1;
				end
			end
		end
		else begin
			$display("[%d] [CHK] ERROR IN RX_LINE ", $time());
			$display("---- [CHK] DATA IN BUS	 %d ", i);
			$display("---- [CHK] DATA IN RX_LINE %d ", k);
			error_count += 1;
		end	

		$display("[%d] [CHK] ERROR_COUNT = %d ", $time(),error_count);
		if(error_count === 0) 
			$display("[%d] [CHK] SIMULATION WAS SUCCESSFUL ", $time());
		else
			$display("[%d] [CHK] TOO MANY ERRORS ", $time());
		
			

	endfunction:final_error

endclass:checker
`endif //__CHECKER__SVH__
