proc replace_with_HVT {cell} {
	set type HVT
	set curr_cell_lib [get_lib_cell -o $cell]
	set curr_cell_lib_name [get_attribute $curr_cell_lib full_name]
	puts $curr_cell_lib_name
	if { [ regexp {\/(.+)_.+_(.+)} $curr_cell_lib_name full1 name_orig name2_orig ] } {
        if { [get_attribute $curr_cell_lib threshold_voltage_group] != $type } {

          foreach_in_collection alternative [get_alternative_lib_cells [get_cell $cell]] {
            set possible_swap_name [get_attribute $alternative full_name]

            if { [ regexp {\/(.+)_.+_(.+)} $possible_swap_name full nm nm2 ] } {
              if { ($name_orig == $nm) && ($name2_orig == $nm2) && ([get_attribute $alternative threshold_voltage_group] == $type) } {

                puts "Replaced $cell -> $curr_cell_lib_name with $possible_swap_name"
                size_cell $cell $possible_swap_name
              }
            }
          }
        } else {
            puts "Skipped $cell because already $type"
        }
    }
}

proc replace_with_lower_size {cell} {
	set curr_cell_lib [get_lib_cell -o $cell]
	# list_attributes -application -class lib_cell
	set curr_cell_lib_name [get_attribute $curr_cell_lib full_name]
	if { [ regexp {\/(.+)_(.+_.+[0-9]*X)([0-9]+)} $curr_cell_lib_name full1 name_orig name2_orig old_load] } {
		  foreach_in_collection alternative [get_alternative_lib_cells [get_cell $cell]] {
            set possible_swap_name [get_attribute $alternative full_name]

            if { [ regexp {\/(.+)_(.+_.+[0-9]*X)([0-9]+)} $possible_swap_name full nm nm2 new_possible_load] } {
				if { ($name_orig == $nm) && ($name2_orig == $nm2) && ([get_attribute $alternative threshold_voltage_group] == [get_attribute $curr_cell_lib threshold_voltage_group]) } {

					if { $old_load > $new_possible_load } {
             			puts "Replaced $cell -> $curr_cell_lib_name with $possible_swap_name"
                		size_cell $cell $possible_swap_name
					}
             }
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
	set cell_list [get_cell]
	foreach_in_collection cell $cell_list {
		# test example
		replace_with_lower_size [get_cell $cell]
	}

	return
}

define_proc_attributes dualVth \
-info "Post-Synthesis Dual-Vth Cell Assignment and Gate Re-Sizing" \
-define_args \
{
	{-allowed_slack "allowed slack after the optimization (valid range [-OO, 0])" value float required}
}
