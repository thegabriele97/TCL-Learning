

proc get_cell_attributes {cellName} {

    set cell [ get_cell $cellName ]
    set full_name [ get_attribute $cell full_name ]
    set ref_name [ get_attribute $cell ref_name ]
    set area [ get_attribute $cell area ]
    
    regexp {X([0-9]+$)} $ref_name -> size
    set leak_power [ get_attribute $cell leakage_power ] 
    set dyn_power [ get_attribute $cell dynamic_power ]
    set tot_power [ get_attribute $cell total_power ]

    
    set outpin_arrivaltime 0
    set max_slack 0
    foreach_in_collection pin [ get_pin "$cellName/*" ] {
        if { [ get_attribute $pin direction ] == "out" } {

            set outpin_arrivaltime [ get_attribute $pin max_rise_arrival ]
            if { [ get_attribute $pin max_fall_arrival ] > $outpin_arrivaltime } {
                set outpin_arrivaltime [ get_attribute $pin max_fall_arrival ]
            }

            set max_slack [ get_attribute $pin max_slack ] 
            
            break
        }
    }

    
    puts "$full_name $ref_name $area $size $leak_power $dyn_power $tot_power $outpin_arrivaltime $max_slack"

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


proc slack_histogram {left right} {
    
    set result {}
    set sw [expr $right - $left]
    puts "Slack Window is $sw"

    for {set i 0} {$i < 10} {incr i} {
        set result [ lappend result 0 ]
    }

    foreach_in_collection pin [ get_pins ] {
                
        set slack [ get_attribute $pin max_slack ] 
        #puts "slack is $slack"

        set rel_slack [ expr $slack - $left ]
        for {set i 0} {$i < 10} {incr i} {
   
            if { [expr $i*$sw/double(10)] <= $rel_slack && $rel_slack < [expr ($i+1)*$sw/double(10)] } {
    
                #puts "identified i=$i"
                set result [ lreplace $result $i $i [ expr [lindex $result $i] + 1 ] ]

                break
            }
        }
        
    } 

    puts $result    
    
}





