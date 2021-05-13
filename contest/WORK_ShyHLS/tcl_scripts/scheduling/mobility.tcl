proc mobility {asap_schedule alap_schedule} {

    set node_mobility [list]
    foreach node [get_nodes] {
        set index_asap [lsearch -index 0 $asap_schedule $node]
        set index_alap [lsearch -index 0 $alap_schedule $node]
        set start_asap [lindex $asap_schedule $index_asap 1]
        set start_alap [lindex $alap_schedule $index_alap 1]
        set mobility_value [expr {$start_alap - $start_asap}]
        lappend node_mobility "$node $mobility_value"
    }
    return $node_mobility
}