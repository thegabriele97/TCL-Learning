
set edge_len 32

proc printit { len } {
    
    set last_l 0

    for { set i 0} { $i < [expr {$len << 0}] } { incr i } {

        for { set j 0 } { $j < [expr {$len<<1}] } { incr j } {

            if { $j == [ expr { ($len >> 0) - $i } ] || $j == [ expr { $len + $i }] } {
                puts -nonewline "*"
            } elseif { $i == [expr {$len - 1}] && [expr { $j % 2 }] == 1 } {
                puts -nonewline "*"
            } elseif { $i != [expr {$len - 1}] && [expr {($i + 1) % 4}] == 0 } {
                puts -nonewline "*"
                set last_l $i
            } elseif { [expr {$i % 4}] == 0 } {
                set start 1
            } elseif { $start == 1 && $j == [expr {$len - $i + 1}] } {
                puts -nonewline "+"
            } else {
                puts -nonewline " "
            }

        }

        puts ""

    }
}

printit 32 

puts ""
