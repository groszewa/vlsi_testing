# Create the library.
if [file exists work] {
    vdel -all
}
vlib work


# Compile the sources.
vlog ./project.v ./scan_cut.v ./testbench.v ./lfsr.v ./bist_controller_ver3.v ./misr.v
#vlog ./project.v ./scan_cut.v ./testbench.v ./lfsr.v ./bist_controller_ver2.v ./misr.v
#vlog ./lfsr_tb.v ./lfsr.v ./bist_controller_ver2.v ./misr.v
#../src/cache_tb.v
#vlog +cover -sv ../tb/interfaces.sv ../tb/sequences.sv 
#../tb/sequences.sv ../tb/coverage.sv ../tb/scoreboard.sv ../tb/modules.sv ../tb/tests.sv  ../tb/tb.sv  

# Simulate the design.
#vsim -c top 
#vsim -novopt top 
vsim -novopt TOP_ctl
run -all
exit
