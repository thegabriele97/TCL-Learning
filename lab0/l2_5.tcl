
set paragraph "Write a Tcl script that declares a variable called paragraph which contains the assignment of this exercise (or any other arbitrary text). The script should be able to: 1. Report the word count of the text contained in paragraph (consider the split function); 2. Create a new variable where the original text is modified as to include the word program instead of the word script; then print the obtained result to the terminal (refer to function replace or lreplace)."

puts "$paragraph \n"

set words [ split $paragraph " ;" ]
puts "There are [ llength $words ] words!"

for { set i 0} { $i < [ llength $words ] } { incr i } {
    if { [ lindex $words $i ] eq "script" } {
        set words [lreplace $words $i $i "program" ]
    }
}

puts $words

