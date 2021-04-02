source ./tcl_scripts/setenv.tcl

puts -nonewline "File name for ./data/DFGs/*.dot: "
flush stdout
#gets stdin filename
set filename "ewf"

read_design ./data/DFGs/${filename}.dot
read_library ./data/RTL_libraries/RTL_lib_1.txt

proc list_malc_scheduler {lambda} {
    source ./alap.tcl

    puts "Executing alap algorithm from lab2.1.tcl.."
    set alap_result [alap $lambda] 
    puts "alap: $alap_result"

    set constraints_l {}
    foreach node [get_nodes] {
        set op [get_attribute $node operation]
        if {[ lsearch -index 0 $constraints_l $op ] < 0} {
            set dummyl {}
            set constraints_l [ lappend constraints_l [ lappend dummyl $op {1} ] ]
        }
    }

    puts "Initial constraints: $constraints_l" 

    set result {}
    set v [get_sorted_nodes]
    set u {}
    set l 1
    while {[ llength $result ] != [ llength [get_nodes] ]} {
        
        foreach node $v {

            set isok 1
            foreach parent [get_attribute $node parents] {
                set op_delay [ get_attribute [get_lib_fu_from_op [ get_attribute $parent operation ]] delay ]

                if {[ lsearch -index 0 $result $parent ] < 0} {
                    set isok 0
                    break
                } elseif {[expr [ lindex [lindex [ lsearch -index 0 -all -inline $result $parent ] 0] 1] + $op_delay ] > $l} {
                    set isok 0
                    break
                }
            }

            if {$isok == 0} {
                continue
            }

            set dummyl {}
            set u [ lappend u [ lappend dummyl $node -1 ] ] 
            set v [ lsearch -all -inline -not $v $node ]
        }

        # u contains now nodes ready to be scheduled as pair <node, slack>
        # where actually the slack is -1 for the new ones, while it's a number
        # for nodes available in u before this iteration
        # however, both are useless now because we need to compute again the new slack
        # because we are in a new iteration with a bigger L
        for {set i 0} {$i < [llength $u]} {incr i} {
            set node [lindex [lindex $u $i] 0]

            set alap_schedule [ lindex [ lindex [ lsearch -index 0 -all -inline $alap_result $node ] 0 ] 1 ]
            set slack [ expr $alap_schedule - $l ]
            
            set dummyl {}
            set u [ lreplace $u $i $i [ lappend dummyl $node $slack ] ]
        }

        # we sort now u, we want nodes with slack=0 first
        # in order to schedule them immediatelly. Then, if there
        # are nodes left with slack > 0 and there are resources 
        # still available, we schedule them
        set u [ lsort -index 1 -increasing -integer $u ]
        puts "(l=$l) u: $u"

        foreach node_slack $u {

            set node [ lindex $node_slack 0 ]
            set slack [ lindex $node_slack 1 ]

            set op [ get_attribute $node operation ]
            set op_delay [ get_attribute [get_lib_fu_from_op $op] delay ]
            set ll [lindex [lindex [ lsearch -index 0 -all -inline $constraints_l $op ] 0] 1]

            puts "\t$node ([get_attribute $node label]) has slack=$slack.."

            # we try to place it if there are available resources
            set placed 0
            for {set i 0} {$i < [llength $ll]} {incr i} {
                if { $l >= [ lindex $ll $i ]} {
                    set ll [ lreplace $ll $i $i [ expr $l + $op_delay ] ]    
                    puts "\tll now is $ll"
                    set placed 1
                    break
                }
            }
        
            if {$slack <= 0} {

                # if slack is 0, means that we have to place it immediately
                # so if there are no resources available (placed==0), we allocate a new one!
                # (if < 0 means that the wanted latency is to low)
                if {$placed == 0} {
                    set ll [ lappend ll [expr $l + $op_delay] ]
                    puts "\tll now is $ll"
                    set placed 1
                }

            }

            if {$placed == 1 } {
                set dummyl {}

                set result [ lappend result [lappend dummyl $node $l ] ]
                set u [ lsearch -all -inline -not -index 0 $u $node ]
            }

            set dummyl {}
            set opidx [ lsearch -index 0 $constraints_l $op ]
            set constraints_l [ lreplace $constraints_l $opidx $opidx [ lappend dummyl $op $ll ] ]

            puts $constraints_l
        }

        incr l
    }

    # the length of resources used is the same
    # of the length of each list inside contraints_l
    # this is because we use constraints_l as a table
    # where we store for each resource the label L 
    # indicating when they are free to be used
    set res_area {}
    foreach cons $constraints_l {
        set dummyl {}
        set res_area [ lappend res_area [lappend dummyl [lindex $cons 0] [llength [lindex $cons 1]] ]]
    }

    set dummyl {}
    return [lappend dummyl $result $res_area]
} 

set list_malc_result [list_malc_scheduler 60]
set schedule [lindex $list_malc_result 0]
set resources [lindex $list_malc_result 1]

foreach pair $schedule {
    set node_id [lindex $pair 0]
    set start_time [lindex $pair 1]
    puts "Node: $node_id starts @ $start_time"
}

foreach pair $resources {
    set op [lindex $pair 0]
    set n_resources [lindex $pair 1]
    puts "Operation: $op #resources: $n_resources"
}


#print_dfg ./data/out/${filename}.dot
print_scheduled_dfg $schedule ./data/out/${filename}_scheduled_list_malc_area.dot