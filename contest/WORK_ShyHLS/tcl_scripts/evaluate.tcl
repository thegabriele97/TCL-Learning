source ./tcl_scripts/setenv.tcl
source ./tcl_scripts/braveOpt.tcl


proc validate_solution {result} {
    # save the scheduled nodes
    set node_list [lindex $result 0]
    foreach node_pair $node_list {
        set node [lindex $node_pair 0]
        set node_start_time [lindex $node_pair 1]
        set min_child_start_time -1
        foreach child [ get_attribute $node children ] {
            set child_start_time [ lindex [ lsearch -index 0 -inline $node_list $child ] 1]
            # get min starting time of child nodes
            if { ($min_child_start_time == -1) || ($child_start_time < $min_child_start_time) } {
                set min_child_start_time $child_start_time
            }
        }

        if {$min_child_start_time > 0} {
            set node_fu_unit [lindex [ lsearch -index 0 -inline [lindex $result 1] $node ] 1 ]
            set delay_node [get_attribute $node_fu_unit delay]
            # check that the output of the node is generated before the start of the
            # first child (first in time)
            if {$delay_node + $node_start_time > $min_child_start_time} {
                return 1
            }
        }
    }
    return 0
}
# puts -nonewline "File name for ./data/DFGs/*.dot: "
# flush stdout
# gets stdin filename

proc asap {} {

    # This is the output
    set node_start_time [list]

    foreach node [get_sorted_nodes] {
        set start_time 1
        foreach parent [get_attribute $node parents] {

            # end time of the parent = start time of the parent + delay of the parent


            # Here I get the delay of the parent
            set parent_op [get_attribute $parent operation]
            set fu [get_lib_fu_from_op $parent_op]
            set parent_delay [get_attribute $fu delay]


            # Here I get the start time of the parent

            # In order to do it I search in the list node_start_time. Also if this list is the output
            # I'm sure I will find my data because I'm iterating in topological order
            set idx_parent_start [lsearch -index 0 $node_start_time $parent]
            # Con l'istruzione -index 0 cerco il valore che sta sulla colonna 0. Il comando mi ritorna l'indice della colonna a cui si trova il dato $parent
            set parent_start_time [lindex [lindex $node_start_time $idx_parent_start] 1]


            # Qua stai calcolando il massimo
            set curr_node_start_time [expr $parent_start_time + $parent_delay]
            if { $curr_node_start_time > $start_time } {
                set start_time $curr_node_start_time
            }
        }
        lappend node_start_time "$node $start_time"
    }
    return $node_start_time
}


proc compute_latency_min {result} {
    set node_start_time [asap]
    set last_node [lindex $node_start_time end 0]
    set op [get_attribute $last_node operation]
    set fu [get_lib_fu_from_op $op]
    set delay [get_attribute $fu delay]
    set last_node_start_time [lindex $node_start_time end 1]
    set latency_min [expr {$delay + $last_node_start_time}]

    return $latency_min
}

proc compute_latency {result} {

    set last_node_starting_time [lindex [lindex $result 0 end] 1]
    set last_node_name [lindex [lindex $result 0 end] 0]
    set op_last_node [lindex [lsearch -index 0 -inline [lindex $result 1] $last_node_name] 1]
    set delay_last_node [get_attribute $op_last_node delay]
    set latency [expr {$last_node_starting_time + $delay_last_node}]

    return $latency
}


set filename "fir"
read_design ./data/DFGs/${filename}.dot
read_library ./data/RTL_libraries/RTL_library_multi-resources.txt

set start [clock millisec]
set result [brave_opt -total_area 1000]
set end [clock millisec]
set time [expr {$end - $start}]
set is_valid [validate_solution $result]

if { $is_valid == 0 } {
    set latency_min [compute_latency_min $result]
    set latency [compute_latency $result]

    set score [expr {100 * (1-($time/(900*1000))) * $latency_min/$latency}]
    puts "score $score"

} else {
    puts "THE SCHEDULED DFG IS WRONG!"
}
