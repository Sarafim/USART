`ifndef	___SEQUENCER_SVH___
`define	___SEQUENCER_SVH___

`include "interface.svh"
`include "usart_uvc.svh"


class sequencer;
	virtual	usart_interface usart_if;
	virtual dut_interface	dut_if;
	virtual	inout_interface	inout_if;


	sequence_item	sq_item;
	usart_transactor usart_xtr;


	integer i;
	function new( virtual usart_interface usart_if, virtual dut_interface dut_if, virtual inout_interface inout_if);
		this.usart_if = usart_if;
		this.inout_if = inout_if;
		this.dut_if = dut_if;
		
		this.i = 0;
		
		sq_item = new();
		usart_xtr = new(usart_if, dut_if,  inout_if);

	endfunction : new


	task 	set_reg( sequence_item regs);
		usart_xtr.usart_sent(regs);
	endtask
	

	task tc_randseq( int unsigned run_count = 30);
		i=1;
		repeat(run_count)begin
			$display("--------------------------------------------------------------------");
			$display("[%d][SEQ ] Test #%d: Random Sequence", $time(),i);
			randsequence( random_test ) 
				random_test : some_rand_seq ;
					some_rand_seq: sent_some_data;
						sent_some_data : {							
											assert(sq_item.randomize() with{
												// this.u2x  == NORMAL_MODE;
												this.mpcm == MPCM_DISEBLE;
												// this.txen == TXEN_ENABLE;
												// this.rxen == RXEN_ENABLE;
												// this.ucsz == BIT_8;
												// this.umsel == ASYNCHRONOUS;
												// this.upm == DISABLE;//DISABLE;//ENABLE_EVEN;
												// this.usbs == STOP_1;
												// this.ddr_xcl == SLAVE;
												// this.ucpol == POSEDGE;
											});

											i+=1;
											set_reg(sq_item);

										}; 
			endsequence
		end
	endtask : tc_randseq 

endclass:	sequencer

`endif	//___SEQUENCER_SVH___


