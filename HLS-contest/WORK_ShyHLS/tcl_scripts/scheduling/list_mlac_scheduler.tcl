proc hu {input_list} {

    set nodes [get_sorted_nodes]
    set fus [get_lib_fus]
    set node_start_time [list]

    foreach fu $fus {
        set fu_operation [get_attribute $fu operation]
        foreach node $nodes {
            set node_operation [get_attribute $node operation]
            if {$node_operation eq $fu_operation} {
                set flag "ok"
                foreach parent [get_attribute $node parents] {
                    # puts "parent: $parent"
                    # gets stdin
                    set index_parent_start [lsearch -index 0 $node_start_time $parent]

                    # If you don't find the parent between the scheduled nodes you can't use the current node
                    if {$index_parent_start == -1} {
                        set flag "no"
                    } else { # If you find it you need to check if the scheduling time + delay is greater than current scheduling time
                        set parent_start_time [lindex $node_start_time $index_parent_start 1]
                        set delay [get_attribute $fu delay]
                        set parent_end_time [expr {$parent_start_time + $delay}]
                        if {$parent_end_time > $start_time} { ## If the parent_end_time in greater than the start time, it means that the parent has not finished yet
                            set flag "no"
                        }
                    }
                }
                ## Salva i nodi che sono ok nella lista relativa alla functional unit

                ## Pensa a dove mettere la lista relativa alle functional unit


            }
        }
    }
}