ncvlog -work worklib design/FIFO.v 
ncvlog -work worklib design/FSM_receiver.v
ncvlog -work worklib design/FSM_transmitter.v 
ncvlog -work worklib design/clock_generator.v 
ncvlog -work worklib design/data_path_receiver.v 
ncvlog -work worklib design/data_path_transmitter.v
ncvlog -work worklib design/receiver
ncvlog -work worklib design/registers.v 
ncvlog -work worklib design/transmitter.v 
ncvlog -work worklib design/usart_top.v  

ncvlog -work worklib verification/usart_testbench.sv -sv -incdir verification/
ncvlog -work worklib verification/dut_top.sv -sv -incdir verification/
ncvlog -work worklib verification/enviroment.sv -sv -incdir verification/

ncelab -work worklib worklib.usart_testbench 
ncsim  -svseed 5 worklib.usart_testbench:module 

rm *.log *.key .*.dd .*.bak *.diag .*.err



