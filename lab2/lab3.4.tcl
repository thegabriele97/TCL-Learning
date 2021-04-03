source ./tcl_scripts/setenv.tcl

puts -nonewline "File name for ./data/DFGs/*.dot: "
flush stdout
gets stdin filename
#set filename "fir"

read_design ./data/DFGs/${filename}.dot
read_library ./data/RTL_libraries/RTL_lib_1.txt

proc calc_endtime {pair} {
    set op [ get_attribute [lindex $pair 0] operation ]
    set op_delay [get_attribute [ get_lib_fu_from_op $op ] delay ]
    set node_endtime [ expr [lindex $pair 1] + $op_delay - 1 ]
}

proc life_time {schedule} {

    set result {}

    foreach pair $schedule {

        set node_endtime [calc_endtime $pair]

        set max_endtime $node_endtime
        foreach child [ get_attribute [lindex $pair 0] children ] {

            set child_entime [ calc_endtime [ lindex [ lsearch -index 0 -all -inline $schedule $child ] 0 ] ]
            if {$child_entime > $max_endtime} {
                set max_endtime $child_entime
            }

        }

        set dummyl1 {}
        set dummyl2 {}
        set result [lappend result [lappend dummyl1 [lindex $pair 0] [lappend dummyl2 $node_endtime $child_entime]]]
    }

    return $result
}

source ./asap.tcl
source ./alap.tcl

set schedule [asap] 
set result [ life_time $schedule ]

foreach lt $result {
    puts "For [lindex $lt 0]\t([get_attribute [lindex $lt 0] label]):\t\t[lindex $lt 1]"
}