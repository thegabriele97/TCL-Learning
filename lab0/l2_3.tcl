
set vals {}

for { set i 0 } { $i < 10 } { incr i } {
    lappend vals $i
}

set i 0
foreach val $vals {
    puts "${i})\t$val"
    incr i 
}

puts "The value is [ lindex $vals 4 ]"

lappend vals [ expr { [lindex $vals 4] + [lindex $vals 9] } ]

puts "The last element of the list is [ lindex $vals 10 ]"

