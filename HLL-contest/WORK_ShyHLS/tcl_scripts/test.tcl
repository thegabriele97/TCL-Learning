set time 11958
set latency 9
set latency_min 8

puts [expr {100 * (1-($time/double((900*1000*1000)))) * $latency_min/double($latency)}]

set time 81385
set latency 10
set latency_min 8

puts [expr {100 * (1-($time/double((900*1000*1000)))) * $latency_min/double($latency)}]