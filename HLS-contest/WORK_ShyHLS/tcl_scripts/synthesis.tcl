source ./tcl_scripts/setenv.tcl
source ./tcl_scripts/scheduling/asap.tcl
source ./tcl_scripts/scheduling/alap.tcl
source ./tcl_scripts/scheduling/alap.tcl
source ./tcl_scripts/scheduling/mobility.tcl
source ./tcl_scripts/scheduling/priority.tcl
source ./tcl_scripts/scheduling/hu.tcl

# read_design ./data/DFGs/fir.dot
# read_library ./data/RTL_libraries/RTL_lib_1.txt

read_design ./data/DFGs/hu_slides.dot
read_library ./data/RTL_libraries/RTL_lib_2.txt

# set asap_schedule [asap]

# puts "ASAP:"
# foreach time_pair $asap_schedule {
#     set node_id [lindex $time_pair 0]
#     set start_time [lindex $time_pair 1]
#     puts "Node $node_id starts @ $start_time"
# }

# print_dfg ./data/out/fir.dot
# print_scheduled_dfg $asap_schedule ./data/out/fir_asap.dot

# set alap_schedule [alap 31]
# puts "ALAP:"
# foreach time_pair $alap_schedule {
#     set node_id [lindex $time_pair 0]
#     set start_time [lindex $time_pair 1]
#     puts "Node $node_id starts @ $start_time"
# }

# print_dfg ./data/out/fir.dot
# print_scheduled_dfg $alap_schedule ./data/out/fir_alap.dot

# set mobility_values [mobility $asap_schedule $alap_schedule]
# puts "Mobility:"
# foreach pair $mobility_values {
#     set node_id [lindex $pair 0]
#     set mob [lindex $pair 1]
#     puts "Node $node_id has mobility $mob"
# }

# set priority_values [priority]
# foreach pair $priority_values {
#     set node_id [lindex $pair 0]
#     set pri [lindex $pair 1]
#     puts "Node $node_id has priority $pri"
# }

set latency [hu 4]
puts "latency: $latency"