transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+C:/Users/User/Documents/FPGA {C:/Users/User/Documents/FPGA/uart_rx.v}
vlog -vlog01compat -work work +incdir+C:/Users/User/Documents/FPGA {C:/Users/User/Documents/FPGA/uart_tx.v}
vlog -vlog01compat -work work +incdir+C:/Users/User/Documents/FPGA {C:/Users/User/Documents/FPGA/uart_top.v}

