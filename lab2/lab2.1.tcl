source ./tcl_scripts/setenv.tcl

puts -nonewline "File name for ./data/DFGs/*.dot: "
flush stdout
gets stdin filename

read_design ./data/DFGs/${filename}.dot
read_library ./data/RTL_libraries/RTL_lib_1.txt

source ./alap.tcl

set result [alap 31] 

#puts $result
foreach schedule $result {
    puts -nonewline "\{[get_attribute [lindex $schedule 0] label] [lindex $schedule 1]\} "
}

puts ""

#print_dfg ./data/out/fir.dot
print_scheduled_dfg $result ./data/out/${filename}_scheduled_alap.dot