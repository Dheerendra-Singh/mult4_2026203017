# OpenSTA script. Clock period T (ns) defaults to 2.59 (T_min); override with:
#   CLK_PERIOD=10 sta -exit sta/sta.tcl
set lib $::env(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
set T 2.59
if {[info exists ::env(CLK_PERIOD)]} { set T $::env(CLK_PERIOD) }

read_liberty $lib
read_verilog synth/mult_array_netlist.v
link_design mult_array

create_clock -name clk -period $T [get_ports clk]
set_input_delay  1.0 -clock clk [delete_from_list [all_inputs] [get_ports clk]]
set_output_delay 1.0 -clock clk [all_outputs]

report_worst_slack -max
report_checks -path_delay max -digits 3 > sta/mult_array_timing.rpt
