
set library_file "CORE65LPSVT_bc_1.30V_m40C.lib"

set cell_name "HS65_LS_NAND2X2"
set inputPin "A"
set loadCap "0.0014"
set inputTransTime "0.005"

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

set headers [ loadTableHeader $library_file $cell_name $inputPin ]
puts $headers

set values [ loadTableValues $library_file $cell_name $inputPin ]
puts $values