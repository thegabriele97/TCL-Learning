source ./tcl_scripts/setenv.tcl

read_design ./data/DFGs/fir.dot
read_library ./data/RTL_libraries/RTL_lib_1.txt

proc alap {lambda} {

    set result {}

    foreach node [ lreverse [get_sorted_nodes] ] {
        set ldummy {}

        set op_delay [ get_attribute [ get_lib_fu_from_op [ get_attribute $node operation ] ] delay ]
        set minval $lambda
        # all nodes with 0 children will be scheduled at the end [$lambda - $op_delay]
        # so this for will be skipped because they have 0 children
        foreach child [ get_attribute $node children ] {
            set searchr [ lindex $result [ lsearch -index 0 $result $child ]]
            set starttime [ lindex $searchr 1 ] 
            if {$starttime < $minval } {
                set minval $starttime
            }
        }

        set result [ lappend result [ lappend ldummy $node [ expr $minval - $op_delay ] ] ]
    }

    return [ lreverse $result ]
}

set result [alap 31] 

#puts $result
foreach schedule $result {
    puts -nonewline "\{[get_attribute [lindex $schedule 0] label] [lindex $schedule 1]\} "
}

puts ""

#print_dfg ./data/out/fir.dot
print_scheduled_dfg $result ./data/out/fir_scheduled_alap.dot