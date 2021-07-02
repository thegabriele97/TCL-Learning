set blockName "c1908"
set allowed_slack -3
source ./tcl_scripts/pt_analysis.tcl
source ./tcl_scripts/dualVth.tcl

proc check_slack {allowed_slack} {
    set path_list [get_timing_paths -slack_lesser_than $allowed_slack]
    set empty 1
    foreach_in_collection elem $path_list {
        puts $elem
        set empty 0
        break
    }
    return $empty
}

proc get_area {} {
    set sum 0
    foreach_in_collection cell [get_cells] {
        set cell_area [get_attribute $cell area]
        set sum [ expr { $cell_area + $sum } ]
    }
    return $sum
}

proc get_leakage {} {
    # Cell Leakage Power   = 4.150e-07   ( 0.09%)
    report_power > "power.rpt"
    set fp [open "power.rpt" r]
    set pwr_report [read $fp]
    close $fp
    if { [ regexp {Cell Leakage Power[ ]*=[ ]*([0-9\.\-e]+)} $pwr_report all_matches value ] } {
        return $value
    } else {
        puts "ERROR on Cell Internal Power"
        exit > "void"
    }
}

proc get_dynamic {} {
    #   Net Switching Power  = 3.195e-04   (66.70%)
    #   Cell Internal Power  = 1.591e-04   (33.21%
    report_power > "power.rpt"
    set fp [open "power.rpt" r]
    set pwr_report [read $fp]
    close $fp

    set sum 0

    if { [ regexp {Net Switching Power[ ]*=[ ]*([0-9\.\-e]+)} $pwr_report all_matches value ] } {
        set sum [ expr { $sum + $value } ]
    } else {
        puts "not found"
        puts "ERROR on Cell Internal Power"
        exit > "void"
    }

    if { [ regexp {Cell Internal Power[ ]*=[ ]*([0-9\.\-e]+)} $pwr_report all_matches value ] } {
        set sum [ expr { $sum + $value } ]
    } else {
        puts "ERROR on Cell Internal Power"
        exit > "void"
    }
    return $sum
}

# Start the pt_shell by loading the blockName circuit
pt_init $blockName

# Get starting point
set initial_leakage [get_leakage]
set initial_dynamic [get_dynamic]
set initial_area [get_area]

# Call dualVth function
set start [clock millisec]
dualVth -allowed_slack $allowed_slack
set end [clock millisec]

# Check that the slack is within the given constraint
set empty [check_slack $allowed_slack]
if { $empty == 1 } {
    set time [ expr { $end - $start } ]
    set final_leakage [get_leakage]
    set final_dynamic [get_dynamic]
    set final_area [get_area]
    set pleak_ratio [ expr { $initial_leakage / $final_leakage } ]
    set pdyn_ratio [ expr { $initial_dynamic / $final_dynamic } ]
    set area_ratio [ expr { $initial_area / $final_area } ]
    set points [ expr { ($area_ratio + $pleak_ratio + $pdyn_ratio) * ( 1 - ($time/(900 * 1000))) } ]

    # Summary
    puts ""
    puts ""
    puts "------------------------"
    puts "RESULTS"
    puts ""
    puts "TIME:   $time ms"
    puts "P LEAK: $initial_leakage\/$final_leakage \t-> $pleak_ratio"
    puts "P DYN:  $initial_dynamic\/$final_dynamic \t-> $pdyn_ratio"
    puts "AREA:   $initial_area\/$final_area \t\t-> $area_ratio"
    puts ""
    puts "POINTS:  $points"
    puts ""
    puts "------------------------"
} else {
    puts ""
    puts ""
    puts "------------------------"
    puts "ERROR: slack less than $allowed_slack"
    puts ""
    puts "------------------------"
}
