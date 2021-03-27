
set var -20
set mylist {2 3}

linsert mylist end 4

while { $var <= 0 } {
	linsert $mylist $var
	incr var
}

if { $var > 0 } {
	puts "the variable $var is great then 0"
} else {
	puts "{the variable $var sucks}"
}

puts [list $mylist]

