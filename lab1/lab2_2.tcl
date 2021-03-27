
set library_file "CORE65LPSVT_bc_1.30V_m40C.lib"

set cell_ref_list { "HS65_LS_IVX2" "HS65_LS_IVX2" "HS65_LS_NAND2X2" "HS65_LS_NOR3X2" }
set tech_par { "area" "leakage" "rise" "fall" }

puts "Cell List: $cell_ref_list"

for {set i 0} {$i < [llength $cell_ref_list] } {incr i} {

    set fd [ open "$library_file" {r} ]
    set cell_name [lindex $cell_ref_list $i]
    set cell_param [lindex $tech_par $i] 
    
    puts -nonewline "$cell_name\[$cell_param\]: "
    flush stdout

    set state 0
    set nline 0
    set isInTable 0
    set maxVal 0
    while { 1 } {

        incr nline
        set nchar [ gets $fd line ]
        if { $nchar < 0 } {
            break
        }

        switch $state {
            0 {
                if {[ regexp "$cell_name" $line -> ]} {
                    set state 1
                }
            }

            1 { 

                if {[ regexp {\scell\(} $line -> ]} {
                    break
                }

                switch $cell_param {
                    "leakage" {
                        set cell_param "cell_leakage_power"
                    }

                    "rise" {
                        if {[ regexp {\s*pin\(Z\)} $line -> ]} {
                            set state 2
                        }
                    }

                    "fall" {
                        if {[ regexp {\s*pin\(Z\)} $line -> ]} {
                            set state 2
                        }
                    }

                    default {}
                }

                if {[ regexp "\s*(.+)\s*\:\s*(.+);" $line -> param value ]} {                          
                    if {[string equal [string trim $param] $cell_param]} {
                        puts "[string trim $value]"
                        break
                    }
                }

            }

            2 {
                if {[ regexp {\s*timing\(\)\s*} $line -> ]} {
                    set state 3
                } 
            }

            3 {
                if {[ regexp "\s*${cell_param}_transition.*" $line -> ]} {
                    set state 4
                }
            }

            4 {
                
                if {[ regexp {values\(\".*\"} $line -> ] || $isInTable == 1} {
                    set isInTable 1

                    regexp {\"(.*)\"} $line -> row
                    foreach val [ split $row ", " ] {
                        if {[ string is double -strict $val ]} {
                            if { $val > $maxVal } {
                                set maxVal $val
                            }
                        }
                    }

                    if {[ regexp {\"\);} $line -> ]} {
                        puts "$maxVal"

                        set isInTable 0
                        break
                    }
                }
            }

            default {}

        }
    }
}
        

