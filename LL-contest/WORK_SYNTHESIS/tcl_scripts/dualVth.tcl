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
    set path_list [get_timing_paths -slack_lesser_than $allowed_slack]
    set empty 1
    foreach_in_collection elem $path_list {
        set empty 0
		break
    }
    return $empty
}

proc compute_priority_leakage {cell} {
	set curr_cell_lib_name  [get_attribute [get_lib_cell -o $cell] full_name]

	if {[get_attribute [get_lib_cell -o $cell] threshold_voltage_group] == "LVT"} {
	
		############ ACTUAL CELL
		set cell_actual_leakage [get_attribute $cell leakage_power]
		# set cell_actual_delay [expr {$original_arrival - $previous_arrival}]
		set LVT_delay_max [get_attribute [get_timing_arcs -of_object $cell] delay_max]


		############ NEW CELL
		set new_hvt_cell [set_cell_HVT $cell]
		
		set cell_new_leakage [get_attribute $new_hvt_cell leakage_power]
		set curr_cell_lib_name2 [get_attribute [get_lib_cell -o $new_hvt_cell] full_name]
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


proc start2 {allowed_slack} {
	
	# prendi path 
	while {1} {
		print_slacks
		set end 1
		set lut {}
		set priority {}
		set priority_areadyn {}
		set count 0

		set path_list [get_timing_paths -slack_greater_than $allowed_slack -max_paths 2000000]
		set current_path [index_collection $path_list end]

		set slacks {}
		foreach_in_collection path $path_list {
			set slack [lappend slacks [get_attribute $path slack]]
		}


		# slack scende
		
		foreach_in_collection timing_point [get_attribute $current_path points] {

			set obj_type [get_attribute [get_attribute $timing_point object] object_class]
			
			if {$obj_type == "pin"} {
				set cell [ get_cell -of_object [get_attribute $timing_point object] ]
				puts [get_attribute $cell full_name]

				# puts [get_attribute $cell ref_name]
				# puts [get_attribute $cell leakage_power]



					set search_lut [lsearch -index 0 -inline -all $lut [get_attribute [get_lib_cell -o $cell] full_name]]
					if {$search_lut < 0} {
						
						set priority_leakage_list [compute_priority_leakage $cell]
						
						set priority_area_list [compute_priority_area_dyn $cell]

						set priority_leakage [lindex $priority_leakage_list 0]
						set priority_area [lindex $priority_area_list 0]

						# {cell_lvt, cell_hvt, priotity_hvt}
						# {cell_lvt, cell_low_size, priorty_area}

						set x1 [list [get_attribute [get_lib_cell -o $cell] full_name] [lindex $priority_leakage_list 1]  [lindex $priority_leakage_list 0]]
						set x2 [list [get_attribute [get_lib_cell -o $cell] full_name] [lindex $priority_area_list 1] 0]

						set lut [lappend lut $x1]
						set lut [lappend lut $x2]

						set search_lut [list $x1 $x2]

						#puts "lut: $lut"
						# gets stdin
					}


					#puts "result search: $search_lut"
					# gets stdin
					set priority_leakage [lindex $search_lut 0 2]
					set priority_area [lindex $search_lut 1 2]


					if {$priority_leakage > 0} {
						set priority [lappend priority [list $timing_point $priority_leakage]]
					}

					if {$priority_area > 0} {
						set priority_areadyn [lappend priority_areadyn [list $timing_point $priority_area]]
					}
				


				# compute_priority_area_dyn $cell
			}
			
		}

		incr count

		if {$count >= 1} {
			
			#puts $priority
			# gets stdin

			set priority [lsort -index 1 -decreasing -real $priority]
			set priority_areadyn [lsort -index 1 -decreasing -real $priority_areadyn]
			#puts $priority
			
			set must_end 0

				puts "ALL PRIO FINISHED1 [llength $priority]"
				foreach prio $priority {
					puts [get_attribute [ get_cell -of_object [get_attribute [lindex $prio 0] object]] full_name]
				}
				puts "ALL PRIO FINISHED2 [llength $priority_areadyn]"
				#gets stdin
			while {1} {

				set first_prio_leak -1
				set first_prio_area -1

				if {[llength $priority] > 0} {
					set first_prio_leak [lindex $priority 0]
				}

				if {[llength $priority_areadyn] > 0} {
					set first_prio_area [lindex $priority_areadyn 0]
				}

				if {$first_prio_leak == -1 && $first_prio_area == -1 } {
					break
				}

				if {[lindex $first_prio_leak 1] >= [lindex $first_prio_area 1]} {
					set cell [ get_cell -of_object [get_attribute [lindex $first_prio_leak 0] object] ]
				} else {
					set cell [ get_cell -of_object [get_attribute [lindex $first_prio_area 0] object] ]
				}

				set curr_cell_lib_name  [get_attribute [get_lib_cell -o $cell] full_name]
				

				set curr_cell_lib [get_lib_cell -o $cell]
				if {[lindex $first_prio_leak 1] >= [lindex $first_prio_area 1]} {
					# substitution leak based
					# removed first element of priority
					# replace

					if {[get_attribute $curr_cell_lib threshold_voltage_group] != "HVT"} {
						set_cell_HVT $cell
					}
					set priority [ lrange $priority 1 end ]
					#puts "ALL PRIO FINISHED"
					#gets stdin
				} else {
					set rpc [get_cell_lower_size $cell]
					if {$rpc != [get_attribute $curr_cell_lib full_name]} {
						size_cell $cell $rpc 
					}
					set priority_areadyn [ lrange $priority_areadyn 1 end ]
					#puts "ALL PRIO FINISHED2 [llength $priority_areadyn]"
					#gets stdin
				}


				if {[is_ok_slack $allowed_slack] == 0} {
					#puts $lut
					#puts "STOPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPEEEEEERFECT"
					size_cell $cell $curr_cell_lib_name

				}


			} 

			# foreach pair $priority {

			# 	set cell [ get_cell -of_object [get_attribute [lindex $pair 0] object] ]
			# 	set curr_cell_lib_name  [get_attribute [get_lib_cell -o $cell] full_name]

			# 	set_cell_HVT $cell

			# 	if {[is_ok_slack $allowed_slack] == 0} {
			# 		puts "STOPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPEEEEEERFECT"

			# 		size_cell $cell $curr_cell_lib_name

			# 		set must_end 1
			# 		break
			# 	}

			# }
			
			set count 0
			# gets stdin
		}

		set i 0
		set end_slack_check 0


		puts "aaaaaaaaaaaaaaaaaa"
		print_slacks

		foreach_in_collection path [get_timing_paths -slack_greater_than $allowed_slack -max_paths 2000000] {
			puts "--> check [lindex $slacks $i] != [get_attribute $path slack]"
			if {[lindex $slacks $i] != [get_attribute $path slack]} {
				set end_slack_check 1
				break
			}

			incr i
		}

		if {$end_slack_check == 0} {
			break
		}

	}
}

proc start3 {allowed_slack} {


	set priority {}

	foreach_in_collection cell [get_cell] {
		set priority [lappend priority [concat [list $cell] [compute_priority_leakage $cell]]]
	}

	set priority [lsort -index 1 -decreasing -real $priority]
	puts $priority
	# gets stdin
	
	foreach prio $priority {

		set cell [lindex $prio 0]
		set curr_cell_lib_name  [get_attribute [get_lib_cell -o $cell] full_name]
		
		set_cell_HVT $cell

		if {[is_ok_slack $allowed_slack] == 0} {
			size_cell $cell $curr_cell_lib_name
		}

	}


	set priority_area {}
	set marked_cells {}
	foreach_in_collection cell [get_cell] {
		set result [compute_priority_area_dyn $cell]
		if {[lindex $result 0] > 0} {
			set marked_cells [lappend marked_cells [list $marked_cells 0]]
			set priority_area [lappend priority_area [concat [list $cell] $result ]]
		}
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
			
				size_cell $cell $new_cell_name

				if {[is_ok_slack $allowed_slack] == 0} {
					size_cell $cell $curr_cell_lib_name
					set marked_cells [lreplace $marked_cells $i $i [list [lindex $marked_cells 0] 1]]
				}
			}
		}

		puts "LOOP $found"
		#gets stdin

		if {$found == 0} {
			break
		}

	}

}

## Arrivo subito 

proc start {allowed_slack} {
	# set cell_list [get_cell]
	# foreach_in_collection cell $cell_list {
	# 	# test example
	# 	get_cell_lower_size [get_cell $cell]
	# 	break
	# }	

	
	
	# foreach_in_collection path $path_list {
	# 	puts "[get_attribute $path slack]"
	# }

	# set current_path [get_attribute [index_collection $path_list end] slack]
	
	

	set end 0
	set sl1 -1
	set sl2 0
	while {$end == 0} {
		print_slacks 
		set end 1
		set lut {}
		set priority {}
		set priority_areadyn {}
		set count 0
		# X8 X6 X2
		set path_list [get_timing_paths -slack_greater_than $allowed_slack -max_paths 2000000]
		foreach_in_collection current_path $path_list {
			foreach_in_collection timing_point [get_attribute $current_path points] {
				set cell [ get_cell -of_object [get_attribute $timing_point object] ]
				puts ">>>>>>  [get_attribute $cell full_name] <<<<<<"
			}
		}
		foreach_in_collection current_path $path_list {
			puts "SLACK [get_attribute $current_path slack]"
			#set current_path [index_collection $path_list end]

			foreach_in_collection timing_point [get_attribute $current_path points] {

				set obj_type [get_attribute [get_attribute $timing_point object] object_class]
				
				if {$obj_type == "pin"} {
					set cell [ get_cell -of_object [get_attribute $timing_point object] ]
					puts [get_attribute $cell full_name]

					# puts [get_attribute $cell ref_name]
					# puts [get_attribute $cell leakage_power]



						set search_lut [lsearch -index 0 -inline -all $lut [get_attribute [get_lib_cell -o $cell] full_name]]
						if {$search_lut < 0} {
							
							set priority_leakage_list [compute_priority_leakage $cell]

							set priority_area_list [compute_priority_area_dyn $cell]

							set priority_leakage [lindex $priority_leakage_list 0]
							set priority_area [lindex $priority_area_list 0]

							# {cell_lvt, cell_hvt, priotity_hvt}
							# {cell_lvt, cell_low_size, priorty_area}

							set x1 [list [get_attribute [get_lib_cell -o $cell] full_name] [lindex $priority_leakage_list 1]  [lindex $priority_leakage_list 0]]
							set x2 [list [get_attribute [get_lib_cell -o $cell] full_name] [lindex $priority_area_list 1]  0]

							set lut [lappend lut $x1]
							set lut [lappend lut $x2]

							set search_lut [list $x1 $x2]

							#puts "lut: $lut"
							# gets stdin
						}


						#puts "result search: $search_lut"
						# gets stdin
						set priority_leakage [lindex $search_lut 0 2]
						set priority_area [lindex $search_lut 1 2]


						if {$priority_leakage > 0} {
							set priority [lappend priority [list $timing_point $priority_leakage]]
						}

						if {$priority_area > 0} {
							set priority_areadyn [lappend priority_areadyn [list $timing_point $priority_area]]
						}
					


					# compute_priority_area_dyn $cell
				}
				
			}

			incr count

			if {$count >= 1} {
				
				#puts $priority
				# gets stdin

				set priority [lsort -index 1 -decreasing -real $priority]
				set priority_areadyn [lsort -index 1 -decreasing -real $priority_areadyn]
				#puts $priority
				
				set must_end 0

					puts "ALL PRIO FINISHED1 [llength $priority]"
					puts "ALL PRIO FINISHED2 [llength $priority_areadyn]"
					#gets stdin
				while {1} {

					set first_prio_leak -1
					set first_prio_area -1

					if {[llength $priority]} {
						set first_prio_leak [lindex $priority 0]
					}

					if {[llength $priority_areadyn]} {
						set first_prio_area [lindex $priority_areadyn 0]
					}

					if {$first_prio_leak == -1 && $first_prio_area == -1 } {
						break
					}

					if {[lindex $first_prio_leak 1] >= [lindex $first_prio_area 1]} {
						set cell [ get_cell -of_object [get_attribute [lindex $first_prio_leak 0] object] ]
					} else {
						set cell [ get_cell -of_object [get_attribute [lindex $first_prio_area 0] object] ]
					}

					set curr_cell_lib_name  [get_attribute [get_lib_cell -o $cell] full_name]
					

					set curr_cell_lib [get_lib_cell -o $cell]
					if {[lindex $first_prio_leak 1] >= [lindex $first_prio_area 1]} {
						# substitution leak based
						# removed first element of priority
						# replace

						if {[get_attribute $curr_cell_lib threshold_voltage_group] != "HVT"} {
							set_cell_HVT $cell
							set end 0
						}
							set priority [ lrange $priority 1 end ]
						#puts "ALL PRIO FINISHED"
						#gets stdin
					} else {
						set rpc [get_cell_lower_size $cell]
						if {$rpc != [get_attribute $curr_cell_lib full_name]} {
							size_cell $cell $rpc 
							set end 0
						}
							set priority_areadyn [ lrange $priority_areadyn 1 end ]
						#puts "ALL PRIO FINISHED2 [llength $priority_areadyn]"
						#gets stdin
					}


					if {[is_ok_slack $allowed_slack] == 0} {
						#puts $lut
						#puts "STOPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPEEEEEERFECT"
						set end 1
						size_cell $cell $curr_cell_lib_name

					}


				} 

				# foreach pair $priority {

				# 	set cell [ get_cell -of_object [get_attribute [lindex $pair 0] object] ]
				# 	set curr_cell_lib_name  [get_attribute [get_lib_cell -o $cell] full_name]

				# 	set_cell_HVT $cell

				# 	if {[is_ok_slack $allowed_slack] == 0} {
				# 		puts "STOPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPEEEEEERFECT"

				# 		size_cell $cell $curr_cell_lib_name

				# 		set must_end 1
				# 		break
				# 	}

				# }
				
				set count 0
				# gets stdin
			}

		}


		#puts "LOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOP"
		# gets stdin
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
	start3 $allowed_slack
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
