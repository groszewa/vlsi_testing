# Create the library.
if [file exists work] {
    vdel -all
}
vlib work


# Compile the sources.
vlog ./lfsr.v  ./lfsr_tb.v ./bist_controller.v
#../src/cache_tb.v
#vlog +cover -sv ../tb/interfaces.sv ../tb/sequences.sv 
#../tb/sequences.sv ../tb/coverage.sv ../tb/scoreboard.sv ../tb/modules.sv ../tb/tests.sv  ../tb/tb.sv  

# Simulate the design.
#vsim -c top 
vsim -novopt top
run -all
exit
