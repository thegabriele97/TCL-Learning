proc max args {
    set res -1
    foreach element [lindex $args 0] {
        if {$element > $res} {set res $element}
    }
    return $res
}

proc print_slacks {} {

	set path_list [get_timing_paths -slack_greater_than -10 -max_paths 2000000]
	foreach_in_collection path $path_list {
		puts "[get_attribute $path slack]"
	}

}

proc set_cell_HVT {cell} {
	set type HVT
	set curr_cell_lib [get_lib_cell -o $cell]
	set curr_cell_lib_name [get_attribute $curr_cell_lib full_name]
	# puts $curr_cell_lib_name
	if { [ regexp {\/(.+)_.+_(.+)} $curr_cell_lib_name full1 name_orig name2_orig ] } {
        if { [get_attribute $curr_cell_lib threshold_voltage_group] != $type } {

          foreach_in_collection alternative [get_alternative_lib_cells [get_cell $cell]] {
            set possible_swap_name [get_attribute $alternative full_name]

            if { [ regexp {\/(.+)_.+_(.+)} $possible_swap_name full nm nm2 ] } {
              if { ($name_orig == $nm) && ($name2_orig == $nm2) && ([get_attribute $alternative threshold_voltage_group] == $type) } {
				
				# puts "set_cell_HVT: found $possible_swap_name from $curr_cell_lib_name"
				size_cell $cell $possible_swap_name
				# set curr_cell_lib [get_lib_cell -o $cell]
				# puts [get_attribute $curr_cell_lib threshold_voltage_group]
				# puts "Replaced $cell -> $curr_cell_lib_name with $possible_swap_name"
              }
            }
          }
        }
    }

	return $cell
}

proc set_cell_LVT {cell} {
	set type LVT
	set curr_cell_lib [get_lib_cell -o $cell]
	set curr_cell_lib_name [get_attribute $curr_cell_lib full_name]
	# puts $curr_cell_lib_name
	if { [ regexp {\/(.+)_.+_(.+)} $curr_cell_lib_name full1 name_orig name2_orig ] } {
        if { [get_attribute $curr_cell_lib threshold_voltage_group] != $type } {

          foreach_in_collection alternative [get_alternative_lib_cells [get_cell $cell]] {
            set possible_swap_name [get_attribute $alternative full_name]

            if { [ regexp {\/(.+)_.+_(.+)} $possible_swap_name full nm nm2 ] } {
              if { ($name_orig == $nm) && ($name2_orig == $nm2) && ([get_attribute $alternative threshold_voltage_group] == $type) } {
				
				# puts "set_cell_HVT: found $possible_swap_name from $curr_cell_lib_name"
				size_cell $cell $possible_swap_name
				# set curr_cell_lib [get_lib_cell -o $cell]
				# puts [get_attribute $curr_cell_lib threshold_voltage_group]
				# puts "Replaced $cell -> $curr_cell_lib_name with $possible_swap_name"
              }
            }
          }
        }
    }

	return $cell
}

proc get_cell_lower_size {cell} {
	set curr_cell_lib [get_lib_cell -o $cell]
	# list_attributes -application -class lib_cell
	set curr_cell_lib_name [get_attribute $curr_cell_lib full_name]

	set replacement_name $curr_cell_lib_name

	if { [ regexp {\/.*X([0-9]+)} $curr_cell_lib_name full1 old_load] } {

		set min_found -1
		foreach_in_collection alternative [get_alternative_lib_cells [get_cell $cell]] {
			set possible_swap_name [get_attribute $alternative full_name]

			if { [ regexp {\/.*X([0-9]+)} $possible_swap_name full new_possible_load] } {
				if { ([get_attribute $alternative threshold_voltage_group] == [get_attribute $curr_cell_lib threshold_voltage_group]) } {

					# puts "[get_attribute $alternative threshold_voltage_group] -- [get_attribute $curr_cell_lib threshold_voltage_group]"
					# puts "old load: $old_load. new possible load: $new_possible_load. min_found: $min_found"
					if { $old_load > $new_possible_load && $new_possible_load > $min_found } {
						set min_found $new_possible_load
						set replacement_name $possible_swap_name
					}

				}
			}
		}
	}

	return $replacement_name 
}


proc report_timing_enh {} {

    foreach_in_collection path [ get_timing_paths ] {
        
        set arrival 0
        foreach_in_collection tpoint [ get_attribute $path points ] {

            set pin [ get_attribute $tpoint object ]
            set cell [ get_cell -of_object $pin ]

            set full_name [ get_attribute $pin full_name ]
            set ref_name [ get_attribute $cell ref_name ]
            set delta [ expr [ get_attribute $tpoint arrival ] - $arrival ]
            set arrival [ get_attribute $tpoint arrival ]  

            # puts "$full_name\t\t\t\t$delta\t$arrival"    

            

        }
    }

}

proc is_ok_slack {allowed_slack} {
	if {[get_attribute [get_timing_paths] slack] < $allowed_slack} {
		return 0
	}

	return 1
}

proc compute_priority_leakage {cell} {
	set curr_cell_lib_name  [get_attribute [get_lib_cell -o $cell] full_name]

	if {[get_attribute [get_lib_cell -o $cell] threshold_voltage_group] == "LVT"} {
	
		############ ACTUAL CELL
		set cell_actual_leakage [get_attribute $cell leakage_power]
		# set cell_actual_delay [expr {$original_arrival - $previous_arrival}]
		set LVT_delay_max [get_attribute [get_timing_arcs -of_object $cell] delay_max]
		set lvt_path_delay {}

		############ NEW CELL
		set new_hvt_cell [set_cell_HVT $cell]
		
		set cell_new_leakage [get_attribute $new_hvt_cell leakage_power]
		set curr_cell_lib_name2 [get_attribute [get_lib_cell -o $new_hvt_cell] full_name]
		set HVT_delay_max [get_attribute [get_timing_arcs -of_object $new_hvt_cell] delay_max]

		set max_lvt_delay [max $LVT_delay_max]
		set max_hvt_delay [max $HVT_delay_max]

		size_cell $cell $curr_cell_lib_name 

		set denominator [expr {$max_hvt_delay - $max_lvt_delay}]
		if {$denominator == 0} {
			return [list 0 $curr_cell_lib_name2]
		} else {
			return [list [expr {($cell_actual_leakage - $cell_new_leakage) / $denominator}] $curr_cell_lib_name2]
		}
	} else {
		return [list 0 $curr_cell_lib_name]
	}
}

proc compute_priority_area_dyn {cell} {
	
	############ ACTUAL CELL
	set curr_cell_lib_name  [get_attribute [get_lib_cell -o $cell] full_name]
	set cell_actual_area [get_attribute $cell area]
	set cell_actual_dynpower [get_attribute $cell dynamic_power]
	set actual_delay_max [get_attribute [get_timing_arcs -of_object $cell] delay_max]


	############ NEW CELL
	set new_cell_name [get_cell_lower_size $cell]

	if {$new_cell_name == $curr_cell_lib_name} {
		return [list 0 $new_cell_name]
	}

	size_cell $cell $new_cell_name 
	
	set cell_new_area [get_attribute $cell area]
	set cell_new_dynpower [get_attribute $cell dynamic_power]
	set new_delay_max [get_attribute [get_timing_arcs -of_object $cell] delay_max]

	# puts "$cell_actual_area -> $cell_new_area"
	# puts "$cell_actual_dynpower -> $cell_new_dynpower"

	size_cell $cell $curr_cell_lib_name 

	set max_lvt_delay [max $actual_delay_max]
	set max_hvt_delay [max $new_delay_max]

	set denominator [expr {$max_hvt_delay - $max_lvt_delay}]

	if {$denominator == 0} {
		return [list 0 $new_cell_name]
	}

	return [list [expr {($cell_actual_area*$cell_actual_dynpower - $cell_new_area*$cell_new_dynpower) / $denominator}] $new_cell_name]
}

proc compute_priority_area_dummy {cell} {

	set curr_cell_lib_name  [get_attribute [get_lib_cell -o $cell] full_name]
	set cell_actual_area [get_attribute $cell area]
	set cell_actual_dynpower [get_attribute $cell dynamic_power]

	return [list [expr {($cell_actual_area*$cell_actual_dynpower)}] $curr_cell_lib_name]
}


proc compute_priority {cell} {

	set curr_cell_lib_name  [get_attribute [get_lib_cell -o $cell] full_name]

	############ ACTUAL CELL
	set cell_actual_leakage [get_attribute $cell leakage_power]
	set cell_actual_area [get_attribute $cell area]
	set cell_actual_dynpower [get_attribute $cell dynamic_power]
	# set cell_actual_delay [expr {$original_arrival - $previous_arrival}]
	set LVT_delay_max [get_attribute [get_timing_arcs -of_object $cell] delay_max]
	set lvt_path_delay {}

	############ NEW CELL
	set new_hvt_cell [set_cell_HVT $cell]
	
	set cell_new_leakage [get_attribute $new_hvt_cell leakage_power]
	set curr_cell_lib_name2 [get_attribute [get_lib_cell -o $new_hvt_cell] full_name]
	set HVT_delay_max [get_attribute [get_timing_arcs -of_object $new_hvt_cell] delay_max]

	set max_lvt_delay [max $LVT_delay_max]
	set max_hvt_delay [max $HVT_delay_max]

	# size_cell $cell $curr_cell_lib_name 

	set denominator [expr {$max_hvt_delay - $max_lvt_delay}]
	set hvt_priority {}
	if {$denominator == 0} {
		set hvt_priority [list 0 $curr_cell_lib_name2]
	} else {
		set hvt_priority [list [expr {($cell_actual_leakage - $cell_new_leakage) / $denominator}] $curr_cell_lib_name2]
	}

	set area_priority {}
	set lower_size_name [get_cell_lower_size $cell]

	if {$lower_size_name == $curr_cell_lib_name2} {
		set area_priority [list 0 $lower_size_name]
	} else {

		size_cell $cell $lower_size_name

		set cell_new_area [get_attribute $cell area]
		set cell_new_dynpower [get_attribute $cell dynamic_power]
		set new_delay_max [get_attribute [get_timing_arcs -of_object $cell] delay_max]
		
		set denominator [expr {$max_hvt_delay - $max_lvt_delay}]

		if {$denominator == 0} {
			set area_priority [list 0 $lower_size_name]
		}

		set area_priority [list [expr {($cell_actual_area*$cell_actual_dynpower - $cell_new_area*$cell_new_dynpower) / $denominator}] $lower_size_name]
	}

	size_cell $cell $curr_cell_lib_name
	return [list $hvt_priority $area_priority]
}

proc start {allowed_slack} {


	set dummy_priority {}
	set priority {}
	set priority_area {}
	set marked_cells {}

	foreach_in_collection cell [get_cell] {
		set dummy_priority [lappend dummy_prio [list $cell [get_attribute $cell leakage_power]]]
	}

	set finished 0
	set start_time [clock millisec]
	foreach dummy_prio [lsort -index 1 -decreasing -real $dummy_priority] {
		set cell [lindex $dummy_prio 0]
		# set priority_total [compute_priority $cell]
		# set priority [lappend priority [concat [list $cell] [lindex $priority_total 0]]]
		# if {[lindex $priority_total 1 0] > 0} {
		# 	set priority_area [lappend priority [concat [list $cell] [lindex $priority_total 1]]]
		# 	set marked_cells [lappend marked_cells [list $marked_cells 0]]
		# }
		# set priority [lappend priority [concat [list $cell [get_attribute [get_lib_cell -o $cell] full_name]] [compute_priority_leakage $cell]]]
		set priority [lappend priority [concat [list $cell [get_attribute [get_lib_cell -o $cell] full_name]] [lindex $dummy_prio 1]]]

		if {[expr {[clock millisec] - $start_time}] > 60000} {
			set finished 1
			break
		}
	}

	set priority [lsort -index 2 -decreasing -real $priority]
	puts $priority
	# gets stdin
	foreach prio $priority {

		set cell [lindex $prio 0]
		set curr_cell_lib_name  [get_attribute [get_lib_cell -o $cell] full_name]
		
		puts -nonewline "slack [get_attribute [get_timing_paths] slack] -> "
		set_cell_HVT $cell
		puts -nonewline "[get_attribute [get_timing_paths] slack] -> "

		if {[is_ok_slack $allowed_slack] == 0} {
			size_cell $cell $curr_cell_lib_name
			update_timing -full
			puts -nonewline "[get_attribute [get_timing_paths] slack]"
		}

		puts ""
		# if {[expr {[clock millisec] - $start_time}] > 75000} { 
		# 	break
		# }
	}

	if {$finished == 1} {
		foreach_in_collection cell [get_cell] {

			# if {[expr {[clock millisec] - $start_time}] > 90000} {
			# 	break
			# }

			set curr_cell_lib_name [get_attribute [get_lib_cell -o $cell] full_name]
			if {[lsearch -index 1 $priority $curr_cell_lib_name] == -1} {

				puts -nonewline "# slack [get_attribute [get_timing_paths] slack] -> "
				set_cell_HVT $cell
				puts -nonewline "[get_attribute [get_timing_paths] slack] -> "

				if {[is_ok_slack $allowed_slack] == 0} {
					size_cell $cell $curr_cell_lib_name
					update_timing -full
					puts -nonewline "[get_attribute [get_timing_paths] slack]"
				}

				puts ""
			}
		}
	}
	
	set curr_cell_lib_name  [get_attribute [get_lib_cell -o $cell] full_name]

	puts "slack [is_ok_slack $allowed_slack]"

	foreach_in_collection cell [get_cell] {
		set result [compute_priority_area_dummy $cell]
		if {[lindex $result 0] > 0} {
			set marked_cells [lappend marked_cells [list $marked_cells 0]]
			set priority_area [lappend priority_area [concat [list $cell] $result ]]
		}

		# if {[expr {[clock millisec] - $start_time}] > 100000} {
		# 	break
		# }
	}

	set priority_area [lsort -index 1 -decreasing -real $priority_area]
	puts $priority_area
	# gets stdin

	while {1} {

		set found 0
		for {set i 0} {$i < [llength $priority_area]} {incr i} {

			set prio [lindex $priority_area $i]
			set cell [lindex $prio 0]
			set curr_cell_lib_name  [get_attribute [get_lib_cell -o $cell] full_name]
			
			set new_cell_name [get_cell_lower_size $cell]

			puts "$new_cell_name -> $curr_cell_lib_name"
			if {$new_cell_name != $curr_cell_lib_name && [lindex $marked_cells $i 1] == 0} {
				set found 1
			
				puts -nonewline "slack [get_attribute [get_timing_paths] slack] -> "
				size_cell $cell $new_cell_name
				update_timing -full
				puts -nonewline "[get_attribute [get_timing_paths] slack] -> "

				if {[is_ok_slack $allowed_slack] == 0} {
					size_cell $cell $curr_cell_lib_name
					update_timing -full

					puts -nonewline "[get_attribute [get_timing_paths] slack]"
					set marked_cells [lreplace $marked_cells $i $i [list [lindex $marked_cells 0] 1]]
				}

				puts ""
				puts "Final cell -> [get_attribute [get_lib_cell -o $cell] full_name]"
			}
		}

		puts "LOOP $found: slack [is_ok_slack $allowed_slack]"
		#gets stdin

		if {$found == 0} {
			break
		}

		if {[expr {[clock millisec] - $start_time}] > 180000} {
			break
		}
	}


	while {[is_ok_slack $allowed_slack] == 0} {
		puts "RESTORING SLACK...."

		foreach_in_collection worst_path [get_timing_paths -max_paths 2000000] {

			foreach_in_collection timing_point [get_attribute $worst_path points]	{
				set obj_type [get_attribute [get_attribute $timing_point object] object_class]
							
				if {$obj_type == "pin"} {
					set cell [ get_cell -of_object [get_attribute $timing_point object] ]
					set_cell_LVT $cell	
					update_timing -full
				}

				if {[is_ok_slack $allowed_slack] == 1} {
					break
				}
			}

			if {[is_ok_slack $allowed_slack] == 1} {
				break
			}
		}

	}
}

proc dualVth {args} {
	parse_proc_arguments -args $args results
	set allowed_slack $results(-allowed_slack)

	#################################
	### INSERT YOUR COMMANDS HERE ###
	#################################
	print_slacks
	#gets stdin
	start $allowed_slack
	print_slacks
	
	#gets stdin

	return
}
define_proc_attributes dualVth \
-info "Post-Synthesis Dual-Vth Cell Assignment and Gate Re-Sizing" \
-define_args \
{
	{-allowed_slack "allowed slack after the optimization (valid range [-OO, 0])" value float required}
}
