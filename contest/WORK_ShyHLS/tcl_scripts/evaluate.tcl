source ./tcl_scripts/setenv.tcl
source ./tcl_scripts/braveOpt.tcl


proc validate_solution {result} {
    # save the scheduled nodes
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

    set last_node_starting_time [lindex [lindex $result 0 end] 1]
    set last_node_name [lindex [lindex $result 0 end] 0]
    set op_last_node [lindex [lsearch -index 0 -inline [lindex $result 1] $last_node_name] 1]
    set delay_last_node [get_attribute $op_last_node delay]
    set latency [expr {$last_node_starting_time + $delay_last_node}]

    return $latency
}


#set filename "fir"
set filename "jpeg_fdct_islow_dfg__6"
# set filename "invert_matrix_general_dfg__3"
read_design ./data/DFGs/${filename}.dot
read_library ./data/RTL_libraries/RTL_library_multi-resources.txt

set start [clock millisec]
set result [brave_opt -total_area 2000]
set end [clock millisec]

set time [expr {$end - $start}]
set is_valid [validate_solution $result]

if { $is_valid == 0 } {
    set latency_min [compute_latency_min $result $filename]
    set latency [compute_latency $result]

    puts "\[evaluate] result: [lindex $result 0]"
    puts "\[evaluate] time: $time"
    puts "\[evaluate] latency/latency_min: $latency/$latency_min"

    set score [expr {100 * (1-($time/double((900*1000)))) * $latency_min/double($latency)}]
    puts "\[evaluate] score $score"

    print_scheduled_dfg [lindex $result 0] ./data/out/contest_${filename}.dot

} else {
    puts "THE SCHEDULED DFG IS WRONG!"
}
