source ./tcl_scripts/setenv.tcl
source ./tcl_scripts/braveOpt.tcl

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


proc compute_latency_min {} {
    set node_start_time [asap]
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

# set filename "fir"
# set filename "matmul_dfg__3"
# set filename "motion_vectors_dfg__7"
# set filename "jpeg_fdct_islow_dfg__6"
# set filename "idctcol_dfg__3"
# set filename "invert_matrix_general_dfg__3"

# read_design ./data/DFGs/${filename}.dot
read_design [lindex $::argv 0]
read_library ./data/RTL_libraries/RTL_library_multi-resources.txt
# read_library ./data/RTL_libraries/RTL_library_multi-resources-added.txt

set start [clock millisec]
set result [brave_opt -total_area [lindex $::argv 1]]
set end [clock millisec]

set time [expr {$end - $start}]
set latency [compute_latency $result]
set latency_min [compute_latency_min]

set score [expr {100 * (1-($time/double((900*1000)))) * $latency_min/double($latency)}]
if {$latency == 0} {
    set score 0
}


puts "## EVAL PLOT HELPER ##"
puts $time
puts $latency
puts $latency_min
puts $score
