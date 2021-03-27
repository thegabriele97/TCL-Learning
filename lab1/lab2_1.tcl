
set library_file "CORE65LPSVT_bc_1.30V_m40C.lib"

set cell_ref_list { "HS65_LS_IVX2" "HS65_LS_NAND2X2" "HS65_LS_NOR3X2" }
set pin_cap_list {}

puts "Cell Reference List: $cell_ref_list"

foreach cell_name $cell_ref_list {
    set fd [ open "$library_file" {r} ]

    puts -nonewline "$cell_name: \{ "
    flush stdout

    set state 0
    set nline 0
    set foundCap 0
    set foundPinInput 0
    set cap 0
    set pin ""
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
                if {[ regexp {\spin\(([A-Z]*[A-Z0-9])\)} $line -> pin_name ]} {
                    set pin $pin_name
                    set state 2
                } elseif {[ regexp {\scell\(} $line -> ]} {
                    break
                }
            }

            2 {
                if {[ regexp {\scapacitance\s*:.*([0-9]+\.[0-9]+)} $line -> pin_capacitance ]} {
                    set foundCap 1
                    set cap $pin_capacitance
                } elseif {[ regexp {\sdirection\s*:\s*input} $line -> ]} {
                    set foundPinInput 1
                } elseif {[ regexp {\sdirection\s*:\s*output} $line -> ]} {
                    set state 1
                }

                if {$foundCap == 1 && $foundPinInput == 1} {
                    puts -nonewline "$pin -> $cap "
                    
                    set foundCap 0
                    set foundPinInput 0
                    set state 1
                }
            }

            default {}

        }
    }

    puts "\}"
}
        

