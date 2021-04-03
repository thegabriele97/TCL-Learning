
source ./tcl_scripts/setenv.tcl

puts -nonewline "File name for ./data/DFGs/*.dot: "
flush stdout
gets stdin filename
#set filename "fir"

read_design ./data/DFGs/${filename}.dot
read_library ./data/RTL_libraries/RTL_lib_1.txt

proc mobility {} {
    source ./asap.tcl
    source ./alap.tcl

    set result {}

    set asap_schedule [asap]
    set asap_last_schedule [ lindex $asap_schedule end ]
    set asap_last_schedule_node [lindex $asap_last_schedule 0]
    set asap_last_schedule_node_delay [ get_attribute [ get_lib_fu_from_op [ get_attribute $asap_last_schedule_node operation ] ] delay ]
    set asap_last_schedule_time [lindex $asap_last_schedule 1]
    set asap_latency [ expr $asap_last_schedule_node_delay + $asap_last_schedule_time ]

    set alap_schedule [alap $asap_latency]

    foreach node [get_sorted_nodes] {
        set asap_node [lindex [lindex [ lsearch -all -inline -index 0 $asap_schedule $node ] 0] 1]
        set alap_node [lindex [lindex [ lsearch -all -inline -index 0 $alap_schedule $node ] 0] 1]
        
        set dummyl {}
        set result [ lappend result [ lappend dummyl $node [ expr $alap_node - $asap_node ] ] ]
    }

    return $result
}

foreach node_mobility [mobility] {
    puts "Mobility for [lindex $node_mobility 0]:\t[lindex $node_mobility 1]"
}