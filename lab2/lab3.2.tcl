source ./tcl_scripts/setenv.tcl

puts -nonewline "File name for ./data/DFGs/*.dot: "
flush stdout
gets stdin filename
#set filename "fir"

read_design ./data/DFGs/${filename}.dot
read_library ./data/RTL_libraries/RTL_lib_1.txt


proc busyop {op2look schedule} {

    set result {}

    set last_schedule [ lindex [lsort -increasing -integer -index 1 $schedule] end ]
    set last_schedule_time [lindex $last_schedule 1]
    set last_schedule_node [lindex $last_schedule 0]
    set last_schedule_node_delay [ get_attribute [ get_lib_fu_from_op [ get_attribute $last_schedule_node operation ] ] delay ]
    set latency [ expr $last_schedule_node_delay + $last_schedule_time ]

    for {set i 0} {$i < $latency} {incr i} {
        set result [ lappend result 0 ]
    }

    foreach pair $schedule {

        set start_time [ lindex $pair 1 ]
        set op [ get_attribute [lindex $pair 0] operation ]
        set op_delay [ get_attribute [ get_lib_fu_from_op $op ] delay ]

        if { $op ne $op2look} {
            continue
        }

        for {set i $start_time} {$i < [ expr $start_time + $op_delay ]} {incr i} {
            set result [ lreplace $result $i $i [ expr [ lindex $result $i ] + 1 ] ]
        }

    }

    return $result
} 


source ./alap.tcl
set schedule [alap 31]

gets stdin op2look
set result [busyop $op2look $schedule]

for {set i 0} {$i < [ llength $result ]} {incr i} {
    puts "@ $i:\t[lindex $result $i]"
}