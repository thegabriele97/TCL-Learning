
set seasons { "winter" "spring" "summer" "autumn" }


set i 0
set j 0

foreach season $seasons {
    puts $season

    if { $season eq "spring" } {
        set j $i
    }

    incr i
}

puts "The position is $j"
