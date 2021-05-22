# {{MUL0 1} {ADD2 3} {MUL1 1}}       constraints
# {operazione/indice_del_tipo_di_operazione num_risorse}
# {{OP0 0} {OP1 1} ...allnodes... {}}   nodes_op
# {nodo indice_della_lista_sopra}

# {{MUL0 3} {ADD2 1 1 1}}       constraints_l


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
    # puts "used_area: $area"
    # gets stdin
    return $area
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
        # priority: node_name, #priority, #fanout
    }
    set priority [lsort -index 1 -integer -decreasing $priority]
    for {set i [lindex $priority 0 1]} {$i >= 1} {incr i -1} {
        set list_equal_priority [lsearch -index 1 -all -inline $priority $i]
        set list_equal_priority [lsort -index 2 -integer -decreasing $list_equal_priority]
        set result [concat $result $list_equal_priority]
    }
    # puts "priority: $result"
    # gets stdin
    return $result
}

proc change_children_fu {node nodes_op index} {
    # puts "index: $index"
    # gets stdin
    set node_index [lsearch -index 0 $nodes_op $node]
    set nodes_op [lreplace $nodes_op $node_index $node_index [list $node $index]]
    set node_base_op [get_attribute $node operation]
    set touched_nodes {}
    set touched_nodes [lappend touched_nodes $node]
    while {1} {
        set min_fan_in 0
        set min_fan_in_node -1
        # puts "node: $node [get_attribute $node label]"
        # gets stdin
        foreach child [get_attribute $node children] {
            if {[get_attribute $child operation] == $node_base_op} {
                if {($min_fan_in == 0 || [get_attribute $child n_parents] < $min_fan_in) && [lindex [lsearch -index 0 -inline $nodes_op $child] 1] != $index} {
                    set min_fan_in [get_attribute $child n_parents]
                    set min_fan_in_node $child
                    # puts "min_fan_in_node_inside_if: $min_fan_in_node"
                    # gets stdin
                }
            }
        }

        # puts "min_fan_in_node: $min_fan_in_node"
        # gets stdin

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
        
        #puts "nodes_op: $nodes_op"
        #gets stdin
    }
    
    # puts "nodes_op: $nodes_op"
    # gets stdin
    return [list $nodes_op $touched_nodes]
}

proc heuristic {constraints used_area area nodes_op priority mapping_op} {
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
                set list_node_fu [lappend list_node_fu [lindex $mapping_op $index]]
            }
        }
        set list_node_fu [lsort -index 0 -integer -increasing $list_node_fu]
        # puts "list_node_fu: $list_node_fu"
        # puts "actual_fu: $actual_fu"
        # puts "node: $node [get_attribute $node label]"
        # gets stdin

        set index_actual_fu [lsearch -index 2 $list_node_fu $actual_fu]
        # puts "index_actual_fu: $index_actual_fu"
        # gets stdin
        if {$index_actual_fu != [expr {[llength $list_node_fu] - 1}]} {
            set index_new_fu [expr {$index_actual_fu + 1}]
            set new_fu [lindex $list_node_fu $index_new_fu]
            # puts "used_area: $used_area"
            # puts "area_actual_fu: [lindex $list_node_fu $index_actual_fu 0]"
            # puts "area_new_fu: [lindex $list_node_fu $index_new_fu 0]"
            # puts "remaining_area: [expr {$area - ($used_area - [lindex $list_node_fu $index_actual_fu 0] + [lindex $list_node_fu $index_new_fu 0])}]"

            if {[expr {$area - ($used_area - [lindex $list_node_fu $index_actual_fu 0] + [lindex $list_node_fu $index_new_fu 0])}] >= 0} {
                # puts "constraints: $constraints"
                # gets stdin
                set actual_fu $new_fu
                set actual_constraints [lindex $constraints $node_index]

                set skip 1
                if {[expr {[lindex $actual_constraints 1] - 1}] >= 0} {
                    set constraints [lreplace $constraints $node_index $node_index [list [lindex $actual_constraints 0] [expr {[lindex $actual_constraints 1] - 1}]]]
                    set skip 0
                }

                # puts "constraints: $constraints"
                # gets stdin
                # puts "nodes_op: $nodes_op"
                # gets stdin
                set result_change_children_fu [change_children_fu $node $nodes_op [lsearch $mapping_op $new_fu]]
                set nodes_op [lindex $result_change_children_fu 0]
                set priority_list_to_remove [concat $priority_list_to_remove [lindex $result_change_children_fu 1]]
                # puts "nodes_op: $nodes_op"
                # puts "touched nodes: [lindex $result_change_children_fu 1]"
                # puts "total touched nodes: $priority_list_to_remove"
                # gets stdin
                set node_op_index [lsearch -index 0 -inline $nodes_op $node]
                set node_index [lindex $node_op_index 1]
                set actual_constraints [lindex $constraints $node_index]
                
                if {$skip == 0} {
                    set constraints [lreplace $constraints $node_index $node_index [list [lindex $actual_constraints 0] [expr {[lindex $actual_constraints 1] + 1}]]]
                    set used_area [expr {$used_area + [lindex $list_node_fu $index_new_fu 0] - [lindex $list_node_fu $index_actual_fu 0]}]
                }

                # puts "constraints: $constraints"
                # gets stdin
                # puts "used_area: $used_area"
                # gets stdin
            } elseif {[lindex $constraints $node_index 1] == 0} {
                # [lindex $constraints [lsearch $mapping_op $new_fu] 1] > 0
                set result_change_children_fu [change_children_fu $node $nodes_op [lsearch $mapping_op $new_fu]]
                set nodes_op [lindex $result_change_children_fu 0]
                set priority_list_to_remove [concat $priority_list_to_remove [lindex $result_change_children_fu 1]]
            }
        }
    }

    # puts "new constraints: $constraints"
    # puts "new nodes_op: $nodes_op"
    # gets stdin

    return [list $constraints $nodes_op $used_area]
}


proc list_mlac_scheduler {constraints nodes_op mapping_op} {

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

    #### Ok till here ###

    # foreach node [get_nodes] {

    #     set op [get_attribute $node operation]
    #     set opidx [ lsearch -index 0 $constraints_l $op ]
    #     set l_list [lindex [lindex $constraints_l $opidx ] 1]

    #     if {[ lsearch -index 0 $constraints $op ] < 0} {
    #         set l_list [linsert $l_list end-1 1]
    #     }

    #     set dummyl {}
    #     set constraints_l [ lreplace $constraints_l $opidx $opidx [ lappend dummyl $op $l_list ] ]
    # }

    while {[llength $result] != [llength [get_sorted_nodes]]} {

        # puts "\n\n"
        foreach node $v {

            set ready 1
            foreach parent [get_attribute $node parents] {

                set op [get_attribute $parent operation]
                # set op_delay [get_attribute [get_lib_fu_from_op $op ] delay ]

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
        #gets stdin

        foreach node $u {
            set dummyl {}

            set op [get_attribute $node operation]
            #set op_delay [get_attribute [get_lib_fu_from_op $op ] delay ]
            set op_delay [compute_delay $nodes_op $mapping_op $parent]
            #set opidx [ lsearch -index 0 $constraints_l $op ]

            set op_name [lindex $constraints [lindex [lsearch -index 0 -inline $nodes_op $node] 1] 0]
            # contains the index of the operation in constraints_l
            set opidx [lsearch -index 0 $constraints_l $op_name]
            set l_list [lindex [lindex $constraints_l $opidx ] 1]


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
        #gets stdin
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

    # puts "used_unit_count: $used_unit_count"
    # gets stdin

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

    # Calcolo il totale delle operazioni
    set total_op_number 0
    foreach op $op_number {
        set total_op_number [expr {$total_op_number + [lindex $op 1]}]
    }

    puts $op_number
    set at_least_one 1
    while {$at_least_one == 1} {
        set i 0
        set area_used 0
        set at_least_one 0
        foreach constraint $constraints {
            if {[lindex $constraint 1] > 0} {
                set mapping_op_element [lindex $mapping_op $i]
                set area_op_element [lindex $mapping_op_element 0]
                set functional_unit [lindex $mapping_op_element 2]
                set functional_unit_op [get_attribute $functional_unit operation]
                set functional_unit_op_number [lindex [lsearch -index 0 -inline $op_number $functional_unit_op] 1]
                set num_op_to_add [expr {int(($area - $tot_area) * (double($functional_unit_op_number) / $total_op_number) / $area_op_element)}]

                set alredy_present_fu [lindex $constraints $i 1]
                set num_op_to_add [ expr { min($functional_unit_op_number - $alredy_present_fu, $num_op_to_add ) } ]
                if { $num_op_to_add > 0 } {
                    set at_least_one 1
                    set constraints [lreplace $constraints $i $i [list [lindex $constraints $i 0] [expr {$alredy_present_fu + $num_op_to_add}]]]
                }
                set area_used [expr {$area_used + ($num_op_to_add * $area_op_element)}]
            }
            incr i
        }
        set tot_area [expr {$tot_area + $area_used}]
    }

    # Do I have still memory available? Substitute slow with fast!


    puts "constraints $constraints"
    puts ""
    puts "mapping_op $mapping_op"
    puts ""
    puts "nodes_op $nodes_op"
    puts ""

    #puts "area: $tot_area"
    # puts "op_number $op_number"
    #gets stdin


    set min_last_schedule -1
    while {1} {
        set result_total [list_mlac_scheduler $constraints $nodes_op $mapping_op]
        set result_new [lindex $result_total 0]
        puts "\n\n-------> result_scheduling $result_new"
        puts "\n#########> constraints: $constraints"
        puts "\n*********> nodes_op: $nodes_op"


        ### PROBLEM HERE ######
        # We do the scheduling with constraints 
        # {MUL0 0} {MUL1 7} {MUL2 0} {ADD0 0} {ADD1 7} {ADD2 0} {LOD0 0} {LOD1 7} {LOD2 0} {SUB0 0} {SUB1 2} {SUB2 0} {ASR0 2} {STR0 0} {STR1 2} {STR2 0}
        #
        # And the output after the sharing is
        # {MUL0 0} {MUL1 7} {MUL2 0} {ADD0 0} {ADD1 7} {ADD2 0} {LOD0 0} {LOD1 7} {LOD2 0} {SUB0 0} {SUB1 2} {SUB2 0} {ASR0 2} {STR0 0} {STR1 2} {STR2 0}
        #
        # Now we do another try and we obtain these constraints:
        # {MUL0 4} {MUL1 3} {MUL2 0} {ADD0 1} {ADD1 6} {ADD2 0} {LOD0 0} {LOD1 7} {LOD2 0} {SUB0 0} {SUB1 2} {SUB2 0} {ASR0 2} {STR0 0} {STR1 2} {STR2 0}
        # and we have always 7 MUL as before but 4 are faster
        # Now the result after sharing is
        # {MUL0 4} {MUL1 0} {MUL2 0} {ADD0 1} {ADD1 0} {ADD2 0} {LOD0 0} {LOD1 1} {LOD2 0} {SUB0 0} {SUB1 1} {SUB2 0} {ASR0 1} {STR0 0} {STR1 1} {STR2 0}
        # The slower MUL are never used anymore!!
        #
        # So we are not entirely using our area budget!
        # this is caused by nodes_op, there are no nodes that useses constraints[1]

        set latency 0
        foreach schedule $result_new {
            if {[lindex $schedule 1] > $latency} {
                set latency [lindex $schedule 1]
            }
        }

        if {$min_last_schedule == -1 || $latency < $min_last_schedule} {
            set min_last_schedule $latency
            set result $result_new
        }

        set constraints [lindex $result_total 1]
        set used_area [compute_area $constraints $mapping_op]
        puts "\nlatency: $latency (vs min $min_last_schedule) - computed area on scheduling: $used_area - constraints: $constraints"
        #gets stdin

        set heuristic_result [heuristic $constraints $used_area $area $nodes_op $priority $mapping_op]
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

    puts "\n\n>> So the used area is: $used_area (computed is [compute_area $constraints $mapping_op])"
    puts ">> So the final constrains are $constraints\n\n"

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

    #puts $total_area

    #################################
    ### INSERT YOUR COMMANDS HERE ###
    set result [start $total_area]
    #################################

    return $result
}
