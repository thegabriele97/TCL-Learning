source ./tcl_scripts/setenv.tcl

puts -nonewline "File name for ./data/DFGs/*.dot: "
flush stdout
gets stdin filename

read_design ./data/DFGs/${filename}.dot
read_library ./data/RTL_libraries/RTL_lib_1.txt

proc list_mlac_scheduler {constraints} {

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

    foreach node [get_nodes] {
        
        set op [get_attribute $node operation]
        set opidx [ lsearch -index 0 $constraints_l $op ]  
        set l_list [lindex [lindex $constraints_l $opidx ] 1]

        if {[ lsearch -index 0 $constraints $op ] < 0} {
            set l_list [linsert $l_list end-1 1]
        } 

        set dummyl {}
        set constraints_l [ lreplace $constraints_l $opidx $opidx [ lappend dummyl $op $l_list ] ]
    }

    while {[llength $result] != [llength [get_sorted_nodes]]} {
        
        puts "\n\n"
        foreach node $v {

            set ready 1
            foreach parent [get_attribute $node parents] {

                set op [get_attribute $parent operation]
                set op_delay [get_attribute [get_lib_fu_from_op $op ] delay ]

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

            set u [lappend u $node]
            set v [lsearch -all -inline -not $v $node]
        }

        puts "(l=$l)u: $u"

        foreach node $u {
            set dummyl {}

            set op [get_attribute $node operation]
            set op_delay [get_attribute [get_lib_fu_from_op $op ] delay ]
            set opidx [ lsearch -index 0 $constraints_l $op ]  
            set l_list [lindex [lindex $constraints_l $opidx ] 1]

            for {set i 0} {$i < [llength $l_list]} {incr i} {
                set dummyl {}

                if { $l >= [ lindex $l_list $i ]} {
                    set l_list [ lreplace $l_list $i $i [ expr $l + $op_delay ] ]
                    set result [ lappend result [ lappend dummyl $node $l ] ]
                    set u [ lsearch -all -inline -not $u $node ]
                    
                    puts "  result: $result"
                    break
                }
            }

            set dummyl {}
            set constraints_l [ lreplace $constraints_l $opidx $opidx [ lappend dummyl $op $l_list ] ]
            puts "  constraints: $constraints_l"
        }

        incr l
        #gets stdin
    }

    return $result 
}


set res_info {{ADD 2} {MUL 1}}
set list_malc_result [list_mlac_scheduler $res_info]


print_dfg ./data/out/${filename}.dot
print_scheduled_dfg $list_malc_result ./data/out/${filename}_scheduled_list_mlac_area.dot