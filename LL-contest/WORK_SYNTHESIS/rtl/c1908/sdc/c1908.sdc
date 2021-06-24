set sdc_version 1.3

set clockName "clk"
set clockPeriod "1.3"

create_clock -name clk -period $clockPeriod

;# Set-up Clock
set_clock_uncertainty [format %.4f [expr $clockPeriod*0.05]]  $clockName

;# fix hold constraints
set_min_delay 0.10 -from [all_inputs] -to [all_outputs]

;# Set-up IOs
set STM_minStrength_buf_LVT "HS65_LL_BFX7"
#set STM_minStrength_buf_SVT "HS65_LS_BFX7"
#set STM_minStrength_buf_HVT "HS65_LH_BFX7"

set_driving_cell -library "CORE65LPLVT_nom_1.20V_25C.db:CORE65LPLVT" -lib_cell $STM_minStrength_buf_LVT [all_inputs]
#set_driving_cell -library "CORE65LPSVT_nom_1.20V_25C.db:CORE65LPSVT" -lib_cell $STM_minStrength_buf_SVT [all_inputs]
#set_driving_cell -library "CORE65LPHVT_nom_1.20V_25C.db:CORE65LPHVT" -lib_cell $STM_minStrength_buf_HVT [all_inputs]

set_input_delay  [format %.4f [expr $clockPeriod*0.10]] -clock $clockName [all_inputs]
set_output_delay [format %.4f [expr $clockPeriod*0.10]] -clock $clockName [all_outputs]

set max_transition_time 0.1
set_max_transition $max_transition_time [all_outputs]

;# Set area constraint
set_max_area 0
