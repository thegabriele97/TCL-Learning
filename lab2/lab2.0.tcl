source ./tcl_scripts/setenv.tcl

puts -nonewline "File name for ./data/DFGs/*.dot: "
flush stdout
gets stdin filename

read_design ./data/DFGs/${filename}.dot
read_library ./data/RTL_libraries/RTL_lib_1.txt

proc asap {} {

    set result {}
    set index 0

    foreach node [get_sorted_nodes] {

        set pres {}
        if {[ get_attribute $node n_parents ] == 0} {
            set result [lappend result [lappend pres $node 1]]
        } else {
            set parents [get_attribute $node parents]
            
            set end_time 1
            foreach parent $parents {
                
                # getting the parent delay. Useful to know when it should finish knowing the starting time
                set op_delay [get_attribute [get_lib_fu_from_op [get_attribute $parent operation]] delay]
                
                # now searching for the scheduled parent in order to retrieve its starting time
                foreach sched_node $result {
                    if {$parent eq [lindex $sched_node 0]} {

                        # scheduled parent found, retrieving its end time = starting time + op_delay
                        set parent_endtime [ expr [lindex $sched_node 1] + $op_delay ]

                        # we need to take the slowest parent (higher end time)
                        # in order to know when to start its child (current node)
                        if {$parent_endtime > $end_time} {
                            set end_time $parent_endtime
                        }

                        break
                    }
                }
            }

            set result [lappend result [lappend pres $node [ expr $end_time ]]]

        }

        #puts $result
        
        #if {$index == 25} {
        #    break
        #}
        
        incr index
    }

    return $result
}

set result [asap]

#puts $result
foreach schedule $result {
    puts -nonewline "\{[get_attribute [lindex $schedule 0] label] [lindex $schedule 1]\} "
}

puts ""

print_dfg ./data/out/fir.dot
print_scheduled_dfg $result ./data/out/${filename}_scheduled_asap.dot