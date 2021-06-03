source ./tcl_scripts/setenv.tcl
source ./tcl_scripts/braveOpt.tcl

set filename "fir"
# set filename "matmul_dfg__3"
# set filename "write_bmp_header_dfg__7"
# set filename "motion_vectors_dfg__7"
# set filename "jpeg_fdct_islow_dfg__6"
# set filename "smooth_color_z_triangle_dfg__31"
# set filename "idctcol_dfg__3"
# set filename "invert_matrix_general_dfg__3"

read_design ./data/DFGs/${filename}.dot
# read_library ./data/RTL_libraries/RTL_library_multi-resources.txt
read_library ./data/RTL_libraries/RTL_library_multi-resources-added.txt
set area_constraint 5000

proc validate_units_per_instant {result} {

	set index 1
	set last_start_time [lindex [lsort -index 1 -integer -decreasing [lindex $result 0] ] 0 1]
	set scheduled {}

	while {$index <= $last_start_time } {
		set tmp_fus [lindex $result 2]

		set started_nodes [lsearch -index 1 -all -inline [lindex $result 0] $index]

		set scheduled [concat $scheduled $started_nodes ]

		set tbc {}
		foreach node_scheduled_list $scheduled {
			set node_start_time [lindex $node_scheduled_list 1]
			set node [lindex $node_scheduled_list 0]
			set node_op_fu [lindex [lsearch -index 0 -inline [lindex $result 1] $node ] 1]
			set delay [get_attribute $node_op_fu delay]

			if {[expr {$node_start_time + $delay}] > $index} {
				set tbc [lappend tbc $node_scheduled_list]
			}
		}

		#foreach elem $tbc {
		#	puts -nonewline " \{$elem [get_attribute [lindex $elem 0] label] \}"
		#}

		#puts ""

		foreach node_list $tbc {
			
			set node_op [get_attribute [lindex $node_list 0] operation]
			set node_op_fu [lindex [lsearch -index 0 -inline [lindex $result 1] [lindex $node_list 0] ] 1]

			set index_tmp_fus [lsearch -index 0 $tmp_fus $node_op_fu]
			
			
			set new_number [expr { [lindex $tmp_fus $index_tmp_fus 1] - 1 }]
			if { $new_number < 0 } {
			puts "node_op_fu: [lindex $node_list 0] $node_op_fu $new_number [get_attribute [lindex $node_list 0] label]" 
			return 1
			}

			set tmp_fus [lreplace $tmp_fus $index_tmp_fus $index_tmp_fus [ list $node_op_fu $new_number ]]
		}
		incr index
	}

	return 0;
}


proc validate_area {result area_constraint} {
  set used_area 0
  foreach elem [lindex $result 2] {
    set used_area [ expr { $used_area + ([get_attribute [ lindex $elem 0 ] area ] * [ lindex $elem 1 ] ) } ]
  }
  if {$area_constraint >= $used_area} {
    return 0
  }
  return 1
}

proc validate_solution {result} {
    # save the scheduled nodes
    if { [ llength [lindex $result 0 ] ] == 0 } {
      return 1;
    }

    set node_list [lindex $result 0]
    foreach node_pair $node_list {
        set node [lindex $node_pair 0]
        set node_start_time [lindex $node_pair 1]
        set min_child_start_time -1
        foreach child [ get_attribute $node children ] {
            set child_start_time [ lindex [ lsearch -index 0 -inline $node_list $child ] 1]
            # get min starting time of child nodes
            if { ($min_child_start_time == -1) || ($child_start_time < $min_child_start_time) } {
                set min_child_start_time $child_start_time
            }
        }

        if {$min_child_start_time > 0} {
            set node_fu_unit [lindex [ lsearch -index 0 -inline [lindex $result 1] $node ] 1 ]
            set delay_node [get_attribute $node_fu_unit delay]
            # check that the output of the node is generated before the start of the
            # first child (first in time)
            if {$delay_node + $node_start_time > $min_child_start_time} {
                return 1
            }
        }
    }
    return 0
}
# puts -nonewline "File name for ./data/DFGs/*.dot: "
# flush stdout
# gets stdin filename

proc asap {} {
  set max_latency 0
  set node_start_time [list]

  foreach node [get_sorted_nodes] {
    set start_time 1
    foreach parent [get_attribute $node parents] {
      set parent_op [get_attribute $parent operation]
      set fu [get_lib_fu_from_op $parent_op]
      set parent_delay [get_attribute $fu delay]
      set idx_parent_start [lsearch -index 0 $node_start_time $parent]
      set parent_start_time [lindex [lindex $node_start_time $idx_parent_start] 1]
      set parent_end_time [expr $parent_start_time + $parent_delay]
      if { $parent_end_time > $start_time } {
        set start_time $parent_end_time
      }
    }
    lappend node_start_time "$node $start_time"

    set node_op [get_attribute $node operation]
    set fu [get_lib_fu_from_op $node_op]
    set node_delay [get_attribute $fu delay]
    set node_latency [ expr { $start_time + $node_delay } ]
    if {$max_latency < $node_latency } {
      set max_latency $node_latency
    }
  }

  return [list $node_start_time $max_latency]
}


proc compute_latency_min {result filename} {
    set node_start_time [asap]
    puts "\[evaluate] ASAP result: $node_start_time"
    print_scheduled_dfg [lindex $node_start_time 0] ./data/out/asap_contest_${filename}.dot

    return [lindex $node_start_time 1]
}

proc compute_latency {result} {

  	set latency 0

	set schedules [lindex $result 0]
    foreach schedule $schedules {
		set op_last_node [lindex [lsearch -index 0 -inline [lindex $result 1] [lindex $schedule 0]] 1]
		set delay_last_node [get_attribute $op_last_node delay]

		set computed_latency [ expr {[lindex $schedule 1] + $delay_last_node}]
		if {$computed_latency > $latency} {
			set latency $computed_latency
		}

    }

    return $latency

    # set last_node_starting_time [lindex [lindex $result 0 end] 1]
    # set last_node_name [lindex [lindex $result 0 end] 0]
    # set op_last_node [lindex [lsearch -index 0 -inline [lindex $result 1] $last_node_name] 1]
    # set delay_last_node [get_attribute $op_last_node delay]

    # set latency [expr {$last_node_starting_time + $delay_last_node}]

    # return $latency
}


set start [clock millisec]
set result [brave_opt -total_area $area_constraint]
set end [clock millisec]

set time [expr {$end - $start}]
set is_valid [validate_solution $result]
set is_valid2 [validate_area $result $area_constraint]
set is_valid3 [validate_units_per_instant $result]

if { $is_valid == 0 && $is_valid2 == 0 && $is_valid3 == 0 } {
    set latency_min [compute_latency_min $result $filename]
    set latency [compute_latency $result]

    puts "\[evaluate] result 0: [lindex $result 0]"
    puts "\[evaluate] result 2: [lindex $result 2]"
    puts "\[evaluate] time: $time ms"
    puts "\[evaluate] latency/latency_min: $latency/$latency_min"

    set score [expr {100 * (1-($time/double((900*1000)))) * $latency_min/double($latency)}]
    puts "\[evaluate] score $score"

    print_scheduled_dfg [lindex $result 0] ./data/out/contest_${filename}.dot

} else {
    puts "THE SCHEDULED DFG IS WRONG!"
}
