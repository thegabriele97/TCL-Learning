
set a 2
set b 18
set c 12

puts "a = $a\tb = $b\tc = $c"

set delta [ expr { ($b*$b) - ($a*$c << 2) } ]

if { $delta > 0 } {
    set sq [ expr { sqrt($delta) } ]
    
    set x1 [ expr { (-1*$b + $sq) / ($a << 1) } ]
    set x2 [ expr { (-1*$b - $sq) / ($a << 1) } ]

    puts "The solutions are $x1 and $x2 :)"

} else {
    puts "There are no real solutions :("
}

