set blockName "c1908"
set allowed_slack 0.5

source ./tcl_scripts/pt_analysis.tcl
source ./tcl_scripts/dualVth.tcl

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
    report_power > "/tmp/power.rpt"
    set fp [open "/tmp/power.rpt" r]
    set pwr_report [read $fp]
    close $fp
    if { [ regexp {Cell Leakage Power[ ]*=[ ]*([0-9\.\-e]+)} $pwr_report all_matches value ] } {
        return $value
    } else {
        puts "ERROR on Cell Internal Power"
        exit > "/tmp/void"
    }
}

proc get_dynamic {} {
    #   Net Switching Power  = 3.195e-04   (66.70%)
    #   Cell Internal Power  = 1.591e-04   (33.21%
    report_power > "/tmp/power.rpt"
    set fp [open "/tmp/power.rpt" r]
    set pwr_report [read $fp]
    close $fp

    set sum 0

    if { [ regexp {Net Switching Power[ ]*=[ ]*([0-9\.\-e]+)} $pwr_report all_matches value ] } {
        set sum [ expr { $sum + $value } ]
    } else {
        puts "not found"
        puts "ERROR on Cell Internal Power"
        exit > "/tmp/void"
    }

    if { [ regexp {Cell Internal Power[ ]*=[ ]*([0-9\.\-e]+)} $pwr_report all_matches value ] } {
        set sum [ expr { $sum + $value } ]
    } else {
        puts "ERROR on Cell Internal Power"
        exit > "/tmp/void"
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
exit > "/tmp/void"