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

        #puts "\n\n"
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

        #puts "(l=$l)u: $u"
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

                    #puts "  result: $result"
                    break
                }
            }

            set dummyl {}
            set constraints_l [ lreplace $constraints_l $opidx $opidx [ lappend dummyl $op_name $l_list ] ]
            #puts "  constraints: $constraints_l"
        }

        incr l
        ###gets stdin
    }


    return $result
}

proc start area {
    set constraints {}
    set nodes_op {}
    set mapping_op {}
    set node_fu_id {}
    set fu_id_allocated {}
    set op_number {}
    set tot_area 0
    foreach node [get_nodes] {
        set node_op [get_attribute $node operation]
        if {[lsearch -index 0 $constraints "${node_op}0"] < 0} {
            set min_area [get_attribute [lindex [get_lib_fus_from_op $node_op] 0] area]
            set op_number [lappend op_number [list [get_attribute $node operation] 1]]
            set i 0
            set min_index 0
            foreach op [get_lib_fus_from_op $node_op] {
                set area2 [get_attribute $op area]
                set id [get_attribute $op id]
                set delay [get_attribute $op delay]
                set operation [get_attribute $op operation]
                set constraints [lappend constraints [list "${operation}$i" 0]]
                set mapping_op [lappend mapping_op [list $area2 $delay $id]]
                if {$area2 <$min_area} {
                    set min_index [expr {[llength $constraints] -1 }]
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
                if {$num_op_to_add > 0} {
                    set at_least_one 1
                    set constraints [lreplace $constraints $i $i [list [lindex $constraints $i 0] [expr {[lindex $constraints $i 1] + $num_op_to_add}]]]
                }
                set area_used [expr {$area_used + ($num_op_to_add * $area_op_element)}]
            }
            incr i
        }
        set tot_area [expr {$tot_area + $area_used}]
    }


    #TODO: Aggiungere il controllo che se il circuito ha 10 load è inutile metterne 20. Piuttosto si dedicano le risorse ad altro


    puts "constraints $constraints"
    puts "mapping_op $mapping_op"
    #puts "nodes_op $nodes_op"
    #puts "area: $tot_area"
    # puts "op_number $op_number"
    #gets stdin


    set result [list_mlac_scheduler $constraints $nodes_op $mapping_op]
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
