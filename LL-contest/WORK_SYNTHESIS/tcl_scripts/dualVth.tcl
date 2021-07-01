proc max args {
    set res -1
    foreach element [lindex $args 0] {
        if {$element > $res} {set res $element}
    }
    return $res
}

proc get_cell_HVT {cell} {
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
				
				# puts "get_cell_hvt: found $possible_swap_name from $curr_cell_lib_name"
				size_cell $cell $possible_swap_name
				# set curr_cell_lib [get_lib_cell -o $cell]
				# puts [get_attribute $curr_cell_lib threshold_voltage_group]
				# puts "Replaced $cell -> $curr_cell_lib_name with $possible_swap_name"
              }
            }
          }
        } else {
            # puts "Skipped $cell because already $type"
        }
    }

	return $cell
}


proc get_cell_lower_size {cell} {
	set curr_cell_lib [get_lib_cell -o $cell]
	# list_attributes -application -class lib_cell
	set curr_cell_lib_name [get_attribute $curr_cell_lib full_name]

	set replacement_name $curr_cell_lib_name
	puts "x"
	set replacement_dyn [get_attribute $cell leakage_power]
	puts "x"

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
						set replacement_dyn [get_attribute $alternative leakage_power]
					}

				}
			}
		}

		# if {$min_found != $old_load} {
		#	puts "Replaced $cell -> $curr_cell_lib_name with $replacement_name"
			# size_cell $cell $replacement_name
		#}
	}

	return list[ $replacement_name $replacement_dyn]
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

            puts "$full_name\t\t\t\t$delta\t$arrival"    

            

        }
    }

}

proc is_ok_slack {allowed_slack} {
    set path_list [get_timing_paths -slack_greater_than -100 -slack_lesser_than $allowed_slack]
    set empty 1
    foreach_in_collection elem $path_list {
        puts $elem
        set empty 0
		break
    }
    return $empty
}

proc compute_priority_leakage {cell} {
	
	############ ACTUAL CELL
	set cell_actual_leakage [get_attribute $cell leakage_power]
	# set cell_actual_delay [expr {$original_arrival - $previous_arrival}]
	set curr_cell_lib_name  [get_attribute [get_lib_cell -o $cell] full_name]
	set LVT_delay_max [get_attribute [get_timing_arcs -of_object $cell] delay_max]


	############ NEW CELL

	set new_hvt_cell [get_cell_HVT $cell]
	
	set cell_new_leakage [get_attribute $new_hvt_cell leakage_power]
	# set curr_cell_lib_name2 [get_attribute [get_lib_cell -o $new_hvt_cell] full_name]
	set HVT_delay_max [get_attribute [get_timing_arcs -of_object $new_hvt_cell] delay_max]

	set max_lvt_delay [max $LVT_delay_max]
	set max_hvt_delay [max $HVT_delay_max]


	# puts "[get_attribute $new_hvt_cell full_name] [get_attribute $cell full_name]"
	# puts "$curr_cell_lib_name $curr_cell_lib_name2"

	# puts "hvt_cell: $new_hvt_cell"
	# puts "actual: $cell_actual_delay - delay: $LVT_delay_max"
	# puts "new: $new_hvt_cell - delay: $HVT_delay_max - max: [max $HVT_delay_max]"
	# puts "new: $cell - delay: $LVT_delay_max - max: [max $LVT_delay_max]"

	size_cell $cell $curr_cell_lib_name 

	set denominator [expr {$max_hvt_delay - $max_lvt_delay}]
	return [expr {($cell_actual_leakage - $cell_new_leakage) / $denominator}]
}

proc compute_area {cell} {
	
	############ ACTUAL CELL
	set cell_actual_area [get_attribute $cell area]
	set cell_actual_dynpower [get_attribute $cell dynamic_power]
	

	############ NEW CELL
	set new_hvt_cell [get_cell_HVT $cell]
	
	set cell_new_area [get_attribute $new_hvt_cell area]
	set cell_new_dynpower [get_attribute $new_hvt_cell dynamic_power]
}


proc start {allowed_slack} {
	# set cell_list [get_cell]
	# foreach_in_collection cell $cell_list {
	# 	# test example
	# 	get_cell_lower_size [get_cell $cell]
	# 	break
	# }	

	set path_list [get_timing_paths -slack_greater_than -10 -max_paths 2000000]
	
	# foreach_in_collection path $path_list {
	# 	puts "[get_attribute $path slack]"
	# }

	# set current_path [get_attribute [index_collection $path_list end] slack]
	set current_path [index_collection $path_list end]

	set priority {}
	foreach_in_collection timing_point [get_attribute $current_path points] {

		set obj_type [get_attribute [get_attribute $timing_point object] object_class]
		
		if {$obj_type == "pin"} {
			set cell [ get_cell -of_object [get_attribute $timing_point object] ]

			# puts [get_attribute $cell ref_name]
			# puts [get_attribute $cell leakage_power]

			set priority_leakage 0
			if {[get_attribute [get_lib_cell -o $cell] threshold_voltage_group] == "LVT"} {
				set priority_leakage [compute_priority_leakage $cell]
			}

			set priority [lappend priority [list $timing_point $priority_leakage]]
		}
		
	}

	set priority [lsort -index 1 -decreasing -real $priority]
	puts $priority

	foreach pair $priority {

		set cell [ get_cell -of_object [get_attribute [lindex $pair 0] object] ]
		get_cell_HVT $cell

		puts [is_ok_slack $allowed_slack]

	}

}


proc dualVth {args} {
	parse_proc_arguments -args $args results
	set allowed_slack $results(-allowed_slack)

	#################################
	### INSERT YOUR COMMANDS HERE ###
	#################################
	report_timing_enh
	start $allowed_slack

	return
}

define_proc_attributes dualVth \
-info "Post-Synthesis Dual-Vth Cell Assignment and Gate Re-Sizing" \
-define_args \
{
	{-allowed_slack "allowed slack after the optimization (valid range [-OO, 0])" value float required}
}
