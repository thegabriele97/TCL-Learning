proc alap {lambda} {

    # This is the output
    set node_start_time [list]
    foreach node [lreverse [get_sorted_nodes]] {
        set start_time $lambda
        # Here I obtain the delay of the operation of the current node
        set node_op [get_attribute $node operation]
        set fu [get_lib_fu_from_op $node_op]
        set node_delay [get_attribute $fu delay]
        
        # Now I need to find the child that start first
        foreach child [get_attribute $node children] {

            set idx_child_start [lsearch -index 0 $node_start_time $child]
            set child_start_time [lindex [lindex $node_start_time $idx_child_start] 1]
            
            set curr_node_start_time [expr $child_start_time - $node_delay]
            if {$curr_node_start_time < $start_time} {
                set start_time $curr_node_start_time
            }
        }
        if {$start_time == $lambda} {
            set start_time [expr $start_time - $node_delay]
        }
        lappend node_start_time "$node $start_time"
    }

    return $node_start_time

}