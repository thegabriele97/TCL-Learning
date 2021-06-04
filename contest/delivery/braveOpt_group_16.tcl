proc compute_delay {nodes_op mapping_op parent} {
    set op_delay 0
    foreach node_list $nodes_op {
        if {[lindex $node_list 0] == $parent} {
            set index [lindex $node_list 1]
            set op_delay [lindex $mapping_op $index 1]
            break

        }
    }
    return $op_delay
}



proc compute_area {constraints mapping_op} {
    set area 0
    for {set i 0} {$i < [llength $constraints]} {incr i} {
        set area [expr {$area + ([lindex $constraints $i 1] * [lindex $mapping_op $i 0])}]
    }

    return $area
}

proc compute_latency_from_schedule {schedules mapping_op nodes_op} {
    set latency 0

    foreach schedule $schedules {
        set computed_latency [ expr {[lindex $schedule 1] + [lindex $mapping_op [lindex [lsearch -index 0 -inline $nodes_op [lindex $schedule 0]] 1] 1]}]
        if {$computed_latency > $latency} {
            set latency $computed_latency
        }
    }

    return $latency
}

proc compute_priority {} {
    set priority {}
    set result {}
    foreach node [lreverse [ get_sorted_nodes ]] {

        set max_child_priority 0
        foreach child [get_attribute $node children] {
            set searchr [ lindex $priority [ lsearch -index 0 $priority $child ] ]
            set child_priority [ lindex $searchr 1 ]
            if {$child_priority > $max_child_priority} {
                set max_child_priority $child_priority
            }
        }

        set priority [ lappend priority [list $node [ expr $max_child_priority + 1 ]  [get_attribute $node n_children]] ]
    }

    set priority [lsort -index 1 -integer -decreasing $priority]
    for {set i [lindex $priority 0 1]} {$i >= 1} {incr i -1} {
        set list_equal_priority [lsearch -index 1 -all -inline $priority $i]
        set list_equal_priority [lsort -index 2 -integer -decreasing $list_equal_priority]
        set result [concat $result $list_equal_priority]
    }

    return $result
}

proc change_children_fu {node nodes_op index} {

    set node_index [lsearch -index 0 $nodes_op $node]
    set nodes_op [lreplace $nodes_op $node_index $node_index [list $node $index]]
    set node_base_op [get_attribute $node operation]
    set touched_nodes {}
    set touched_nodes [lappend touched_nodes $node]
    while {1} {
        set min_fan_in 0
        set min_fan_in_node -1

        foreach child [get_attribute $node children] {
            if {[get_attribute $child operation] == $node_base_op} {
                if {($min_fan_in == 0 || [get_attribute $child n_parents] < $min_fan_in) && [lindex [lsearch -index 0 -inline $nodes_op $child] 1] != $index} {
                    set min_fan_in [get_attribute $child n_parents]
                    set min_fan_in_node $child
                }
            }
        }

        if {[get_attribute $node n_children] == 0} {
            break
        }

        if {$min_fan_in_node != -1} {
            set node_index [lsearch -index 0 $nodes_op $min_fan_in_node]
            set nodes_op [lreplace $nodes_op $node_index $node_index [list $min_fan_in_node $index]]
            set node $min_fan_in_node
            set touched_nodes [lappend touched_nodes $node]
        } else {
            set min_fan_in [get_attribute [lindex [get_attribute $node children] 0] n_parents]
            foreach child [get_attribute $node children] {
                if {[get_attribute $child n_parents] <= $min_fan_in} {
                    set min_fan_in [get_attribute $child n_parents]
                    set node $child
                }
            }
        }
        
    }

    return [list $nodes_op $touched_nodes]
}

proc heuristic {constraints used_area area nodes_op priority mapping_op use_mixture} {
    
    set priority_list_to_remove {}

    foreach priority_list $priority {
        
        set node [lindex $priority_list 0]
        
        if {[lsearch $priority_list_to_remove $node] >= 0} {
            continue
        }

        set node_op [get_attribute $node operation]
        set node_op_index [lsearch -index 0 -inline $nodes_op $node]
        set node_index [lindex $node_op_index 1]
        set actual_fu [lindex $mapping_op $node_index 2]
        set node_op_fu [get_lib_fus_from_op $node_op]
        set list_node_fu {}

        foreach fu $node_op_fu {

            set index [lsearch -index 2 $mapping_op $fu]
            if {$index >= 0} {

                set search_result [lsearch -index 1 $list_node_fu [get_attribute $fu delay]]

                if {$search_result >= 0} {
                    set area_new [get_attribute $fu area]
                    set area_old [lindex $list_node_fu $search_result 0]

                    if {$area_new < $area_old} {
                        set list_node_fu [\
                            lreplace $list_node_fu $search_result $search_result [lindex $mapping_op $index] \
                        ]
                    }

                } else {
                    set list_node_fu [lappend list_node_fu [lindex $mapping_op $index]]
                }

            }

        }

        set list_node_fu [lsort -index 1 -integer -decreasing $list_node_fu]
        set index_actual_fu [lsearch -index 2 $list_node_fu $actual_fu]

        if {$index_actual_fu != [expr {[llength $list_node_fu] - 1}]} {
            set index_new_fu [expr {$index_actual_fu + 1}]
            set new_fu [lindex $list_node_fu $index_new_fu]

            if {[expr {$area - ($used_area - [lindex $list_node_fu $index_actual_fu 0] + [lindex $list_node_fu $index_new_fu 0])}] >= 0} {

                set actual_fu $new_fu
                set actual_constraints [lindex $constraints $node_index]

                set skip 1
                if {[expr {[lindex $actual_constraints 1] - 1}] >= 0} {
                    set constraints [lreplace $constraints $node_index $node_index [list [lindex $actual_constraints 0] [expr {[lindex $actual_constraints 1] - 1}]]]
                    set skip 0
                }

                set result_change_children_fu [change_children_fu $node $nodes_op [lsearch $mapping_op $new_fu]]
                set nodes_op [lindex $result_change_children_fu 0]
                set priority_list_to_remove [concat $priority_list_to_remove [lindex $result_change_children_fu 1]]

                set node_op_index [lsearch -index 0 -inline $nodes_op $node]
                set node_index [lindex $node_op_index 1]
                set actual_constraints [lindex $constraints $node_index]
                
                if {$skip == 0} {
                    set constraints [lreplace $constraints $node_index $node_index [list [lindex $actual_constraints 0] [expr {[lindex $actual_constraints 1] + 1}]]]
                    set used_area [expr {$used_area + [lindex $list_node_fu $index_new_fu 0] - [lindex $list_node_fu $index_actual_fu 0]}]
                }

            } elseif {($use_mixture == 1 && [lindex $constraints $node_index 1] == 0) || ($use_mixture == 0 && [lindex $constraints [lsearch $mapping_op $new_fu] 1] > 0)} {
                # [lindex $constraints [lsearch $mapping_op $new_fu] 1] > 0
                # [lindex $constraints $node_index 1] == 0

                set result_change_children_fu [change_children_fu $node $nodes_op [lsearch $mapping_op $new_fu]]
                set nodes_op [lindex $result_change_children_fu 0]
                set priority_list_to_remove [concat $priority_list_to_remove [lindex $result_change_children_fu 1]]
            }
        }
    }

    return [list $constraints $nodes_op $used_area]
}

proc opt_loop {constraints mapping_op nodes_op area priority use_mixture} {
    set result {}
    set min_last_schedule -1
    
    while {1} {

        set result_total [list_mlac_scheduler $constraints $nodes_op $mapping_op $priority]
        set result_new [lindex $result_total 0]
        
        # puts "\n\n-------> result_scheduling $result_new"
        # puts "\n#########> constraints: $constraints"
        # puts "\n*********> nodes_op: $nodes_op"
        # gets stdin

        set latency [compute_latency_from_schedule $result_new $mapping_op $nodes_op]

        if {$min_last_schedule == -1 || $latency < $min_last_schedule} {
            set min_last_schedule $latency
            set result $result_new
        }

        set constraints [lindex $result_total 1]
        set used_area [compute_area $constraints $mapping_op]
        # puts "\nlatency: $latency (vs min $min_last_schedule) - computed area on scheduling: $used_area - constraints: $constraints"
        #gets stdin

        set heuristic_result [heuristic $constraints $used_area $area $nodes_op $priority $mapping_op $use_mixture]
        set constraints_new [lindex $heuristic_result 0]
        set nodes_op_new [lindex $heuristic_result 1]
        set used_area_new [lindex $heuristic_result 2]

        if {$nodes_op == $nodes_op_new} {
            break
        }
        
        set constraints $constraints_new
        set nodes_op $nodes_op_new
        set used_area $used_area_new
    }

    return [list $constraints $nodes_op $used_area $result $min_last_schedule]
}


proc list_mlac_scheduler {constraints nodes_op mapping_op priority} {

    set constraints_l {}
    set result {}

    set v [get_sorted_nodes]
    set u {}
    set l 1

    #
    # Constraints_l is a list made of different pairs <OP, {}>
    # where inside {} we have a list of m different "l"
    # each means that there are m available resources for that OP
    # but it says that each resource is available at a certain l
    # for example {1, 1, 1} means that there are three resource
    # each available at l =1. {5, 8, 3} means that one resource is available
    # from l = 5 and greater, another one from 8 and greater and so on.
    # At each l, the algorithm checks if there is some resource available (curr_l >= l_ith)
    # if yes, it becomes busy with l=curr_l + op_delay
    #
    # {} is big the same as the number of resources specified in constraints.
    # if for some required op in the DFG there is no constraints specified, a pair <OP, {}>
    # will be created ad hoc with the length {} the same as the number of OP in the DFG
    #
    foreach val $constraints {
        set myl {}
        set dummyl {}

        for {set i 0} {$i < [lindex $val 1]} {incr i} {
            set myl [ lappend myl 1 ]
        }

        set constraints_l [lappend constraints_l [ lappend dummyl [lindex $val 0] $myl ]]
    }
    #puts $constraints_l
    #gets stdin

    while {[llength $result] != [llength [get_sorted_nodes]]} {

        # puts "\n\n"
        foreach node $v {

            set ready 1
            foreach parent [get_attribute $node parents] {

                set op [get_attribute $parent operation]

                set op_delay [compute_delay $nodes_op $mapping_op $parent]

                if {[lsearch -index 0 -all -inline $result $parent] < 0} {
                    set ready 0
                    break
                } elseif { $l < [ expr [lindex [lindex [lsearch -index 0 -all -inline $result $parent] 0] 1 ] + $op_delay ]} {
                    set ready 0
                    break
                }
            }

            if {$ready == 0} {
                continue
            }

            #u: list of node to be scheduled
            set u [lappend u $node]

            #v: list of not ready nodes
            set v [lsearch -all -inline -not $v $node]
        }

        # puts "(l=$l)u: $u"
        
        set tmp_u $u
        set u {}
        foreach node_list $priority {
            if {[lsearch -index 0 -all -inline $tmp_u [lindex $node_list 0]] >= 0} {
                #set tmp_prio [lsearch -all -inline -not $tmp_prio $node_list]
                set u [lappend u [lindex $node_list 0]]
            }

            if {[llength $u] == [llength $tmp_u]} {
                break
            }
        }
        
        # puts "(l=$l)u: $u"
        # gets stdin
        
        foreach node $u {
            set dummyl {}

            set op [get_attribute $node operation]
            set op_delay [compute_delay $nodes_op $mapping_op $node]

            set op_name [lindex $constraints [lindex [lsearch -index 0 -inline $nodes_op $node] 1] 0]
            # contains the index of the operation in constraints_l
            set opidx [lsearch -index 0 $constraints_l $op_name]
            set l_list [lindex [lindex $constraints_l $opidx ] 1]

            # puts "looking for $node ($op): $op_delay"

            for {set i 0} {$i < [llength $l_list]} {incr i} {
                set dummyl {}

                if { $l >= [ lindex $l_list $i ]} {
                    set l_list [ lreplace $l_list $i $i [ expr $l + $op_delay ] ]
                    set result [ lappend result [ lappend dummyl $node $l ] ]
                    set u [ lsearch -all -inline -not $u $node ]

                    # puts "  result: $result"
                    break
                }
            }

            set dummyl {}
            set constraints_l [ lreplace $constraints_l $opidx $opidx [ lappend dummyl $op_name $l_list ] ]
            # puts "  constraints_l: $constraints_l"
        }

        incr l
        # gets stdin
    }

    set used_unit_count {}
    foreach constraint_l $constraints_l {
        set list_op_end_time [lindex $constraint_l 1]
        set cnt 0
        for {set i [expr {[llength $list_op_end_time] - 1}]} {$i >= 0} {incr i -1} {
            if {[lindex $list_op_end_time $i] > 1} {
                break
            }
            incr cnt
        }
        set used_unit_count [lappend used_unit_count [list [lindex $constraint_l 0] [expr {[llength $list_op_end_time] - $cnt}]]]
    }

    return [list $result $used_unit_count]
}


proc start area {
    set constraints {}
    set nodes_op {}
    set mapping_op {}
    set node_fu_id {}
    set fu_id_allocated {}
    set op_number {}
    set tot_area 0
    set priority [compute_priority]
    foreach node [get_nodes] {
        set node_op [get_attribute $node operation]
        if {[lsearch -index 0 $constraints "${node_op}0"] < 0} {
            set min_area [get_attribute [lindex [get_lib_fus_from_op $node_op] 0] area]
            set op_number [lappend op_number [list [get_attribute $node operation] 1]]
            set i 0
            set min_index [expr {[llength $constraints] }]
            foreach op [get_lib_fus_from_op $node_op] {
                set area2 [get_attribute $op area]
                set id [get_attribute $op id]
                set delay [get_attribute $op delay]
                set operation [get_attribute $op operation]
                set constraints [lappend constraints [list "${operation}$i" 0]]
                set mapping_op [lappend mapping_op [list $area2 $delay $id]]
                if {$area2 < $min_area} {
                    set min_index [expr {[llength $constraints] - 1}]
                    set min_area $area2
                }
                incr i
            }
            set constraints [lreplace $constraints $min_index $min_index [list [lindex $constraints $min_index 0] 1]]
            set tot_area [expr {$tot_area + $min_area}]
            set nodes_op [lappend nodes_op [list $node $min_index] ]
        } else {
            set op_number_index [lsearch -index 0 $op_number [get_attribute $node operation]]
            set op_number_of_element [lindex $op_number $op_number_index 1]
            set op_number_of_element [expr {$op_number_of_element + 1}]
            set op_number [lreplace $op_number $op_number_index $op_number_index [list [get_attribute $node operation] $op_number_of_element]]
            foreach node_list $nodes_op {
                if {[get_attribute [lindex $node_list 0]  operation] == $node_op} {
                    set nodes_op [lappend nodes_op [list $node [lindex $node_list 1]] ]
                    break
                }
            }
        }
    }

    # check if the area given is feasible
    if { $area < $tot_area } {
        return [list {} {} {}]
    }

    # puts "constraints $constraints"
    # puts ""
    # puts "> mapping_op $mapping_op"
    # puts ""
    # puts "> nodes_op $nodes_op"
    # puts ""
    
    # puts "area: $tot_area"
    # puts "op_number $op_number"
    # gets stdin

    set obtained_latency -1
    set best_latency_idx 0
    set all_results {}
    for {set i 0} { $i < 1 } { incr i } {

        # puts "\n\n\n\t\t ################### >> LOOPING WITH MIXTURE: $i << ###################\n\n\n" 
    
        set result_opt_loop [opt_loop $constraints $mapping_op $nodes_op $area $priority $i]
        
        if {$obtained_latency == -1 || [lindex $result_opt_loop 4] < $obtained_latency} {
            set obtained_latency [lindex $result_opt_loop 4]
            set best_latency_idx $i
        }

        set all_results [lappend all_results $result_opt_loop]
    }


    set constraints [lindex $all_results $best_latency_idx 0] 
    set nodes_op [lindex $all_results $best_latency_idx 1] 
    set used_area [lindex $all_results $best_latency_idx 2] 
    set result [lindex $all_results $best_latency_idx 3] 

    # puts "Best result with best_latency_idx $best_latency_idx ([lindex $all_results $best_latency_idx 4])"


    set biggest_area -1
    foreach mapping $mapping_op {
        if {[lindex $mapping 0] > $biggest_area} {
            set biggest_area [lindex $mapping 0]
        }
    }
    

    set starting_idx 0
    set constraints_lut {}
    set best_latency [lindex $all_results $best_latency_idx 4]
    set best_constraints {}
    set best_result {}
    set best_used_area {}
    set loop_cnt 0
    while {$starting_idx < [llength $constraints]} {

        if {[lindex $constraints $starting_idx 1] == 0} {
            incr starting_idx
            continue
        }

        # puts "\n\n\n\t ################### >> OPT LOOP #$starting_idx << ###################\n\n" 

        set loop_constraints [concat [lrange $constraints $starting_idx end] [lrange $constraints 0 [expr {$starting_idx -1}]]]

        # puts "working on: $loop_constraints"
        # gets stdin

        set last_constraints {}
        set working_constraints $constraints
        set working_used_area $used_area

        while {1} {

            for {set i 0} {$i < [llength $loop_constraints]} {incr i} {

                incr loop_cnt

                if {[lindex $loop_constraints $i 1] == 0} {
                    continue
                }

                set idx [lsearch -index 0 $working_constraints [lindex $loop_constraints $i 0]]

                set multiplier 1
                if { [ expr { $working_used_area + 10*$biggest_area } ] < $area } {
                    set multiplier 2
                }

                if {[expr {$area - $working_used_area - $multiplier * [lindex $mapping_op $idx 0]}] >= 0} {
                    
                    set working_constraints [\
                        lreplace $working_constraints $idx $idx [\
                            list [lindex $working_constraints $idx 0] [expr { [lindex $working_constraints $idx 1] + $multiplier }] \
                        ]\
                    ]

                    set working_used_area [expr {$working_used_area + $multiplier * [lindex $mapping_op $idx 0]}]
                }

            }
    
            if {$last_constraints == $working_constraints} {
                break
            }

            set last_constraints $working_constraints

            # set result_total [list_mlac_scheduler $working_constraints $nodes_op $mapping_op $priority]
            # set lut_result -1

            set lut_result [lsearch -index 2 -inline $constraints_lut $last_constraints ]

            if {$lut_result < 0} {
                set result_total [list_mlac_scheduler $working_constraints $nodes_op $mapping_op $priority]
                set constraints_lut [lappend constraints_lut [list [lindex $result_total 0] [lindex $result_total 1] $working_constraints ]]
            } else {
                set result_total [lrange $lut_result 0 1]
            }

            set working_constraints [lindex $result_total 1]

            # puts "\n\n>> So the used area is: - (computed is [compute_area $working_constraints $mapping_op])"
            # puts "output constraints: $working_constraints"
            set working_result [lindex $result_total 0]


            set working_used_area [compute_area $working_constraints $mapping_op]
            # puts "new area now is > $working_used_area"
            # gets stdin

            # puts -nonewline "\tarea: $working_used_area"
            # puts -nonewline "\tlatency: [compute_latency_from_schedule [lindex $result_total 0] $mapping_op $nodes_op]\tbest: $best_latency"
            # if {$lut_result < 0} {
            #     puts ""
            # } else {
            #     puts "\t*"
            # }

            set curr_latency [compute_latency_from_schedule $working_result $mapping_op $nodes_op]
            if {$curr_latency < $best_latency} {
                set best_constraints $working_constraints
                set best_result $working_result
                set best_latency $curr_latency 
                set best_used_area $working_used_area
            } 

        }

        incr starting_idx
    }

    if {$best_latency < [lindex $all_results $best_latency_idx 4]} {
        set constraints $best_constraints
        set result $best_result
        set used_area $best_used_area
    }

    # puts "\n# loops: $loop_cnt"

    # puts "\n\n>> So the used area is: $used_area (computed is [compute_area $constraints $mapping_op])"
    # puts ">> So the final constrains (with mixture $best_latency_idx) are $constraints\n\n"

    foreach node_list $nodes_op {
        set index [lindex $node_list 1]
        set fu_id [lindex $mapping_op $index 2]
        set node_fu_id [lappend node_fu_id [list [lindex $node_list 0] $fu_id]]
    }

    set i 0
    foreach constraint $constraints {
        set fu_id_allocated [lappend fu_id_allocated [list [lindex $mapping_op $i 2] [lindex $constraint 1]]]
        incr i
    }

    return [list $result $node_fu_id $fu_id_allocated]
}

proc brave_opt args {
    array set options {-total_area 0}
    if { [llength $args] != 2 } {
        return -code error "Use brave_opt with -total_area $area_value$"
    }
    foreach {opt val} $args {
        if {![info exist options($opt)]} {
            return -code error "unknown option "$opt""
        }
        set options($opt) $val
    }
    set total_area $options(-total_area)

    #################################
    ### INSERT YOUR COMMANDS HERE ###
    set result [start $total_area]
    #################################

    return $result
}
