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
