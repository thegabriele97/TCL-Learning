
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
    while { 1 } {
        incr nline
        set nchar [ gets $fd line ]
        if { $nchar < 0 } {
            break
        }

        switch $state {

            0 {
                if {[ regexp "$cell_name" $line -> ]} {
                    puts "Found cell name -> state 1"
                    set state 1
                }
            }

            1 {
                if {[ regexp {\scell\(} $line -> ]} {
                    puts "found the end: $nline) $line"
                    break
                }
                
                set state 1
            }

            default {}
        }
    }

    puts "\}"
}
        

