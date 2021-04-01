source ./tcl_scripts/setenv.tcl

read_design ./data/DFGs/fir.dot

proc hu_scheduler {n_resources} {

    set result {}
    set priority {}

    foreach node [lreverse [ get_sorted_nodes ]] {
        set dummyl {}
        
        set max_child_priority 0
        foreach child [get_attribute $node children] {
            set searchr [ lindex $priority [ lsearch -index 0 $priority $child ] ]
            set child_priority [ lindex $searchr 1 ]
            if {$child_priority > $max_child_priority} {
                set max_child_priority $child_priority
            }
        } 

        set priority [ lappend priority [ lappend dummyl $node [ expr $max_child_priority + 1 ] ] ]
    }
    
    set v [get_sorted_nodes]
    set u {}
    set l 1
    while {[ llength $result ] != [llength [get_sorted_nodes]] } {

        foreach node $v {

            set parents [ get_attribute $node parents ]
            for {set i 0} {$i < [ llength $parents ]} {incr i} {
                if {[lsearch -index 0 $result [ lindex $parents $i ]] < 0} {
                    break
                }
            }

            # checking if the node is ready to be scheduled (i.e. all parents already scheduled)
            if {$i != [ llength $parents ]} {
                continue
            }

            # removing from v the current node
            set v [lsearch -all -inline -not $v $node ]
            
            # adding it to u ready to be scheduled
            set u [lappend u [ lindex [lsearch -all -inline -index 0 $priority $node] 0 ]]
        }

        # sorting u by priority (length of each path)
        set u [lsort -integer -decreasing -index 1 $u ]

        set n_items 0
        foreach nodeready $u {
            
            if {$n_items >= $n_resources} {
                break
            }

            set dummyl {}
            set result [ lappend result [ lappend dummyl [lindex $nodeready 0] $l ] ]
            set u [lsearch -all -inline -not $u $nodeready]
            incr n_items
        
        }

        incr l

    }

    return $result
}

set result [hu_scheduler 3] 

puts $result
#foreach schedule $result {
#    puts -nonewline "\{[get_attribute [lindex $schedule 0] label] [lindex $schedule 1]\} "
#}

puts ""

#print_dfg ./data/out/fir.dot
print_scheduled_dfg $result ./data/out/fir_scheduled_hu.dot