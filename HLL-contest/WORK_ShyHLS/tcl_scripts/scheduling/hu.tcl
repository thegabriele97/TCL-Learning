proc hu {hw_units} {

    ############ Priority computation ############

    set node_priority [list]

    foreach node [lreverse [get_sorted_nodes]] {
        set priority_value 1
        foreach child [get_attribute $node children] {
            # Search for the priority of the child
            set index_child [lsearch -index 0 $node_priority $child]
            set child_priority [lindex $node_priority $index_child 1]
            # The priority of the node is the priority of the children + 1
            set curr_node_priority [expr {$child_priority + 1}]
            if {$curr_node_priority > $priority_value} {
                set priority_value $curr_node_priority
            }
        }
        lappend node_priority "$node $priority_value"
    }

    # puts $node_priority

    ############# End priority computation ############

    set nodes [get_sorted_nodes]
    set node_start_time [list]
    set ready [list]
    set functional_unit [get_lib_fus]
    set delay [get_attribute $functional_unit delay]
    set start_time 1
    # puts [get_sorted_nodes]
    while {[llength $nodes] != 0 || [llength $ready] != 0} {

        ################# Fill the ready vector with the nodes that can be scheduled ###########
        foreach node $nodes {
            # puts "node: $node"
            # gets stdin
            set flag "ok"
            # Check if all parents have already been scheduled
            foreach parent [get_attribute $node parents] {
                # puts "parent: $parent"
                # gets stdin
                set index_parent_start [lsearch -index 0 $node_start_time $parent]

                # If you don't find the parent between the scheduled nodes you can't use the current node
                if {$index_parent_start == -1} {
                    set flag "no"
                }
            }
            # puts "flag: $flag"
            # gets stdin
            # puts $nodes
            # gets stdin
            if {$flag eq "ok"} {
                set index_node [lsearch -index 0 $node_priority $node]
                set priority_of_node [lindex $node_priority $index_node 1]
                lappend ready "$node $priority_of_node"
                # puts $ready
                # gets stdin

                # Now I remove the node that I added to the ready list from the nodes list


                if {[llength $nodes] == 1} {
                    set nodes {}
                } else {
                    set index [lsearch $nodes $node]
                    set nodes [lreplace $nodes $index $index]
                }
                # puts "nodes $nodes"
                # gets stdin
            }
        }

        ########### Ordering based on priority #############

        # puts $ready
        # puts [llength $ready]
        # gets stdin
        set swap "true"
        while {$swap eq "true"} {
            set swap "false"
            for {set i 0} {$i < [llength $ready] - 1} {incr i} {
                if {[lindex $ready $i 1] < [lindex $ready [expr {$i + 1}] 1]} {
                    set swap "true"
                    set temp [lindex $ready [expr {$i + 1}]]
                    # puts $temp
                    # gets stdin
                    set ready [lreplace $ready [expr {$i +1}] [expr {$i + 1}] [lindex $ready $i]]
                    set ready [lreplace $ready $i $i $temp]

                    # puts $ready
                    # gets stdin
                }
            }
        }

        # puts "FINE"
        # gets stdin

        ########### Scheduling based on unit's number ###########

        # puts "ready to be scheduled: $ready"
        # gets stdin
        if {[llength $ready] < $hw_units} {

            ### Append to node_start_time ###
            for {set i 0} {$i < [llength $ready]} {incr i} {
                lappend node_start_time "[lindex $ready $i 0] $start_time"
            }

            ## Remove the scheduled node from ready ###

            set max [llength $ready]
            for {set i 0} {$i < $max} {incr i} {
                if {[llength $ready] == 1} {
                    set ready {}
                } else {
                    set ready [lreplace $ready 0 0]
                }
            }
        } else {

            ### Append to node_start_time ###
            for {set i 0} {$i < $hw_units} {incr i} {
                lappend node_start_time "[lindex $ready $i 0] $start_time"
            }

            ## Remove the scheduled node from ready ###

            for {set i 0} {$i < $hw_units} {incr i} {
                if {[llength $ready] == 1} {
                    set ready {}
                } else {
                    set ready [lreplace $ready 0 0]
                }
            }
        }

        # puts "scheduled $node_start_time"
        # puts "ready to be scheduled: $ready"
        # gets stdin



        set start_time [expr {$start_time + $delay}]
    }

    puts $node_start_time
    return [expr {$start_time - 1}]

}