
set library_file "CORE65LPSVT_bc_1.30V_m40C.lib"

set cell_name "HS65_LS_NAND2X2"
set inputPin "A"
set inputTransTime "0.041"
set loadCap "0.0088"

proc textlist2list {text} {
    set mylist {}

    foreach val [ split $text ", " ] {
        if { $val ne "" } {
            lappend mylist $val
        }
    }

    return $mylist
}

proc loadTableHeader {lib_file cell pin} {
    set fd [ open "$lib_file" {r} ]

    puts "# Looking for the right table header of $cell output pin Z related to input pin $pin .."
    
    set state 0
    set headerName ""
    while { 1 } {

        set nchar [ gets $fd line ]
        if { $nchar < 0 } {
            break
        }

        if { $state > 0 && [ regexp {\scell\(} $line -> ]} {
            break
        }

        switch $state {
            0 {
                if {[ regexp "$cell" $line -> ]} {
                    set state 1
                }
            }

            1 {
                if {[ regexp {\s*pin\(Z\)} $line -> ]} {
                    set state 2
                }
            }

            2 {
                if {[ regexp {\s*timing\(\)\s*} $line -> ]} {
                    set state 3
                }
            }

            3 {
                if {[ regexp {\s*related_pin\s*\:\s*\"(.*)\"} $line -> relatedPin ]} {
                    set state 2;

                    if {[ string equal -nocase $pin $relatedPin ]} {
                        set state 4
                    }
                }
            }

            4 {
                if {[ regexp {\s*cell_fall\((.*)\)} $line -> tableHeader ]} {
                    set headerName $tableHeader
                    break
                }
            }
        }

    }

    set indexes {{} {}}
    if { $headerName ne "" } {
        puts "# The correct header seems to be $headerName"
        puts "# Looking for $headerName .."
        set fd [ open "$lib_file" {r} ]

        set state 0
        while { 1 } {
            set nchar [ gets $fd line ]
            if { $nchar < 0 } {
                break
            }

            switch $state {
                0 {
                    if {[ regexp "\\s*lu_table_template\\(${headerName}\\)" $line -> ]} {
                        set state 1
                    }
                }

                1 {
                    if {[ regexp "\\s*index_1\\(\"\\s*(.*)\\s\"\\);" $line -> vals]} {
                        set indexes [ lreplace $indexes 0 0 [ textlist2list $vals ] ]
                    } elseif {[ regexp "\\s*index_2\\(\"\\s*(.*)\\s\"\\);" $line -> vals]} {
                        set indexes [ lreplace $indexes 1 1 [ textlist2list $vals ] ]
                    }

                    if {[ llength [ lindex $indexes 0 ] ] > 0 && [ llength [ lindex $indexes 1 ] ] > 0} {
                        puts "# Done!"
                        break
                    }
                }
            }
        }
    }

    return $indexes
}

proc loadTableValues {lib_file cell pin} {
    set fd [ open "$lib_file" {r} ]

    puts "# Looking for the right table values of $cell output pin Z related to input pin $pin .."
    
    set state 0
    set isInTable 0
    set table {}
    while { 1 } {

        set nchar [ gets $fd line ]
        if { $nchar < 0 } {
            break
        }

        if { $state > 0 && [ regexp {\scell\(} $line -> ]} {
            break
        }

        switch $state {
            0 {
                if {[ regexp "$cell" $line -> ]} {
                    set state 1
                }
            }

            1 {
                if {[ regexp {\s*pin\(Z\)} $line -> ]} {
                    set state 2
                }
            }

            2 {
                if {[ regexp {\s*timing\(\)\s*} $line -> ]} {
                    set state 3
                }
            }

            3 {
                if {[ regexp {\s*related_pin\s*\:\s*\"(.*)\"} $line -> relatedPin ]} {
                    set state 2;

                    if {[ string equal -nocase $pin $relatedPin ]} {
                        set state 4
                    }
                }
            }

            4 {
                if {[ regexp {\s*cell_fall\(.*\)} $line -> ]} {
                    set state 5
                }
            }

            5 {
                if {[ regexp {values\(\".*\"} $line -> ] || $isInTable == 1} {
                    set isInTable 1

                    regexp {\"(.*)\"} $line -> row
                    set table [ lappend table [ textlist2list $row ] ] 

                    if {[ regexp {\"\);} $line -> ]} {
                        set isInTable 0
                        puts "# Done!"

                        break
                    }
                }
            }
        }

    }

    return $table
}

# returns {{i, bool } {j, bool}} both if exists the exact (bool = 1)
# pair passed as argument or the best result otherwise (bool = 0)
proc searchFor {header vals} {

    set mylist {{} {}}

    for {set j 0} {$j < [ llength $vals ]} {incr j} {
        set header0 [ lindex $header $j ]
        set val [ lindex $vals $j ]

        puts "# Now looking for $val in $header0 .."
    
        for {set i 0} {$i < [ llength $header0 ]} {incr i} {
            if { $val >= [ lindex $header0 $i ] } {
                set ilist {}
                set ilist [ lappend ilist $i ]
                
                if { [ lindex $header0 $i ] == $val } {
                    set ilist [ lappend ilist 1 ]
                } else {
                    set ilist [ lappend ilist 0 ]
                }

                set mylist [ lreplace $mylist $j $j $ilist ]
            }
        }
    }

    return $mylist
}

proc elementAt {matrix i j} {
    set r [ lindex $matrix $i ]
    return [ lindex $r $j ]
}

# x = { x0 x1 x2 } 
# y = { y0 y1 y2 }
# where x0 and y0 are the value of x 
# and y we want to interpolate to found f(x, y)
proc bilinearInterp { x y q11 q12 q21 q22 } {

    set x0 [ lindex $x 0 ]
    set x1 [ lindex $x 1 ]
    set x2 [ lindex $x 2 ]

    set y0 [ lindex $y 0 ]
    set y1 [ lindex $y 1 ]
    set y2 [ lindex $y 2 ]

    set f_x_y1 [ expr (($x2-$x0) * $q11 + ($x0-$x1) * $q21) / ($x2-$x1) ]
    set f_x_y2 [ expr (($x2-$x0) * $q12 + ($x0-$x1) * $q22) / ($x2-$x1) ]

    return [ expr (($y2-$y0) * $f_x_y1 + ($y0-$y1) * $f_x_y2) / ($y2-$y1) ]
}

set headers [ loadTableHeader $library_file $cell_name $inputPin ]
puts $headers

set values [ loadTableValues $library_file $cell_name $inputPin ]
puts $values

set result [ searchFor $headers [ lappend {} $inputTransTime $loadCap ] ]
puts $result

if { [ elementAt $result 0 1 ] == 1 && [ elementAt $result 1 1 ] == 1 } {
    set res [ elementAt $values [ elementAt $result 0 0 ] [ elementAt $result 1 0 ] ]
} else {

    set i [ elementAt $result 0 0 ]
    set j [ elementAt $result 1 0 ]

    set x0 $inputTransTime
    set x1 [ lindex $headers 0 [ expr {$i + 0} ] ]
    set x2 [ lindex $headers 0 [ expr {$i + 1} ] ]

    set y0 $loadCap
    set y1 [ lindex $headers 1 [ expr {$j + 0} ] ]
    set y2 [ lindex $headers 1 [ expr {$j + 1} ] ]

    set q11 [ elementAt $values $i $j ]
    set q12 [ elementAt $values $i [ expr {$j + 1} ] ]
    set q21 [ elementAt $values [ expr {$i + 1} ] $j ]
    set q22 [ elementAt $values [ expr {$i + 1} ] [ expr {$j + 1} ] ]

    set res [ bilinearInterp [ lappend lx $x0 $x1 $x2 ] [ lappend ly $y0 $y1 $y2 ] $q11 $q12 $q21 $q22 ]
}

puts "The final result is: $res"