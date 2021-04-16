# foreach_in_collection point_cell [get_cells] {
 
#    set cell_name [get_attribute $point_cell full_name]
#    set cell_type [get_attribute $point_cell is_combinational]
 
#    if { $cell_type == true } {
#        puts "$cell_name is combinational"
#    } else {
#        puts "$cell_name is not combinational"
#    }

#}

proc sort_list_according_to { the_list ref } {

    set tmplist {}
    for {set i 0} { $i < [ llength $ref ] } {incr i} {
        set tmplist [lappend tmplist [ list [lindex $the_list $i] [lindex $ref $i] ] ]
    }

    
    set tmplist [ lsort -index 1 -increasing -real $tmplist ]
    
    set toret {}
    foreach v $tmplist {
        set toret [ lappend toret [lindex $v 0 ] ]
    }

    return $toret
}


set cell_list_name {}
set cell_list_ref {}
set cell_list_area {}
set cell_list_leakage {}
set cell_list_dynamic {}

foreach_in_collection pcell [ get_cells ] {

    if { [get_attribute $pcell is_combinational] } {
        lappend cell_list_name [ get_attribute $pcell full_name ]
        lappend cell_list_ref [ get_attribute $pcell ref_name ]
        lappend cell_list_area [ get_attribute $pcell area ]
        lappend cell_list_leakage [ get_attribute $pcell leakage_power ]
        lappend cell_list_dynamic [ get_attribute $pcell dynamic_power ]
    }

}


set cell_list_name [ sort_list_according_to $cell_list_name $cell_list_leakage ]
set cell_list_ref [ sort_list_according_to $cell_list_ref $cell_list_leakage ]
set cell_list_area [ sort_list_according_to $cell_list_area $cell_list_leakage ] 
set cell_list_leakage [ sort_list_according_to $cell_list_leakage $cell_list_leakage ]
set cell_list_dynamic [ sort_list_according_to $cell_list_dynamic $cell_list_leakage ]


for {set i 0} {$i < [llength $cell_list_name]} {incr i} {
    puts "[lindex $cell_list_name $i] [lindex $cell_list_leakage $i]"
}

set totarea 0
set totleakpower 0
set totdynpower 0

for {set i 0} {$i < [llength $cell_list_area]} {incr i} {
    set totarea [ expr $totarea + [lindex $cell_list_area $i] ]
    set totleakpower [ expr $totleakpower + [lindex $cell_list_leakage $i] ]
    set totdynpower [ expr $totdynpower + [lindex $cell_list_dynamic $i] ]
}

puts "The total combinational area is $totarea"
puts "The total leakage power is $totleakpower"
puts "The total dynamic power is $totdynpower"

