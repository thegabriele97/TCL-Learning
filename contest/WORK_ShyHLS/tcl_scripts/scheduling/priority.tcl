proc priority {} {
    set node_priority [list]
   
    foreach node [lreverse [get_sorted_nodes]] {
        gets stdin
        puts "node: $node"
        set priority_value 1
        foreach child [get_attribute $node children] {
            gets stdin
            puts "child: $child"
            # Search for the priority of the child
            set index_child [lsearch -index 0 $node_priority $child]
            set child_priority [lindex $node_priority $index_child 1]
            puts "child priority: $child_priority"
            # The priority of the node is the priority of the children + 1
            set curr_node_priority [expr {$child_priority + 1}]
            if {$curr_node_priority > $priority_value} {
                set priority_value $curr_node_priority
            }
        }
        gets stdin
        puts "value: $priority_value"
        lappend node_priority "$node $priority_value"
        puts $node_priority
    }
}